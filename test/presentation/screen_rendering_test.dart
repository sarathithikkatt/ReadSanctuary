import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readsanctuary/core/utils/color_extractor.dart';
import 'package:readsanctuary/data/local/database.dart';
import 'package:readsanctuary/data/services/revenuecat_service.dart';
import 'package:readsanctuary/presentation/screens/book_detail/book_detail_screen.dart';
import 'package:readsanctuary/presentation/screens/book_detail/ocr_quote_scanner.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/bookshelf_screen.dart';
import 'package:readsanctuary/presentation/screens/settings_backup/settings_backup_screen.dart';
import 'package:readsanctuary/presentation/screens/spine_cropper/spine_cropper_screen.dart';
import 'package:readsanctuary/presentation/screens/stats/stats_screen.dart';
import 'package:readsanctuary/presentation/screens/timer/reading_timer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrapWithMaterial(Widget widget, {bool isPro = false}) {
    return ProviderScope(
      key: ValueKey('scope_$isPro'),
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isProUserProvider.overrideWith((ref) {
          final notifier = ProUserNotifier();
          notifier.setDebugProOverride(isPro);
          return notifier;
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC79C5E),
          ),
        ),
        home: widget,
      ),
    );
  }

  group('Visual & Layout Rendering Tests Across Multiple Screen Sizes', () {
    const screenSizes = [
      Size(360, 640), // Compact Mobile (small Android)
      Size(390, 844), // Standard Modern Mobile (iPhone 14/15/16)
      Size(800, 1200), // Tablet / Desktop
    ];

    for (final size in screenSizes) {
      testWidgets(
          'BookshelfScreen renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);

        // Seed books and shelf items
        final allShelves = await db.shelfDao.getAllShelves();
        final shelfId = allShelves.first.id;

        for (int i = 0; i < 5; i++) {
          final bookId = 'book-$i';
          final title = 'Book Title $i';
          final spineColors = ColorExtractor.generateFromTitle(title);
          await db.bookDao.insertBook(
            BooksCompanion.insert(
              id: bookId,
              title: title,
              authors: '["Author $i"]',
              pageCount: drift.Value(200 + i * 150),
              format: drift.Value(i % 2 == 0 ? 'hardcover' : 'paperback'),
              status: 'reading',
              spineColorHex: spineColors.spineColorHex,
              spineTextHex: spineColors.spineTextHex,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

          await db.shelfDao.insertShelfItem(
            ShelfItemsCompanion.insert(
              id: 'shelf-item-$i',
              shelfId: shelfId,
              itemType: 'book',
              bookId: drift.Value(bookId),
              displayMode: drift.Value(i == 1 ? 'cover_out' : 'spine'),
              positionIndex: i,
            ),
          );
        }

        // Add a prop and a gap
        await db.shelfDao.insertShelfItem(
          ShelfItemsCompanion.insert(
            id: 'prop-item',
            shelfId: shelfId,
            itemType: 'prop',
            propAssetId: const drift.Value('plant_monstera'),
            positionIndex: 5,
          ),
        );
        await db.shelfDao.insertShelfItem(
          ShelfItemsCompanion.insert(
            id: 'gap-item',
            shelfId: shelfId,
            itemType: 'gap',
            positionIndex: 6,
          ),
        );

        await tester.pumpWidget(wrapWithMaterial(const BookshelfScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(BookshelfScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      });

      testWidgets(
          'BookDetailScreen renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);

        final now = DateTime.now().millisecondsSinceEpoch;
        const bookId = 'detail-test-book';
        const spineColors = SpineColors.fallback;

        await db.bookDao.insertBook(
          BooksCompanion.insert(
            id: bookId,
            title: 'The Way of Kings: Special Extended Novella Edition',
            authors: jsonEncode(['Brandon Sanderson', 'Co-Author']),
            pageCount: const drift.Value(1007),
            format: const drift.Value('hardcover'),
            status: 'reading',
            seriesName: const drift.Value('The Stormlight Archive'),
            seriesIndex: const drift.Value(1.5),
            rating: const drift.Value(4.75),
            spineColorHex: spineColors.spineColorHex,
            spineTextHex: spineColors.spineTextHex,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Add notes and sessions
        await db.sessionDao.insertNote(
          BookNotesCompanion.insert(
            id: 'note-1',
            bookId: bookId,
            noteType: 'quote',
            content:
                'Life before death. Strength before weakness. Journey before destination.',
            pageNumber: const drift.Value(160),
            createdAt: now,
          ),
        );

        await db.sessionDao.insertSession(
          ReadingSessionsCompanion.insert(
            id: 'session-1',
            bookId: bookId,
            startTime: now - 3600000,
            durationSeconds: 1800,
            startPage: 1,
            endPage: 45,
          ),
        );

        await tester.pumpWidget(
            wrapWithMaterial(const BookDetailScreen(bookId: bookId)));
        await tester.pumpAndSettle();

        expect(find.byType(BookDetailScreen), findsOneWidget);
        expect(find.text('The Stormlight Archive #1.5'), findsOneWidget);
        expect(find.text('4.75 / 5.0'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      });

      testWidgets(
          'ReadingTimerScreen renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);

        const spineColors = SpineColors.fallback;
        final dummyBook = Book(
          id: 'timer-book',
          title: 'A Memory of Light',
          authors: '["Robert Jordan", "Brandon Sanderson"]',
          pageCount: 909,
          format: 'hardcover',
          status: 'reading',
          spineColorHex: spineColors.spineColorHex,
          spineTextHex: spineColors.spineTextHex,
          lastReadPage: 0,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await tester
            .pumpWidget(wrapWithMaterial(ReadingTimerScreen(book: dummyBook)));
        await tester.pumpAndSettle();

        expect(find.byType(ReadingTimerScreen), findsOneWidget);
        expect(find.text('Focus Reading Timer'), findsOneWidget);
        expect(find.text('A Memory of Light'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      });

      testWidgets(
          'StatsScreen renders (empty & populated) at ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);

        // 1. Render empty stats
        await tester.pumpWidget(wrapWithMaterial(const StatsScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(StatsScreen), findsOneWidget);
        expect(find.text('Reading Insights & Stats'), findsOneWidget);
        expect(find.text('0 Days'), findsNWidgets(2));
        await tester.scrollUntilVisible(
          find.text('No books in library yet'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('No books in library yet'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 2. Populate data and test charts
        final now = DateTime.now();
        final nowMs = now.millisecondsSinceEpoch;

        final formats = ['paperback', 'hardcover', 'ebook', 'audiobook'];
        for (int i = 0; i < formats.length; i++) {
          await db.bookDao.insertBook(
            BooksCompanion.insert(
              id: 'stat-book-$i',
              title: 'Book $i',
              authors: '["Author"]',
              format: drift.Value(formats[i]),
              status: i == 0 ? 'finished' : 'reading',
              spineColorHex: 0xFF2C3E50,
              spineTextHex: 0xFFFFFFFF,
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

          await db.sessionDao.insertSession(
            ReadingSessionsCompanion.insert(
              id: 'stat-session-$i',
              bookId: 'stat-book-$i',
              startTime: nowMs - (i * 86400000), // consecutive days
              durationSeconds: 1200 + i * 300,
              startPage: 1,
              endPage: 30 + i * 15,
            ),
          );
        }

        await tester.pumpWidget(wrapWithMaterial(const StatsScreen()));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Format Distribution'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Format Distribution'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      });

      testWidgets(
          'SettingsBackupScreen renders (free & pro) at ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);

        // Free tier
        await tester.pumpWidget(
            wrapWithMaterial(const SettingsBackupScreen(), isPro: false));
        await tester.pumpAndSettle();

        expect(find.text('Settings & Data Backup'), findsOneWidget);
        expect(find.text('ReadSanctuary Free'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Pro tier
        await tester.pumpWidget(
            wrapWithMaterial(const SettingsBackupScreen(), isPro: true));
        await tester.pumpAndSettle();

        expect(find.text('ReadSanctuary Pro Active'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      });

      testWidgets('SpineCropperScreen renders at ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);

        // Initial picker prompt view
        await tester.pumpWidget(
            wrapWithMaterial(const SpineCropperScreen(bookId: 'crop-book')));
        await tester.pumpAndSettle();

        expect(find.byType(SpineCropperScreen), findsOneWidget);
        expect(find.text('Take or choose a photo of the book spine'),
            findsOneWidget);
        expect(tester.takeException(), isNull);

        // Crop view with raw image bytes (100x200 1-pixel transparent PNG mock bytes)
        final dummyBytes = Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]);

        await tester.pumpWidget(wrapWithMaterial(
          SpineCropperScreen(
              bookId: 'crop-book', initialImageBytes: dummyBytes),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Crop & Save'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      });

      testWidgets('OcrQuoteScanner renders at ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(wrapWithMaterial(
          const OcrQuoteScanner(bookId: 'ocr-book', bookTitle: 'Oathbringer'),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(OcrQuoteScanner), findsOneWidget);
        expect(find.text('Scan Quote (OCR)'), findsOneWidget);
        expect(find.text('Take Photo'), findsOneWidget);
        expect(find.text('Pick Image'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      });
    }
  });
}
