import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/book_spine_25d_widget.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/shelf_prop_widget.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/wooden_shelf_row.dart';

void main() {
  group('Verification Gate 3 - 2.5D Bookshelf & Spine Scaling Widget Tests', () {
    testWidgets(
      'Pumps WoodenShelfRow with 15 books of varying page counts and formats without layout overflow',
      (WidgetTester tester) async {
        // Prepare 15 books with varied formats and page counts (80 to 1200)
        final testSpecs = [
          (pages: 80, format: 'paperback', title: 'Novella A'),
          (pages: 150, format: 'paperback', title: 'Short Novel B'),
          (pages: 250, format: 'paperback', title: 'Novel C'),
          (pages: 350, format: 'paperback', title: 'Novel D'),
          (pages: 420, format: 'hardcover', title: 'Hardcover E'),
          (pages: 500, format: 'hardcover', title: 'Epic F'),
          (pages: 630, format: 'hardcover', title: 'Tome G'),
          (pages: 700, format: 'hardcover', title: 'Grimoire H'),
          (pages: 850, format: 'hardcover', title: 'Archive I'),
          (pages: 1000, format: 'hardcover', title: 'Omnibus J'),
          (pages: 1200, format: 'hardcover', title: 'Monolith K'),
          (pages: 100, format: 'ebook', title: 'Digital L'),
          (pages: 300, format: 'ebook', title: 'Digital M'),
          (pages: 450, format: 'ebook', title: 'Digital N'),
          (pages: 600, format: 'audiobook', title: 'Audio O'),
        ];

        final bookWidgets = <Widget>[
          for (int i = 0; i < testSpecs.length; i++)
            BookSpine25DWidget(
              key: ValueKey('book-$i'),
              id: 'book-$i',
              title: testSpecs[i].title,
              authors: ['Author ${i + 1}'],
              pageCount: testSpecs[i].pages,
              format: testSpecs[i].format,
              spineColorHex: 0xFF2C3E50 + (i * 100),
              spineTextHex: 0xFFFFFFFF,
            ),
        ];

        // Pump inside a standard mobile screen viewport (width: 390, height: 844)
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WoodenShelfRow(
                shelfId: 'test-shelf-1',
                shelfName: 'Master Bedroom Shelf',
                woodThemeId: 'oak',
                items: bookWidgets,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify zero layout overflow exceptions
        expect(tester.takeException(), isNull);

        // 2. Verify accurate width scaling formula: (pages.clamp(80, 1200) / 14.0).clamp(26.0, 62.0)
        // Book 0: 80 pages -> 80/14 = 5.71 clamped to 26.0
        final book0Finder = find.byKey(const ValueKey('book-0'));
        expect(book0Finder, findsOneWidget);
        final book0Size = tester.getSize(book0Finder);
        expect(book0Size.width, 26.0);
        expect(book0Size.height, 170.0); // paperback height

        // Book 4: 420 pages -> 420/14 = 30.0
        final book4Finder = find.byKey(const ValueKey('book-4'));
        expect(book4Finder, findsOneWidget);
        final book4Size = tester.getSize(book4Finder);
        expect(book4Size.width, 30.0);
        expect(book4Size.height, 185.0); // hardcover height

        // Book 7: 700 pages -> 700/14 = 50.0
        final book7Finder = find.byKey(const ValueKey('book-7'));
        expect(book7Finder, findsOneWidget);
        final book7Size = tester.getSize(book7Finder);
        expect(book7Size.width, 50.0);
        expect(book7Size.height, 185.0); // hardcover height

        // Book 10: 1200 pages -> 1200/14 = 85.71 clamped to 62.0
        final book10Finder = find.byKey(const ValueKey('book-10'));
        expect(book10Finder, findsOneWidget);
        final book10Size = tester.getSize(book10Finder);
        expect(book10Size.width, 62.0);
        expect(book10Size.height, 185.0); // hardcover height

        // Book 11: ebook format height -> 160.0
        final book11Finder = find.byKey(const ValueKey('book-11'));
        expect(book11Finder, findsOneWidget);
        final book11Size = tester.getSize(book11Finder);
        expect(book11Size.height, 160.0);
      },
    );

    testWidgets('Renders shelf props and spacer gaps seamlessly on shelf', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WoodenShelfRow(
              shelfId: 'prop-shelf',
              shelfName: 'Aesthetic Shelf',
              woodThemeId: 'walnut',
              items: [
                ShelfPropWidget(key: ValueKey('prop-bookend'), propAssetId: 'bookend_brass'),
                BookSpine25DWidget(
                  key: ValueKey('prop-book'),
                  id: 'b1',
                  title: 'Quiet Book',
                  pageCount: 300,
                ),
                ShelfPropWidget(key: ValueKey('prop-plant'), propAssetId: 'plant_monstera'),
                ShelfPropWidget(key: ValueKey('prop-candle'), propAssetId: 'candle_amber'),
                ShelfPropWidget(key: ValueKey('prop-gap'), propAssetId: 'gap'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('prop-bookend')), findsOneWidget);
      expect(find.byKey(const ValueKey('prop-book')), findsOneWidget);
      expect(find.byKey(const ValueKey('prop-plant')), findsOneWidget);
      expect(find.byKey(const ValueKey('prop-candle')), findsOneWidget);
      expect(find.byKey(const ValueKey('prop-gap')), findsOneWidget);
    });

    testWidgets('Supports horizontal reordering mode on WoodenShelfRow', (WidgetTester tester) async {
      bool reordered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WoodenShelfRow(
              shelfId: 'reorder-shelf',
              shelfName: 'Reorderable Shelf',
              isReorderable: true,
              onReorder: (oldIdx, newIdx) {
                reordered = true;
              },
              items: const [
                BookSpine25DWidget(key: ValueKey('b1'), id: 'b1', title: 'First', pageCount: 200),
                BookSpine25DWidget(key: ValueKey('b2'), id: 'b2', title: 'Second', pageCount: 300),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(reordered, isFalse);
    });
  });
}
