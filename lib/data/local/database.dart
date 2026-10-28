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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
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
