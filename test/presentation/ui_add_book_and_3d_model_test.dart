import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readsanctuary/app.dart';
import 'package:readsanctuary/data/local/database.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/widgets/book_spine_25d_widget.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/widgets/interactive_3d_book_viewer.dart';

Future<void> _loadTestFonts() async {
  try {
    const fontDir = r'D:\Dev\Flutter\flutter\bin\cache\artifacts\material_fonts';
    final robotoFile = File('$fontDir\\roboto-regular.ttf');
    if (robotoFile.existsSync()) {
      final fontLoader = FontLoader('Roboto');
      fontLoader.addFont(robotoFile.readAsBytes().then((b) => ByteData.sublistView(b)));
      await fontLoader.load();
    }

    final iconsFile = File('$fontDir\\materialicons-regular.otf');
    if (iconsFile.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons');
      iconLoader.addFont(iconsFile.readAsBytes().then((b) => ByteData.sublistView(b)));
      await iconLoader.load();
    }
  } catch (e) {
    debugPrint('Font load error: $e');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String artifactDirPath =
      r'C:\Users\sarat\.gemini\antigravity\brain\55dea127-cb50-40ad-b84e-39009e2f7fdd';

  late AppDatabase db;

  setUpAll(() async {
    await _loadTestFonts();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> saveScreenshot(
    WidgetTester tester,
    GlobalKey repaintKey,
    String filename, {
    double pixelRatio = 2.0,
  }) async {
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      // 1. Save to workspace directory
      final localFile = File(filename);
      await localFile.writeAsBytes(bytes);

      // 2. Save to antigravity brain artifact directory
      final artDir = Directory(artifactDirPath);
      if (!artDir.existsSync()) {
        artDir.createSync(recursive: true);
      }
      final artFile = File('${artDir.path}${Platform.pathSeparator}$filename');
      await artFile.writeAsBytes(bytes);
    });
  }

  group('UI Testing: Add Book and 3D Model Formation', () {
    testWidgets('Complete UI flow: Add book via dialog, view on shelf, open detail and 3D inspect',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final appKey = GlobalKey();

      // 1. Pump App
      await tester.pumpWidget(
        RepaintBoundary(
          key: appKey,
          child: ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
            ],
            child: const ReadSanctuaryApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app loaded with default shelves
      expect(find.text('Currently Reading'), findsOneWidget);
      expect(find.text('Favorites & TBR'), findsOneWidget);
      await saveScreenshot(tester, appKey, 'screenshot_ui_1_bookshelf_empty.png');

      // 2. Tap FloatingActionButton to Add Book
      final addBookFab = find.widgetWithText(FloatingActionButton, 'Add Book');
      expect(addBookFab, findsOneWidget);
      await tester.tap(addBookFab);
      await tester.pumpAndSettle();

      expect(find.text('Add Book to Shelf'), findsOneWidget);
      await saveScreenshot(tester, appKey, 'screenshot_ui_2_add_book_dialog.png');

      // 3. Fill in book details: "Dune" by Frank Herbert (680 pages, Hardcover)
      await tester.enterText(
          find.widgetWithText(TextField, 'Book Title *'), 'Dune');
      await tester.enterText(
          find.widgetWithText(TextField, 'Author *'), 'Frank Herbert');
      await tester.enterText(
          find.widgetWithText(TextField, 'Page Count'), '680');
      await tester.enterText(
          find.widgetWithText(TextField, 'Series (optional)'),
          'Dune Chronicles');
      await tester.enterText(
          find.widgetWithText(TextField, 'Vol # (e.g. 1.5)'), '1.0');

      await tester.pump();
      await saveScreenshot(tester, appKey, 'screenshot_ui_3_add_book_filled.png');

      // 4. Submit Add Book Form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Book'));
      await tester.pumpAndSettle();

      // Verify Book was inserted into Database and placed on shelf
      final allBooks = await db.bookDao.getAllBooks();
      expect(allBooks.length, 1);
      final duneBook = allBooks.first;
      expect(duneBook.title, 'Dune');
      expect(duneBook.pageCount, 680);

      // Verify book spine rendered on the wooden shelf
      expect(find.byType(BookSpine25DWidget), findsOneWidget);
      expect(find.text('Dune'), findsWidgets);
      await saveScreenshot(tester, appKey, 'screenshot_ui_4_bookshelf_with_new_book.png');

      // 5. Tap the book spine to navigate to BookDetailScreen
      await tester.tap(find.byType(BookSpine25DWidget).first);
      await tester.pumpAndSettle();

      expect(find.text('Dune Chronicles #1.0'), findsOneWidget);
      expect(find.text('Read Timer'), findsOneWidget);
      await saveScreenshot(tester, appKey, 'screenshot_ui_5_book_detail_screen.png');

      // 6. Tap the book cover preview to trigger Interactive 3D Model Viewer
      // GestureDetector in BookDetailHeader triggers Interactive3dBookViewer.show(context, book: book)
      await tester.tap(find.text('3D').first);
      await tester.pumpAndSettle();

      // Verify 3D Book Viewer is open
      expect(find.text('Dune'), findsWidgets);
      expect(find.textContaining('680 pages'), findsOneWidget);
      expect(find.text('3D View'), findsOneWidget);
      expect(find.text('Spine'), findsOneWidget);
      expect(find.text('Page Edges'), findsOneWidget);
      expect(find.text('Back Cover'), findsOneWidget);
      expect(find.text('Front Cover'), findsOneWidget);

      await saveScreenshot(tester, appKey, 'screenshot_ui_6_3d_model_isometric_formed.png');

      // 7. Test rotation preset chip: 'Spine'
      final spineChip = find.text('Spine');
      await tester.ensureVisible(spineChip);
      await tester.tap(spineChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      await saveScreenshot(tester, appKey, 'screenshot_ui_7_3d_model_spine_face.png');

      // 8. Test rotation preset chip: 'Page Edges'
      final pageEdgesChip = find.text('Page Edges');
      await tester.ensureVisible(pageEdgesChip);
      await tester.tap(pageEdgesChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      await saveScreenshot(tester, appKey, 'screenshot_ui_8_3d_model_page_edges.png');

      // 9. Test rotation preset chip: 'Back Cover'
      final backCoverChip = find.text('Back Cover');
      await tester.ensureVisible(backCoverChip);
      await tester.tap(backCoverChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      await saveScreenshot(tester, appKey, 'screenshot_ui_9_3d_model_back_cover.png');

      // 10. Test rotation preset chip: 'Front Cover'
      final frontCoverChip = find.text('Front Cover');
      await tester.ensureVisible(frontCoverChip);
      await tester.tap(frontCoverChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      await saveScreenshot(tester, appKey, 'screenshot_ui_10_3d_model_front_cover.png');

      // 11. Test Auto-Orbit turntable mode
      final autoOrbitBtn = find.text('Auto Orbit');
      expect(autoOrbitBtn, findsOneWidget);
      await tester.tap(autoOrbitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await saveScreenshot(tester, appKey, 'screenshot_ui_11_3d_model_auto_orbit.png');

      // Stop Auto Orbit before finishing
      await tester.tap(find.text('Pause'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Close 3D Viewer dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Clean up widget tree
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('High-Fidelity 3D Model Formation & Reading Ribbon Analysis',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 850));
      final viewerKey = GlobalKey();

      const duneWithProgress = Book(
        id: 'book-dune-3d-model',
        title: 'Dune',
        authors: '["Frank Herbert"]',
        pageCount: 680,
        format: 'hardcover',
        status: 'reading',
        spineColorHex: 0xFFD84315, // Deep rust orange
        spineTextHex: 0xFFFFFFFF,
        createdAt: 1700000000,
        updatedAt: 1700000000,
        lastReadPage: 340, // 50% reading progress -> triggers crimson silk ribbon!
        seriesName: 'Dune Chronicles',
        seriesIndex: 1.0,
      );

      await tester.pumpWidget(
        RepaintBoundary(
          key: viewerKey,
          child: ProviderScope(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                fontFamily: 'Roboto',
                useMaterial3: true,
              ),
              home: const Interactive3dBookViewer(book: duneWithProgress),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default Isometric formation with Silk Reading Ribbon visible hanging from bottom edge
      await saveScreenshot(
        tester,
        viewerKey,
        'screenshot_ui_12_3d_model_with_silk_ribbon.png',
        pixelRatio: 2.5,
      );

      // Tilt view downwards to inspect top paper edges and thickness
      await tester.drag(
        find.byType(Interactive3dBookViewer),
        const Offset(30.0, 80.0),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await saveScreenshot(
        tester,
        viewerKey,
        'screenshot_ui_13_3d_model_top_tilt_formation.png',
        pixelRatio: 2.5,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
