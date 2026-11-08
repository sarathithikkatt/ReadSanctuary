import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readsanctuary/data/local/database.dart';
import 'package:readsanctuary/data/services/shelf_widget_service.dart';
import 'package:readsanctuary/presentation/widgets/home_widget/shelf_home_widget_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShelfHomeWidgetView Widget Tests', () {
    testWidgets('renders empty state correctly with title and ReadSanctuary branding',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShelfHomeWidgetView(
                shelfName: 'Currently Reading',
                items: [],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Currently Reading'), findsOneWidget);
      expect(find.text('ReadSanctuary'), findsOneWidget);
      expect(find.text('Empty shelf • Tap to add books'), findsOneWidget);
    });

    testWidgets('renders shelf with books and props without overflow',
        (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final book1 = Book(
        id: 'book-1',
        title: 'Project Hail Mary',
        authors: '["Andy Weir"]',
        pageCount: 496,
        format: 'hardcover',
        status: 'reading',
        spineColorHex: 0xFF2C3E50,
        spineTextHex: 0xFFFFFFFF,
        lastReadPage: 1,
        createdAt: now,
        updatedAt: now,
      );

      final book2 = Book(
        id: 'book-2',
        title: 'Dune',
        authors: '["Frank Herbert"]',
        pageCount: 688,
        format: 'paperback',
        status: 'reading',
        spineColorHex: 0xFFD35400,
        spineTextHex: 0xFFFFFFFF,
        lastReadPage: 1,
        createdAt: now,
        updatedAt: now,
      );

      final items = [
        ShelfItemWithBook(
          item: const ShelfItem(
            id: 'item-1',
            shelfId: 'shelf-1',
            itemType: 'book',
            bookId: 'book-1',
            displayMode: 'spine',
            positionIndex: 0,
          ),
          book: book1,
        ),
        const ShelfItemWithBook(
          item: ShelfItem(
            id: 'item-2',
            shelfId: 'shelf-1',
            itemType: 'prop',
            propAssetId: 'plant_monstera',
            displayMode: 'spine',
            positionIndex: 1,
          ),
        ),
        ShelfItemWithBook(
          item: const ShelfItem(
            id: 'item-3',
            shelfId: 'shelf-1',
            itemType: 'book',
            bookId: 'book-2',
            displayMode: 'spine',
            positionIndex: 2,
          ),
          book: book2,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShelfHomeWidgetView(
                shelfName: 'Sci-Fi Shelf',
                items: items,
                woodThemeId: 'walnut',
                wallThemeId: 'library_brick',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sci-Fi Shelf'), findsOneWidget);
      expect(find.text('(2)'), findsOneWidget);
      expect(find.text('ReadSanctuary'), findsOneWidget);
      expect(find.text('Project Hail Mary'), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Empty shelf • Tap to add books'), findsNothing);
    });

    test('ShelfWidgetService preferences get and set', () async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase();
      final service = ShelfWidgetService(shelfDao: db.shelfDao);

      expect(await service.getSelectedShelfId(), isNull);

      await service.setSelectedShelfId('shelf-42');
      expect(await service.getSelectedShelfId(), 'shelf-42');

      await db.close();
    });
  });
}
