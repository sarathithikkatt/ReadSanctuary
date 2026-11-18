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
import 'tables/books.dart';
import 'tables/reading_sessions.dart';
import 'tables/shelf_items.dart';
import 'tables/shelves.dart';

export 'daos/book_dao.dart';
export 'daos/session_dao.dart';
export 'daos/shelf_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Books, Shelves, ShelfItems, ReadingSessions, BookNotes],
  daos: [BookDao, ShelfDao, SessionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 4;

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
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          if (details.wasCreated) {
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
                ),
              );
              await into(shelves).insert(
                ShelvesCompanion.insert(
                  id: 'default-shelf-favorites',
                  name: 'Favorites & TBR',
                  woodThemeId: const Value('oak'),
                  wallThemeId: const Value('warm_cream'),
                  sortOrder: 1,
                ),
              );
            }
          }
        },
      );

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
