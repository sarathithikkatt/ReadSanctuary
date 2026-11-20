import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readsanctuary/data/local/database.dart';
import 'package:readsanctuary/presentation/providers/filtered_library_provider.dart';
import 'package:readsanctuary/presentation/providers/library_filter_provider.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/dialogs/library_filter_bottom_sheet.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/widgets/library_grid_view.dart';
import 'package:readsanctuary/presentation/widgets/cover_image_card.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 4: Library Filtering & High-Signal UX Tests', () {
    testWidgets('CoverImageCard renders typographic fallback card when offline/no image',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CoverImageCard(
              title: 'The Way of Kings',
              author: 'Brandon Sanderson',
              spineColorHex: 0xFF123456,
              spineTextHex: 0xFFFFFFFF,
            ),
          ),
        ),
      );

      expect(find.text('The Way of Kings'), findsOneWidget);
      expect(find.text('Brandon Sanderson'), findsOneWidget);
    });

    testWidgets('LibraryFilterBottomSheet renders Filter and Sort tabs with chips',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LibraryFilterBottomSheet(),
            ),
          ),
        ),
      );

      // Verify tabs
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Sort'), findsOneWidget);

      // Verify filter chips
      expect(find.text('Reading Status'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('Minimum Rating'), findsOneWidget);

      // Switch to Sort tab
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      expect(find.text('Last Read'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Progress %'), findsOneWidget);
    });

    testWidgets('LibraryGridView renders books with progress bars and badges',
        (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final testBooks = [
        Book(
          id: 'b1',
          title: 'Hyperion',
          authors: 'Dan Simmons',
          pageCount: 500,
          format: 'paperback',
          status: 'reading',
          lastReadPage: 250,
          spineColorHex: 0xFF2A2A2A,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
        Book(
          id: 'b2',
          title: 'Neuromancer',
          authors: 'William Gibson',
          pageCount: 300,
          format: 'paperback',
          status: 'finished',
          lastReadPage: 300,
          spineColorHex: 0xFF003366,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryGridView(books: testBooks, isGridView: true),
          ),
        ),
      );

      expect(find.text('Hyperion'), findsNWidgets(2));
      expect(find.text('Neuromancer'), findsNWidgets(2));
      // Finished checkmark badge for finished book
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    test('LibraryFilterNotifier and filteredBooksProvider filter by status and sort correctly',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed books
      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: 'b-alpha',
          title: 'Alpha Book',
          authors: jsonEncode(['Author A']),
          status: 'reading',
          spineColorHex: 0xFF123456,
          spineTextHex: 0xFFFFFFFF,
          rating: const Value(4.5),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: 'b-beta',
          title: 'Beta Book',
          authors: jsonEncode(['Author B']),
          status: 'finished',
          spineColorHex: 0xFF654321,
          spineTextHex: 0xFFFFFFFF,
          rating: const Value(3.0),
          createdAt: now + 100,
          updatedAt: now + 100,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      // Listen to filtered stream
      final filterNotifier = container.read(libraryFilterProvider.notifier);

      // Default: all books returned
      var books = await container.read(filteredBooksProvider.future);
      expect(books.length, 2);

      // Filter by status = 'reading'
      filterNotifier.setStatus('reading');
      books = await container.read(filteredBooksProvider.future);
      expect(books.length, 1);
      expect(books.first.id, 'b-alpha');

      // Filter by min rating 4.0
      filterNotifier.setStatus(null);
      filterNotifier.setMinRating(4.0);
      books = await container.read(filteredBooksProvider.future);
      expect(books.length, 1);
      expect(books.first.id, 'b-alpha');

      // Sort by Title ascending
      filterNotifier.setMinRating(null);
      filterNotifier.setSortBy(LibrarySortField.title, ascending: true);
      books = await container.read(filteredBooksProvider.future);
      expect(books.first.title, 'Alpha Book');
      expect(books.last.title, 'Beta Book');
    });
  });
}
