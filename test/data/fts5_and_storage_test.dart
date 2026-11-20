import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readsanctuary/data/local/database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Trigger creation and FTS setup
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 2: Drift SQLite + FTS5 Verification Tests', () {
    test('FTS5 triggers keep books_fts in sync on insert, update, and note creation',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Insert book
      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: 'book-1',
          title: 'The Name of the Wind',
          authors: jsonEncode(['Patrick Rothfuss']),
          status: 'reading',
          spineColorHex: 0xFF2A1B0E,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
          description: const Value('A hero recounts his legendary past.'),
        ),
      );

      // Verify search finds it by title, author, or description
      var results = await db.bookDao.searchBooksFts('Rothfuss');
      expect(results.length, 1);
      expect(results.first.id, 'book-1');

      results = await db.bookDao.searchBooksFts('legendary');
      expect(results.length, 1);
      expect(results.first.id, 'book-1');

      // 2. Update book
      final current = await db.bookDao.getBookById('book-1');
      expect(current, isNotNull);
      await db.bookDao.updateBook(
        current!.copyWith(
          title: 'The Wise Man\'s Fear',
          updatedAt: now + 1000,
        ),
      );

      // Search for old title should return 0, new title returns 1
      results = await db.bookDao.searchBooksFts('Wind');
      expect(results, isEmpty);

      results = await db.bookDao.searchBooksFts('Wise');
      expect(results.length, 1);
      expect(results.first.title, 'The Wise Man\'s Fear');

      // 3. Insert note into book_notes
      await db.sessionDao.insertNote(
        BookNotesCompanion.insert(
          id: 'note-1',
          bookId: 'book-1',
          noteType: 'quote',
          content: 'There are three things all wise men fear: the sea in storm.',
          createdAt: now,
        ),
      );

      results = await db.bookDao.searchBooksFts('storm');
      expect(results.length, 1);
      expect(results.first.id, 'book-1');

      // 4. Soft-delete book
      await db.bookDao.softDeleteBook('book-1');
      results = await db.bookDao.searchBooksFts('Wise');
      expect(results, isEmpty, reason: 'Soft-deleted books must not appear in FTS search');

      // 5. Hard delete book
      await db.bookDao.deleteBook('book-1');
      final ftsRows = await db
          .customSelect('SELECT * FROM books_fts WHERE book_id = ?',
              variables: [Variable.withString('book-1')])
          .get();
      expect(ftsRows, isEmpty, reason: 'AFTER DELETE trigger must clean up books_fts');
    });

    test('High-Volume Benchmark: 2,000+ mock books search completes in under 15ms',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final mockBooks = <Insertable<Book>>[];

      // Generate 2,050 mock books
      for (int i = 0; i < 2050; i++) {
        mockBooks.add(
          BooksCompanion.insert(
            id: 'mock-book-$i',
            title: i == 1742
                ? 'Hyperion Cantos Chronicles'
                : 'Sample Book Volume $i of the Empire',
            authors: jsonEncode(i == 1742 ? ['Dan Simmons'] : ['Author $i']),
            status: i % 2 == 0 ? 'reading' : 'finished',
            spineColorHex: 0xFF123456,
            spineTextHex: 0xFFFFFFFF,
            createdAt: now,
            updatedAt: now,
            description: Value(
              i == 1742
                  ? 'On the world of Hyperion beyond the reach of galactic law.'
                  : 'Generic description text for mock book volume number $i.',
            ),
          ),
        );
      }

      // Batch insert into database
      await db.bookDao.insertBooks(mockBooks);

      // Verify count
      final count = await db.customSelect('SELECT COUNT(*) AS c FROM books')
          .map((row) => row.read<int>('c'))
          .getSingle();
      expect(count, 2050);

      // Benchmark FTS5 Search
      final stopwatch = Stopwatch()..start();
      final results = await db.bookDao.searchBooksFts('Hyperion');
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      expect(results.length, 1);
      expect(results.first.id, 'mock-book-1742');
      expect(results.first.title, 'Hyperion Cantos Chronicles');

      // Acceptance criterion: under 15ms
      expect(elapsedMs, lessThan(15),
          reason: 'FTS5 search took ${elapsedMs}ms, which should be under 15ms');
    });

    test(
        'Reactive Drift streams update immediately on page or session update with zero manual refreshes',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: 'reactive-book',
          title: 'Atomic Habits',
          authors: jsonEncode(['James Clear']),
          status: 'reading',
          pageCount: const Value(320),
          lastReadPage: const Value(10),
          spineColorHex: 0xFFFFFFFF,
          spineTextHex: 0xFF000000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final stream = db.bookDao.watchBookById('reactive-book');

      // Verify stream emits updated page count immediately
      expect(
        stream.map((b) => b?.lastReadPage),
        emitsInOrder([10, 42]),
      );

      // Trigger update
      await Future.delayed(const Duration(milliseconds: 50));
      await db.bookDao.updateBookLastReadPage('reactive-book', 42);
    });
  });
}
