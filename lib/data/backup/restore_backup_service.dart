import 'package:drift/drift.dart';
import '../local/database.dart';
import 'models/backup_snapshot_dto.dart';

/// Restore operation mode.
enum RestoreMode {
  /// Preserves local data and merges records using Last-Write-Wins (LWW) based on timestamps.
  smartMerge,

  /// Wipes all existing local database tables before writing backup records.
  overwrite,
}

/// Result of a restore operation detailing record counts.
class RestoreResult {
  final bool success;
  final int booksMerged;
  final int shelvesMerged;
  final int sessionsMerged;
  final int notesMerged;
  final String message;

  const RestoreResult({
    required this.success,
    this.booksMerged = 0,
    this.shelvesMerged = 0,
    this.sessionsMerged = 0,
    this.notesMerged = 0,
    required this.message,
  });
}

/// Service that executes atomic database restoration from a BackupSnapshotDto.
class RestoreBackupService {
  /// Restores a snapshot into [db] inside a single atomic SQLite transaction.
  Future<RestoreResult> restoreSnapshot(
    AppDatabase db,
    BackupSnapshotDto snapshot, {
    RestoreMode mode = RestoreMode.smartMerge,
  }) async {
    return db.transaction(() async {
      if (mode == RestoreMode.overwrite) {
        // Clear all tables in dependency order
        await db.delete(db.bookNotes).go();
        await db.delete(db.readingSessions).go();
        await db.delete(db.bookShelves).go();
        await db.delete(db.shelfItems).go();
        await db.delete(db.books).go();
        await db.delete(db.shelves).go();
      }

      int booksMerged = 0;
      int shelvesMerged = 0;
      int sessionsMerged = 0;
      int notesMerged = 0;

      // 1. Restore Shelves
      final existingShelves = await db.shelfDao.getAllShelves();
      final shelfMap = {for (final s in existingShelves) s.id: s};

      for (final raw in snapshot.shelves) {
        final id = raw['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final updatedAt = (raw['updated_at'] as num?)?.toInt() ?? 0;
        final existing = shelfMap[id];

        final companion = ShelvesCompanion(
          id: Value(id),
          name: Value(raw['name']?.toString() ?? 'Shelf'),
          woodThemeId: Value(raw['wood_theme_id']?.toString() ?? 'oak'),
          wallThemeId: Value(raw['wall_theme_id']?.toString() ?? 'warm_cream'),
          sortOrder: Value((raw['sort_order'] as num?)?.toInt() ?? 0),
          createdAt: Value((raw['created_at'] as num?)?.toInt() ?? 0),
          updatedAt: Value(updatedAt),
          deletedAt: Value((raw['deleted_at'] as num?)?.toInt()),
        );

        if (existing == null) {
          await db.into(db.shelves).insert(companion);
          shelvesMerged++;
        } else if (updatedAt >= existing.updatedAt) {
          await db.update(db.shelves).replace(companion);
          shelvesMerged++;
        }
      }

      // 2. Restore Books (Smart LWW Merge matching by ID or ISBN-13)
      final existingBooks =
          await db.bookDao.getAllBooks(includeDeleted: true);
      final bookIdMap = {for (final b in existingBooks) b.id: b};
      final bookIsbnMap = {
        for (final b in existingBooks)
          if (b.isbn13 != null && b.isbn13!.isNotEmpty) b.isbn13!: b
      };

      for (final raw in snapshot.books) {
        final id = raw['id']?.toString() ?? '';
        final isbn13 = raw['isbn13']?.toString();
        if (id.isEmpty) continue;

        final updatedAt = (raw['updated_at'] as num?)?.toInt() ?? 0;

        // Check if book exists locally either by ID or ISBN
        Book? existing = bookIdMap[id];
        if (existing == null && isbn13 != null && isbn13.isNotEmpty) {
          existing = bookIsbnMap[isbn13];
        }

        final companion = BooksCompanion(
          id: Value(existing?.id ?? id),
          isbn13: Value(isbn13),
          title: Value(raw['title']?.toString() ?? 'Untitled'),
          subtitle: Value(raw['subtitle']?.toString()),
          description: Value(raw['description']?.toString()),
          publisher: Value(raw['publisher']?.toString()),
          publishYear: Value(raw['publish_year']?.toString()),
          authors: Value(raw['authors']?.toString() ?? '[]'),
          pageCount: Value((raw['page_count'] as num?)?.toInt() ?? 250),
          format: Value(raw['format']?.toString() ?? 'paperback'),
          status: Value(raw['status']?.toString() ?? 'tbr'),
          finishedAt: Value((raw['finished_at'] as num?)?.toInt()),
          seriesName: Value(raw['series_name']?.toString()),
          seriesIndex:
              Value((raw['series_index'] as num?)?.toDouble()),
          coverPath: Value(raw['cover_path']?.toString()),
          backCoverPath: Value(raw['back_cover_path']?.toString()),
          customSpinePath: Value(raw['custom_spine_path']?.toString()),
          pdfPath: Value(raw['pdf_path']?.toString()),
          lastReadPage:
              Value((raw['last_read_page'] as num?)?.toInt() ?? 1),
          spineColorHex:
              Value((raw['spine_color_hex'] as num?)?.toInt() ?? 0xFF123456),
          spineTextHex:
              Value((raw['spine_text_hex'] as num?)?.toInt() ?? 0xFFFFFFFF),
          rating: Value((raw['rating'] as num?)?.toDouble()),
          ratingPlot: Value((raw['rating_plot'] as num?)?.toDouble()),
          ratingCharacters:
              Value((raw['rating_characters'] as num?)?.toDouble()),
          ratingWriting:
              Value((raw['rating_writing'] as num?)?.toDouble()),
          ratingPacing: Value((raw['rating_pacing'] as num?)?.toDouble()),
          lastReadAt: Value((raw['last_read_at'] as num?)?.toInt()),
          createdAt: Value((raw['created_at'] as num?)?.toInt() ?? 0),
          updatedAt: Value(updatedAt),
          deletedAt: Value((raw['deleted_at'] as num?)?.toInt()),
        );

        if (existing == null) {
          await db.into(db.books).insert(companion);
          booksMerged++;
        } else if (updatedAt >= existing.updatedAt) {
          // Last-Write-Wins
          await db.update(db.books).replace(companion);
          booksMerged++;
        }
      }

      // 3. Restore ShelfItems
      final existingItems = await db.select(db.shelfItems).get();
      final itemMap = {for (final i in existingItems) i.id: i};

      for (final raw in snapshot.shelfItems) {
        final id = raw['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        if (!itemMap.containsKey(id)) {
          final companion = ShelfItemsCompanion(
            id: Value(id),
            shelfId: Value(raw['shelf_id']?.toString() ?? ''),
            itemType: Value(raw['item_type']?.toString() ?? 'book'),
            bookId: Value(raw['book_id']?.toString()),
            propAssetId: Value(raw['prop_asset_id']?.toString()),
            displayMode: Value(raw['display_mode']?.toString() ?? 'spine'),
            positionIndex:
                Value((raw['position_index'] as num?)?.toInt() ?? 0),
          );
          await db.into(db.shelfItems).insert(companion);
        }
      }

      // 4. Restore BookShelves (Many-to-many junction)
      for (final raw in snapshot.bookShelves) {
        final bookId = raw['book_id']?.toString() ?? '';
        final shelfId = raw['shelf_id']?.toString() ?? '';
        if (bookId.isNotEmpty && shelfId.isNotEmpty) {
          await db.into(db.bookShelves).insert(
                BookShelvesCompanion(
                  bookId: Value(bookId),
                  shelfId: Value(shelfId),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }

      // 5. Restore ReadingSessions
      final existingSessions = await db.sessionDao.getAllSessions();
      final sessionMap = {for (final s in existingSessions) s.id: s};

      for (final raw in snapshot.readingSessions) {
        final id = raw['id']?.toString() ?? '';
        if (id.isNotEmpty && !sessionMap.containsKey(id)) {
          final companion = ReadingSessionsCompanion(
            id: Value(id),
            bookId: Value(raw['book_id']?.toString() ?? ''),
            startTime: Value((raw['start_time'] as num?)?.toInt() ?? 0),
            durationSeconds:
                Value((raw['duration_seconds'] as num?)?.toInt() ?? 0),
            startPage: Value((raw['start_page'] as num?)?.toInt() ?? 0),
            endPage: Value((raw['end_page'] as num?)?.toInt() ?? 0),
          );
          await db.into(db.readingSessions).insert(companion);
          sessionsMerged++;
        }
      }

      // 6. Restore BookNotes
      final existingNotes = await db.select(db.bookNotes).get();
      final noteMap = {for (final n in existingNotes) n.id: n};

      for (final raw in snapshot.bookNotes) {
        final id = raw['id']?.toString() ?? '';
        if (id.isNotEmpty && !noteMap.containsKey(id)) {
          final companion = BookNotesCompanion(
            id: Value(id),
            bookId: Value(raw['book_id']?.toString() ?? ''),
            noteType: Value(raw['note_type']?.toString() ?? 'thought'),
            content: Value(raw['content']?.toString() ?? ''),
            pageNumber: Value((raw['page_number'] as num?)?.toInt()),
            createdAt: Value((raw['created_at'] as num?)?.toInt() ?? 0),
          );
          await db.into(db.bookNotes).insert(companion);
          notesMerged++;
        }
      }

      return RestoreResult(
        success: true,
        booksMerged: booksMerged,
        shelvesMerged: shelvesMerged,
        sessionsMerged: sessionsMerged,
        notesMerged: notesMerged,
        message: 'Successfully merged backup data idempotently.',
      );
    });
  }
}
