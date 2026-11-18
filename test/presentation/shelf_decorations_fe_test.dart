import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readsanctuary/core/constants/shelf_props.dart';
import 'package:readsanctuary/core/theme/shelf_themes.dart';
import 'package:readsanctuary/core/utils/image_storage_helper.dart';
import 'package:readsanctuary/data/local/database.dart';
import 'package:readsanctuary/data/services/custom_props_service.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/dialogs/prop_selection_sheet.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/widgets/shelf_prop_widget.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/widgets/shelf_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late ImageStorageHelper storageHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('fe_test_');
    storageHelper = ImageStorageHelper(
      baseDirProvider: () async => tempDir,
    );
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Shelf Props & Themes FE Checkup', () {
    testWidgets('ShelfPropWidget renders spacer gap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelfPropWidget(propAssetId: 'gap', customWidth: 32.0),
          ),
        ),
      );

      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.width, equals(32.0));
    });

    testWidgets('ShelfPropWidget renders new vector props with semantic labels',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ShelfPropWidget(propAssetId: 'reading_glasses'),
                ShelfPropWidget(propAssetId: 'globe_antique'),
                ShelfPropWidget(propAssetId: 'quill_inkpot'),
                ShelfPropWidget(propAssetId: 'crystal_prism'),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
      expect(find.byIcon(Icons.history_edu), findsOneWidget);
      expect(find.byIcon(Icons.diamond_outlined), findsOneWidget);
    });

    testWidgets('PropSelectionSheet shows Create Custom Prop banner and catalog',
        (tester) async {
      // Insert a shelf in db
      await db.shelfDao.insertShelf(
        ShelvesCompanion.insert(
          id: 's1',
          name: 'Fantasy Shelf',
          sortOrder: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PropSelectionSheet(
                shelfId: 's1',
                shelfDao: db.shelfDao,
                isProUser: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify "Create Custom Prop" banner is present
      expect(find.text('Create Custom Prop'), findsOneWidget);
      expect(find.text('FREE'), findsWidgets);

      // Verify built-in decor items are visible
      expect(find.text('Potted Succulent'), findsNothing); // Title is "Succulent Plant"
      expect(find.text('Succulent Plant'), findsOneWidget);
      expect(find.text('Vintage Brass Bookend'), findsOneWidget);
      expect(find.text('Vintage Reading Glasses'), findsOneWidget);
    });

    testWidgets('ShelfSection displays prop and permits removal via options sheet',
        (tester) async {
      // 1. Create a shelf
      await db.shelfDao.insertShelf(
        ShelvesCompanion.insert(
          id: 'shelf_fe_1',
          name: 'Cozy Reading Nook',
          sortOrder: 0,
        ),
      );

      // 2. Insert a decorative plant prop on the shelf
      await db.shelfDao.insertShelfItem(
        ShelfItemsCompanion.insert(
          id: 'item_plant_1',
          shelfId: 'shelf_fe_1',
          itemType: 'prop',
          propAssetId: const drift.Value('plant_monstera'),
          positionIndex: 0,
        ),
      );

      final shelf = (await db.shelfDao.getAllShelves())
          .firstWhere((s) => s.id == 'shelf_fe_1');
      final checkItems = await db.shelfDao.getItemsWithBooksForShelf(shelf.id);
      expect(checkItems.length, equals(1));
      expect(checkItems.first.item.propAssetId, equals('plant_monstera'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ShelfSection(
                shelf: shelf,
                shelfDao: db.shelfDao,
                bookDao: db.bookDao,
                isReorderable: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify prop is rendered on the shelf
      expect(find.byType(ShelfPropWidget), findsOneWidget);

      // Tap the prop on the shelf to open removal options
      await tester.tap(find.byType(ShelfPropWidget).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify bottom sheet appears with "Remove from Shelf"
      expect(find.text('Remove from Shelf'), findsOneWidget);

      // Tap "Remove from Shelf"
      await tester.tap(find.text('Remove from Shelf'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Allow Drift delete operation to execute
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // Verify item was deleted from database
      final itemsAfter = await db.shelfDao.getItemsForShelf('shelf_fe_1');
      expect(itemsAfter.isEmpty, isTrue);

      // Verify ShelfPropWidget is no longer in the shelf tree
      expect(find.byType(ShelfPropWidget), findsNothing);

      // Unmount the widget tree to allow Drift stream query cancellation
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
