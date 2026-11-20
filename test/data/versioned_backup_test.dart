import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readsanctuary/core/errors/failures.dart';
import 'package:readsanctuary/data/backup/backup_deserializer.dart';
import 'package:readsanctuary/data/backup/backup_serializer.dart';
import 'package:readsanctuary/data/backup/restore_backup_service.dart';
import 'package:readsanctuary/data/local/database.dart';

void main() {
  late AppDatabase db;
  late BackupSerializer serializer;
  late BackupDeserializer deserializer;
  late RestoreBackupService restoreService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    serializer = BackupSerializer();
    deserializer = BackupDeserializer();
    restoreService = RestoreBackupService();
    // Initialize DB tables
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3: Versioned .rsbk Backup & Idempotent Sync Tests', () {
    test(
        'Exporting and re-importing the same .rsbk file twice results in zero duplicate books, shelves, or sessions',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Seed initial data
      await db.shelfDao.insertShelf(
        ShelvesCompanion.insert(
          id: 'test-shelf-1',
          name: 'Sci-Fi Classics',
          sortOrder: 0,
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: 'book-foundation',
          title: 'Foundation',
          authors: jsonEncode(['Isaac Asimov']),
          status: 'reading',
          spineColorHex: 0xFF123456,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
          isbn13: const Value('9780553293357'),
        ),
      );

      await db.sessionDao.insertSession(
        ReadingSessionsCompanion.insert(
          id: 'session-1',
          bookId: 'book-foundation',
          startTime: now,
          durationSeconds: 1800,
          startPage: 1,
          endPage: 45,
        ),
      );

      // 2. Export to .rsbk compressed bytes
      final rsbkBytes = await serializer.serializeDatabase(db);
      expect(rsbkBytes.isNotEmpty, isTrue);

      // 3. Deserialize snapshot
      final snapshot = await deserializer.deserializeBytes(rsbkBytes);
      expect(snapshot.books.length, 1);
      expect(snapshot.shelves.length, 3); // 2 default + 1 custom
      expect(snapshot.readingSessions.length, 1);

      // 4. Re-import snapshot into the same DB (First import)
      final result1 = await restoreService.restoreSnapshot(db, snapshot);
      expect(result1.success, isTrue);

      // 5. Re-import snapshot again (Second import - testing idempotency)
      final result2 = await restoreService.restoreSnapshot(db, snapshot);
      expect(result2.success, isTrue);

      // Verify ZERO duplicate books, shelves, or sessions
      final books = await db.bookDao.getAllBooks();
      expect(books.length, 1, reason: 'Must not duplicate books on repeated restore');

      final shelves = await db.shelfDao.getAllShelves();
      expect(shelves.length, 3, reason: 'Must not duplicate shelves');

      final sessions = await db.sessionDao.getAllSessions();
      expect(sessions.length, 1, reason: 'Must not duplicate reading sessions');
    });

    test(
        'Smart Merge applies Last-Write-Wins (LWW): newer timestamps overwrite, older timestamps are ignored',
        () async {
      const bookId = 'book-dune';

      // Local book: updatedAt = 1000, status = 'reading'
      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: bookId,
          title: 'Dune',
          authors: jsonEncode(['Frank Herbert']),
          status: 'reading',
          spineColorHex: 0xFFE0A96D,
          spineTextHex: 0xFF000000,
          createdAt: 1000,
          updatedAt: 1000,
          lastReadPage: const Value(50),
        ),
      );

      // Backup with newer updatedAt = 2000, status = 'finished'
      final newerSnapshotJson = {
        'schema_version': 1,
        'app_version': '1.1.0',
        'exported_at': 2000,
        'device_id': 'cloud-device',
        'data': {
          'books': [
            {
              'id': bookId,
              'title': 'Dune',
              'authors': jsonEncode(['Frank Herbert']),
              'status': 'finished',
              'spine_color_hex': 0xFFE0A96D,
              'spine_text_hex': 0xFF000000,
              'last_read_page': 658,
              'created_at': 1000,
              'updated_at': 2000,
            }
          ],
          'shelves': [],
          'shelf_items': [],
          'book_shelves': [],
          'reading_sessions': [],
          'book_notes': [],
        }
      };

      final gzippedNewer = gzip.encode(utf8.encode(jsonEncode(newerSnapshotJson)));
      final newerSnapshot = await deserializer.deserializeBytes(gzippedNewer);

      await restoreService.restoreSnapshot(db, newerSnapshot);

      var currentBook = await db.bookDao.getBookById(bookId);
      expect(currentBook?.status, 'finished',
          reason: 'Newer backup record must overwrite local record');
      expect(currentBook?.lastReadPage, 658);

      // Now attempt restore with an OLDER backup (updatedAt = 500, status = 'tbr')
      final olderSnapshotJson = {
        'schema_version': 1,
        'app_version': '1.1.0',
        'exported_at': 500,
        'device_id': 'old-device',
        'data': {
          'books': [
            {
              'id': bookId,
              'title': 'Dune',
              'authors': jsonEncode(['Frank Herbert']),
              'status': 'tbr',
              'spine_color_hex': 0xFFE0A96D,
              'spine_text_hex': 0xFF000000,
              'last_read_page': 1,
              'created_at': 1000,
              'updated_at': 500,
            }
          ],
          'shelves': [],
          'shelf_items': [],
          'book_shelves': [],
          'reading_sessions': [],
          'book_notes': [],
        }
      };

      final gzippedOlder = gzip.encode(utf8.encode(jsonEncode(olderSnapshotJson)));
      final olderSnapshot = await deserializer.deserializeBytes(gzippedOlder);

      await restoreService.restoreSnapshot(db, olderSnapshot);

      currentBook = await db.bookDao.getBookById(bookId);
      expect(currentBook?.status, 'finished',
          reason: 'Older backup record must NEVER overwrite newer local state');
      expect(currentBook?.lastReadPage, 658);
    });

    test(
        'Corrupt or truncated .rsbk payload fails gracefully with BackupFailure and leaves DB untouched',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed local book
      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: 'intact-book',
          title: 'The Hobbit',
          authors: jsonEncode(['J.R.R. Tolkien']),
          status: 'reading',
          spineColorHex: 0xFF3D5A40,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Corrupt bytes (random garbage)
      final corruptBytes = [0x1F, 0x8B, 0x08, 0xDE, 0xAD, 0xBE, 0xEF, 0x00];

      expect(
        () => deserializer.deserializeBytes(corruptBytes),
        throwsA(isA<BackupFailure>()),
      );

      // Verify local database remains completely untouched
      final books = await db.bookDao.getAllBooks();
      expect(books.length, 1);
      expect(books.first.id, 'intact-book');
      expect(books.first.title, 'The Hobbit');
    });
  });
}
