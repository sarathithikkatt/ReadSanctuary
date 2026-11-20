import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/book_dao.dart';
import 'daos/session_dao.dart';
import 'daos/shelf_dao.dart';
import 'tables/book_notes.dart';
import 'tables/book_shelves.dart';
import 'tables/books.dart';
import 'tables/reading_sessions.dart';
import 'tables/shelf_items.dart';
import 'tables/shelves.dart';

export 'daos/book_dao.dart';
export 'daos/session_dao.dart';
export 'daos/shelf_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Books, Shelves, ShelfItems, ReadingSessions, BookNotes, BookShelves],
  daos: [BookDao, ShelfDao, SessionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(books, books.pdfPath);
            await m.addColumn(books, books.lastReadPage);
          }
          if (from < 3) {
            await m.addColumn(books, books.ratingPlot);
            await m.addColumn(books, books.ratingCharacters);
            await m.addColumn(books, books.ratingWriting);
            await m.addColumn(books, books.ratingPacing);
          }
          if (from < 4) {
            await m.addColumn(books, books.finishedAt);
            await m.addColumn(books, books.description);
            await m.addColumn(books, books.publisher);
            await m.addColumn(books, books.publishYear);
            await customStatement(
                'CREATE INDEX IF NOT EXISTS books_status_idx ON books (status);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS shelves_sort_order_idx ON shelves (sort_order);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS shelf_items_shelf_idx ON shelf_items (shelf_id, position_index);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS shelf_items_book_idx ON shelf_items (book_id);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS reading_sessions_book_idx ON reading_sessions (book_id);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS reading_sessions_time_idx ON reading_sessions (start_time);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS book_notes_book_idx ON book_notes (book_id);');
          }
          if (from < 5) {
            await m.addColumn(books, books.backCoverPath);
          }
          if (from < 6) {
            await m.addColumn(books, books.lastReadAt);
            await m.addColumn(books, books.deletedAt);
            await m.addColumn(shelves, shelves.createdAt);
            await m.addColumn(shelves, shelves.updatedAt);
            await m.addColumn(shelves, shelves.deletedAt);
            await m.createTable(bookShelves);
            await customStatement(
                'CREATE INDEX IF NOT EXISTS books_last_read_at_idx ON books (last_read_at);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS book_shelves_shelf_idx ON book_shelves (shelf_id);');
            await createFtsTableAndTriggers();
            await populateFtsFromExistingBooks();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          if (details.wasCreated) {
            await createFtsTableAndTriggers();
            final count = await customSelect('SELECT COUNT(*) AS c FROM shelves;')
                .map((row) => row.read<int>('c'))
                .getSingle();
            if (count == 0) {
              await into(shelves).insert(
                ShelvesCompanion.insert(
                  id: 'default-shelf-reading',
                  name: 'Currently Reading',
                  woodThemeId: const Value('oak'),
                  wallThemeId: const Value('warm_cream'),
                  sortOrder: 0,
                  createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                ),
              );
              await into(shelves).insert(
                ShelvesCompanion.insert(
                  id: 'default-shelf-favorites',
                  name: 'Favorites & TBR',
                  woodThemeId: const Value('oak'),
                  wallThemeId: const Value('warm_cream'),
                  sortOrder: 1,
                  createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                ),
              );
            }
          }
        },
      );

  /// Creates SQLite FTS5 virtual table and synchronization triggers.
  Future<void> createFtsTableAndTriggers() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS books_fts USING fts5(
        book_id UNINDEXED,
        title,
        authors,
        description,
        notes,
        tokenize='porter unicode61'
      );
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS books_fts_ai AFTER INSERT ON books BEGIN
        INSERT INTO books_fts(book_id, title, authors, description, notes)
        VALUES (new.id, new.title, new.authors, coalesce(new.description, ''), '');
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS books_fts_au AFTER UPDATE ON books BEGIN
        DELETE FROM books_fts WHERE book_id = old.id;
        INSERT INTO books_fts(book_id, title, authors, description, notes)
        VALUES (new.id, new.title, new.authors, coalesce(new.description, ''), '');
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS books_fts_ad AFTER DELETE ON books BEGIN
        DELETE FROM books_fts WHERE book_id = old.id;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS book_notes_fts_ai AFTER INSERT ON book_notes BEGIN
        INSERT INTO books_fts(book_id, title, authors, description, notes)
        VALUES (new.book_id, '', '', '', new.content);
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS book_notes_fts_ad AFTER DELETE ON book_notes BEGIN
        DELETE FROM books_fts WHERE rowid IN (
          SELECT rowid FROM books_fts WHERE book_id = old.book_id AND notes = old.content LIMIT 1
        );
      END;
    ''');
  }

  /// Populates the FTS5 table with existing rows on migration.
  Future<void> populateFtsFromExistingBooks() async {
    await customStatement('''
      INSERT INTO books_fts(book_id, title, authors, description, notes)
      SELECT id, title, authors, coalesce(description, ''), '' FROM books;
    ''');
    await customStatement('''
      INSERT INTO books_fts(book_id, title, authors, description, notes)
      SELECT book_id, '', '', '', content FROM book_notes;
    ''');
  }

  /// Checkpoints SQLite WAL so all data is flushed to app_database.sqlite
  Future<void> checkpointWal() async {
    await customStatement('PRAGMA wal_checkpoint(FULL);');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final bookDaoProvider = Provider<BookDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.bookDao;
});

final shelfDaoProvider = Provider<ShelfDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.shelfDao;
});

final sessionDaoProvider = Provider<SessionDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionDao;
});
