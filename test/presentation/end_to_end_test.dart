import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelfcraft/app.dart';
import 'package:shelfcraft/data/local/database.dart';
import 'package:shelfcraft/data/services/csv_import_service.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/book_spine_25d_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  Widget buildTestableApp() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const ShelfCraftApp(),
    );
  }

  group('End-to-End User Flow Tests', () {
    testWidgets(
        'E2E: App boots, verifies default shelves, adds book, opens details, edits and logs session',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      // 1. Pump App
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('ShelfCraft'), findsWidgets);
      expect(find.text('Bookshelf'), findsOneWidget);
      expect(find.text('Scan ISBN'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Backup & Pro'), findsOneWidget);

      // Verify default shelves seeded by migration
      final defaultShelves = await db.shelfDao.getAllShelves();
      expect(defaultShelves.length, 2);
      expect(defaultShelves[0].name, 'Currently Reading');
      expect(defaultShelves[1].name, 'Favorites & TBR');

      // Verify shelves show on screen
      expect(find.text('Currently Reading'), findsOneWidget);
      expect(find.text('Favorites & TBR'), findsOneWidget);

      // 2. Add Book Manually via UI dialog
      final addBookFab = find.widgetWithText(FloatingActionButton, 'Add Book');
      expect(addBookFab, findsOneWidget);
      await tester.tap(addBookFab);
      await tester.pumpAndSettle();

      expect(find.text('Add Book to Shelf'), findsOneWidget);

      // Fill in fields
      await tester.enterText(
          find.widgetWithText(TextField, 'Book Title *'), 'The Way of Kings');
      await tester.enterText(
          find.widgetWithText(TextField, 'Author *'), 'Brandon Sanderson');
      await tester.enterText(
          find.widgetWithText(TextField, 'Page Count'), '1007');
      await tester.enterText(
          find.widgetWithText(TextField, 'Series (optional)'),
          'The Stormlight Archive');
      await tester.enterText(
          find.widgetWithText(TextField, 'Vol # (e.g. 1.5)'), '1.0');

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Book'));
      await tester.pumpAndSettle();

      // Verify book was saved to DB and placed on shelf
      final allBooks = await db.bookDao.getAllBooks();
      expect(allBooks.length, 1);
      final book = allBooks.first;
      expect(book.title, 'The Way of Kings');
      expect(book.pageCount, 1007);
      expect(book.seriesName, 'The Stormlight Archive');
      expect(book.seriesIndex, 1.0);

      final shelfItems =
          await db.shelfDao.getItemsForShelf(defaultShelves.first.id);
      expect(shelfItems.length, 1);
      expect(shelfItems.first.bookId, book.id);

      // Verify book spine rendered on the shelf
      expect(find.text('The Way of Kings'), findsWidgets);

      // 3. Tap on the book spine to open BookDetailScreen
      await tester.tap(find.byType(BookSpine25DWidget).first);
      await tester.pumpAndSettle();

      // Should be on BookDetailScreen
      expect(find.text('Read Timer'), findsOneWidget);
      expect(find.text('Quote OCR'), findsOneWidget);
      expect(find.text('Quotes & Notes'), findsOneWidget);
      expect(find.text('Reading Sessions'), findsOneWidget);
      expect(find.text('The Stormlight Archive #1.0'), findsOneWidget);

      // 4. Test Edit Book Details Dialog
      final editButton = find.byTooltip('Edit Details');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Edit Book Details'), findsOneWidget);
      // Change rating slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.tap(slider);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // 5. Open ReadingTimerScreen from BookDetailScreen
      expect(find.text('Read Timer'), findsOneWidget);
      await tester.tap(find.text('Read Timer'));
      await tester.pumpAndSettle();

      expect(find.text('Focus Reading Timer'), findsOneWidget);
      expect(find.text('The Way of Kings'), findsWidgets);

      // Start timer
      final playFab = find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton && widget.heroTag == 'play_btn',
      );
      expect(playFab, findsOneWidget);
      await tester.tap(playFab);
      await tester.pump(const Duration(seconds: 3));

      // Pause timer
      final pauseFab = find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton && widget.heroTag == 'pause_btn',
      );
      expect(pauseFab, findsOneWidget);
      await tester.tap(pauseFab);
      await tester.pumpAndSettle();

      // Stop & Finish session
      final stopFab = find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton && widget.heroTag == 'stop_btn',
      );
      expect(stopFab, findsOneWidget);
      await tester.tap(stopFab);
      await tester.pumpAndSettle();

      expect(find.text('Log Reading Session'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '45');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Session'));
      await tester.pumpAndSettle();

      // Verify session in DB
      final sessions = await db.sessionDao.getAllSessions();
      expect(sessions.length, 1);
      expect(sessions.first.bookId, book.id);
      expect(sessions.first.endPage, 45);

      // Pop back from BookDetailScreen to Bookshelf
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 6. Navigate to Stats tab
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();

      expect(find.text('Reading Insights & Stats'), findsOneWidget);
      expect(find.text('Best Daily Streak'), findsOneWidget);
      expect(find.textContaining('Reading Goal'), findsOneWidget);

      // 7. Navigate to Backup & Pro tab
      await tester.tap(find.text('Backup & Pro'));
      await tester.pumpAndSettle();

      expect(find.text('Settings & Data Backup'), findsOneWidget);
      expect(find.text('Google Drive AppData Backup'), findsOneWidget);
      expect(find.text('Export Local .ZIP Backup'), findsOneWidget);
      expect(find.text('Import Goodreads / StoryGraph CSV'), findsOneWidget);

      // Test Pro Paywall modal when tapping cloud backup as free user
      await tester.tap(find.text('Google Drive AppData Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Unlock ShelfCraft Pro'), findsOneWidget);
      expect(find.text('Unlock Lifetime Pro (\$9.99)'), findsOneWidget);

      // Unlock Pro via button in modal
      final unlockBtn =
          find.widgetWithText(ElevatedButton, 'Unlock Lifetime Pro (\$9.99)');
      await tester.tap(unlockBtn);
      await tester.pumpAndSettle();

      expect(find.text('ShelfCraft Pro Active'), findsOneWidget);

      // Return to bookshelf tab
      await tester.tap(find.text('Bookshelf'));
      await tester.pumpAndSettle();
      expect(find.text('ShelfCraft'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await db.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('E2E: CSV Import Populates Database and Shelf Items',
        (WidgetTester tester) async {
      final csvService = CsvImportService();
      const goodreadsCsv = '''
Book Id,Title,Author,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Recommended For,Recommended By,Owned Copies
12345,"Words of Radiance (The Stormlight Archive, #2)",Brandon Sanderson,,="0765326361",="9780765326362",5,4.76,Tor Books,Hardcover,1087,2014,2014,2023/05/10,2023/01/01,currently-reading,1,currently-reading,,,,1,,,0
67890,"Edgedancer (The Stormlight Archive, #2.5)",Brandon Sanderson,,="125016654X",="9781250166548",4,4.21,Tor Books,Paperback,272,2017,2016,2023/06/01,2023/05/15,read,2,read,,,,1,,,0
''';

      final parseResult = csvService.parseCsv(goodreadsCsv);
      expect(parseResult.books.length, 2);
      expect(parseResult.books[0].title.value, 'Words of Radiance');
      expect(parseResult.books[0].seriesIndex.value, 2.0);
      expect(parseResult.books[1].title.value, 'Edgedancer');
      expect(parseResult.books[1].seriesIndex.value, 2.5);

      // Insert into DB
      await db.bookDao.insertBooks(parseResult.books);

      // Attach to shelf
      final allShelves = await db.shelfDao.getAllShelves();
      final shelfId = allShelves.first.id;

      for (int i = 0; i < parseResult.books.length; i++) {
        await db.shelfDao.insertShelfItem(
          ShelfItemsCompanion.insert(
            id: 'item-$i',
            shelfId: shelfId,
            itemType: 'book',
            bookId: drift.Value(parseResult.books[i].id.value),
            positionIndex: i,
          ),
        );
      }

      // Verify books on shelf
      final items = await db.shelfDao.getItemsForShelf(shelfId);
      expect(items.length, 2);

      // Pump app and verify rendering
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('Words of Radiance'), findsWidgets);
      expect(find.text('Edgedancer'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await db.close();
      await tester.pump(Duration.zero);
    });
  });
}
