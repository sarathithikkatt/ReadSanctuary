import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/book_spine_25d_widget.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/shelf_prop_widget.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/wooden_shelf_row.dart';

void main() {
  testWidgets(
      'Capture screenshots of decorator selection, active drag, and anywhere placement',
      (WidgetTester tester) async {
    const artifactDir =
        r'C:\Users\sarat\.gemini\antigravity\brain\dc33b318-095d-45be-8742-6d171faad2af';

    tester.view.physicalSize = const Size(900, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repaintKey = GlobalKey();

    List<Widget> shelfItems = [
      const BookSpine25DWidget(
        key: ValueKey('b1'),
        id: 'b1',
        title: 'The Hobbit',
        pageCount: 310,
        spineColorHex: 0xFF2E7D32,
        spineTextHex: 0xFFFFFFFF,
      ),
      const BookSpine25DWidget(
        key: ValueKey('b2'),
        id: 'b2',
        title: 'Dune',
        pageCount: 680,
        spineColorHex: 0xFFD84315,
        spineTextHex: 0xFFFFFFFF,
      ),
      const ShelfPropWidget(
        key: ValueKey('prop_cat'),
        propAssetId: 'cat_sleeping',
      ),
      const BookSpine25DWidget(
        key: ValueKey('b3'),
        id: 'b3',
        title: 'Neuromancer',
        pageCount: 271,
        spineColorHex: 0xFF1565C0,
        spineTextHex: 0xFFFFFFFF,
      ),
      const ShelfPropWidget(
        key: ValueKey('prop_plant'),
        propAssetId: 'plant_monstera',
      ),
    ];

    late StateSetter updateState;

    await tester.pumpWidget(
      RepaintBoundary(
        key: repaintKey,
        child: MaterialApp(
          theme: ThemeData(
            cardColor: Colors.white,
          ),
          home: Scaffold(
            backgroundColor: const Color(0xFFF7F2EC),
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateState = setState;
                  return WoodenShelfRow(
                    shelfId: 'demo-shelf',
                    shelfName: 'Living Room Bookshelf',
                    woodThemeId: 'walnut',
                    wallThemeId: 'warm_cream',
                    isReorderable: true,
                    onReorder: (oldIdx, newIdx) {
                      updateState(() {
                        if (oldIdx < newIdx) newIdx -= 1;
                        final moved = shelfItems.removeAt(oldIdx);
                        shelfItems.insert(newIdx, moved);
                      });
                    },
                    items: List.of(shelfItems),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Ensure assets are loaded
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    Future<void> saveScreenshot(String filename) async {
      await tester.runAsync(() async {
        final boundary =
            repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        final file = File('$artifactDir\\$filename');
        await file.writeAsBytes(bytes);
        await File('D:\\Dev\\ShelfCraft\\$filename').writeAsBytes(bytes);
      });
    }

    // 1. Initial State: Cat is between Dune (b2) and Neuromancer (b3)
    await saveScreenshot('screenshot_1_shelf_initial.png');

    // 2. Select the Sleeping Cat decorator and start dragging
    final catFinder = find.byKey(const ValueKey('prop_cat'));
    final b1Finder = find.byKey(const ValueKey('b1'));
    final catCenter = tester.getCenter(catFinder);
    final b1Left = tester.getTopLeft(b1Finder);

    final gesture = await tester.startGesture(catCenter);
    await tester.pump(const Duration(milliseconds: 600)); // enters long-press drag mode

    // Move cat slightly to the left over Dune
    await gesture.moveTo(Offset(catCenter.dx - 40, catCenter.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 2. Capture active drag state (verifying floating transparent decorator without white column)
    await saveScreenshot('screenshot_2_decorator_active_drag.png');

    // 3. Drag cat to before the first book (index 0) and drop
    await gesture.moveTo(Offset(b1Left.dx - 10, catCenter.dy));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // 3. Capture state after dropping cat at index 0 (beginning of shelf)
    await saveScreenshot('screenshot_3_decorator_kept_at_start.png');

    // 4. Now drag Monstera plant towards the middle of the shelf between Dune and Neuromancer
    final plantFinder = find.byKey(const ValueKey('prop_plant'));
    final b2Finder = find.byKey(const ValueKey('b2'));
    final plantCenter = tester.getCenter(plantFinder);
    final b2Center = tester.getCenter(b2Finder);

    final plantGesture = await tester.startGesture(plantCenter);
    await tester.pump(const Duration(milliseconds: 600));

    // Drag plant between Dune and Neuromancer
    await plantGesture.moveTo(Offset(b2Center.dx + 40, plantCenter.dy));
    await tester.pump();
    await plantGesture.up();
    await tester.pumpAndSettle();

    // 4. Capture state after keeping plant anywhere in between
    await saveScreenshot('screenshot_4_decorator_kept_anywhere.png');
  });
}
