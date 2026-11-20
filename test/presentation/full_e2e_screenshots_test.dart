import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:readsanctuary/app.dart';
import 'package:readsanctuary/data/local/database.dart';
import 'package:readsanctuary/data/remote/book_lookup_service.dart';
import 'package:readsanctuary/core/utils/image_storage_helper.dart';
import 'package:readsanctuary/data/remote/free_book_service.dart';
import 'package:readsanctuary/data/services/epub_service.dart';
import 'package:readsanctuary/domain/models/book_metadata.dart';
import 'package:readsanctuary/presentation/providers/filtered_library_provider.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/dialogs/library_filter_bottom_sheet.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/dialogs/prop_selection_sheet.dart';
import 'package:readsanctuary/presentation/screens/bookshelf/widgets/interactive_3d_book_viewer.dart';
import 'package:readsanctuary/presentation/screens/epub_reader/epub_reader_screen.dart';
import 'package:readsanctuary/presentation/screens/settings_backup/dialogs/pro_paywall_sheet.dart';
import 'package:readsanctuary/presentation/screens/settings_backup/widgets/pro_status_banner.dart';
import 'package:readsanctuary/presentation/screens/spine_cropper/spine_cropper_screen.dart';
import 'package:readsanctuary/presentation/screens/timer/dialogs/log_manual_session_dialog.dart';
import 'package:readsanctuary/presentation/screens/timer/reading_timer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

class FakeMobileScannerPlatform extends MobileScannerPlatform {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      currentTorchMode: TorchState.off,
      numberOfCameras: 2,
      size: Size(1920, 1080),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose() async {}
}

class FakeFreeBookService extends Fake implements FreeBookService {
  @override
  Future<List<BookMetadata>> searchFreeBooks(String query, {int limit = 20}) async {
    return [
      const BookMetadata(
        title: 'Frankenstein',
        authors: ['Mary Shelley'],
        pageCount: 280,
        publishYear: '1818',
        description: 'The classic gothic horror novel of Victor Frankenstein and his creature.',
        freePdfUrl: 'https://example.com/frankenstein.pdf',
        source: 'Project Gutenberg',
      ),
    ];
  }
}

class FakeBookLookupService extends Fake implements BookLookupService {
  @override
  Future<List<BookMetadata>> search(String query) async {
    return [
      const BookMetadata(
        title: 'Pride and Prejudice',
        authors: ['Jane Austen'],
        pageCount: 432,
        publishYear: '1813',
        description: 'Romantic novel by Jane Austen set in Georgian England.',
        source: 'OpenLibrary',
      ),
    ];
  }
}

class FakeEpubService extends Fake implements EpubService {
  @override
  Future<EpubBook> parseEpubBytes(List<int> bytes) async {
    return const EpubBook(
      title: 'Dune',
      author: 'Frank Herbert',
      chapters: [
        EpubChapter(
          title: 'Chapter 1: The Desert Planet',
          paragraphs: [
            'A beginning is the time for taking the most delicate care that the balances are correct.',
            'The harsh winds whispered across the great dunes of the deep desert, carrying ancient mystery.',
            'Paul looked toward the twin moons rising above the rocky outcrop, contemplating the journey ahead.'
          ],
          index: 0,
        ),
      ],
    );
  }
}

Future<void> _loadTestFonts() async {
  try {
    const fontDir = r'D:\Dev\Flutter\flutter\bin\cache\artifacts\material_fonts';
    final robotoRegular = File('$fontDir\\roboto-regular.ttf');
    final robotoBold = File('$fontDir\\roboto-bold.ttf');
    final robotoMedium = File('$fontDir\\roboto-medium.ttf');

    final fontLoader = FontLoader('Roboto');
    if (robotoRegular.existsSync()) {
      fontLoader.addFont(robotoRegular.readAsBytes().then((b) => ByteData.sublistView(b)));
    }
    if (robotoBold.existsSync()) {
      fontLoader.addFont(robotoBold.readAsBytes().then((b) => ByteData.sublistView(b)));
    }
    if (robotoMedium.existsSync()) {
      fontLoader.addFont(robotoMedium.readAsBytes().then((b) => ByteData.sublistView(b)));
    }
    await fontLoader.load();

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
      r'C:\Users\sarat\.gemini\antigravity\brain\af49942a-798f-4c7d-94b3-ec9cf8eba882';

  late AppDatabase db;
  late Directory tempDir;
  late ImageStorageHelper storage;

  setUpAll(() async {
    MobileScannerPlatform.instance = FakeMobileScannerPlatform();
    await _loadTestFonts();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    tempDir = await Directory.systemTemp.createTemp('e2e_reader_test_');
    storage = ImageStorageHelper(baseDirProvider: () async => tempDir);
    final f = await storage.getFile('books/dune.epub');
    await f.create(recursive: true);
    await f.writeAsBytes([0x50, 0x4B, 0x03, 0x04]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> saveScreenshot(
    WidgetTester tester,
    GlobalKey repaintKey,
    String relativePath, {
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
      final file = File(p.join('screenshots', relativePath));
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      await file.writeAsBytes(bytes);

      // 2. Save to artifact directory
      final artFile = File(p.join(artifactDirPath, 'screenshots', relativePath));
      if (!artFile.parent.existsSync()) {
        artFile.parent.createSync(recursive: true);
      }
      await artFile.writeAsBytes(bytes);
    });
  }

  testWidgets('Full End-To-End Screenshot Capture across all screens and flows',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    final appKey = GlobalKey();

    // ---------------------------------------------------------
    // 1. BOOT APP & EMPTY BOOKSHELF (01_bookshelf_3d)
    // ---------------------------------------------------------
    await tester.pumpWidget(
      RepaintBoundary(
        key: appKey,
        child: ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            freeBookServiceProvider.overrideWithValue(FakeFreeBookService()),
            bookLookupServiceProvider.overrideWithValue(FakeBookLookupService()),
            imageStorageHelperProvider.overrideWithValue(storage),
            epubServiceProvider.overrideWithValue(FakeEpubService()),
          ],
          child: const ReadSanctuaryApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveScreenshot(tester, appKey, '01_bookshelf_3d/01_empty_shelf.png');

    // ---------------------------------------------------------
    // 2. SEED REALISTIC BOOKS, PROPS, SESSIONS, AND NOTES
    // ---------------------------------------------------------
    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert Book 1: Dune (Currently Reading)
    await db.bookDao.insertBook(
      BooksCompanion.insert(
        id: 'book-dune',
        title: 'Dune',
        authors: jsonEncode(['Frank Herbert']),
        pageCount: const drift.Value(680),
        format: const drift.Value('hardcover'),
        status: 'reading',
        lastReadPage: const drift.Value(245),
        spineColorHex: 0xFF8A5D3B,
        spineTextHex: 0xFFFFFFFF,
        rating: const drift.Value(4.5),
        ratingPlot: const drift.Value(5.0),
        ratingCharacters: const drift.Value(4.5),
        ratingWriting: const drift.Value(4.5),
        ratingPacing: const drift.Value(4.0),
        description: const drift.Value(
            'Set on the desert planet Arrakis, Dune tells the story of Paul Atreides as his family accepts the stewardship of the dangerous planet.'),
        publisher: const drift.Value('Chilton Books'),
        publishYear: const drift.Value('1965'),
        createdAt: now - 86400000 * 5,
        updatedAt: now,
        lastReadAt: drift.Value(now - 3600000),
      ),
    );

    // Insert Book 2: Neuromancer (Finished)
    await db.bookDao.insertBook(
      BooksCompanion.insert(
        id: 'book-neuro',
        title: 'Neuromancer',
        authors: jsonEncode(['William Gibson']),
        pageCount: const drift.Value(271),
        format: const drift.Value('paperback'),
        status: 'finished',
        lastReadPage: const drift.Value(271),
        spineColorHex: 0xFF0D2538,
        spineTextHex: 0xFF50E3C2,
        rating: const drift.Value(4.75),
        description: const drift.Value(
            'Case had been the sharpest data-thief in the business, until he crossed the wrong people.'),
        publisher: const drift.Value('Ace'),
        publishYear: const drift.Value('1984'),
        createdAt: now - 86400000 * 12,
        updatedAt: now,
        lastReadAt: drift.Value(now - 86400000),
      ),
    );

    // Insert Book 3: Project Hail Mary (TBR / Favorites)
    await db.bookDao.insertBook(
      BooksCompanion.insert(
        id: 'book-phm',
        title: 'Project Hail Mary',
        authors: jsonEncode(['Andy Weir']),
        pageCount: const drift.Value(496),
        format: const drift.Value('hardcover'),
        status: 'tbr',
        lastReadPage: const drift.Value(1),
        spineColorHex: 0xFFD4881A,
        spineTextHex: 0xFFFFFFFF,
        rating: const drift.Value(5.0),
        description: const drift.Value(
            'Ryland Grace is the sole survivor on a desperate, chance mission—and if he fails, humanity and the earth itself are doomed.'),
        publisher: const drift.Value('Ballantine Books'),
        publishYear: const drift.Value('2021'),
        createdAt: now - 86400000 * 2,
        updatedAt: now,
      ),
    );

    // Add shelf items to "default-shelf-reading"
    await db.shelfDao.insertShelfItems([
      ShelfItemsCompanion.insert(
        id: 'si-1',
        shelfId: 'default-shelf-reading',
        itemType: 'book',
        bookId: const drift.Value('book-dune'),
        displayMode: const drift.Value('spine'),
        positionIndex: 0,
      ),
      ShelfItemsCompanion.insert(
        id: 'si-2',
        shelfId: 'default-shelf-reading',
        itemType: 'prop',
        propAssetId: const drift.Value('plant_monstera'),
        positionIndex: 1,
      ),
      ShelfItemsCompanion.insert(
        id: 'si-3',
        shelfId: 'default-shelf-reading',
        itemType: 'book',
        bookId: const drift.Value('book-neuro'),
        displayMode: const drift.Value('spine'),
        positionIndex: 2,
      ),
      ShelfItemsCompanion.insert(
        id: 'si-4',
        shelfId: 'default-shelf-reading',
        itemType: 'prop',
        propAssetId: const drift.Value('candle_amber'),
        positionIndex: 3,
      ),
    ]);

    // Add shelf item to "default-shelf-favorites"
    await db.shelfDao.insertShelfItems([
      ShelfItemsCompanion.insert(
        id: 'si-5',
        shelfId: 'default-shelf-favorites',
        itemType: 'book',
        bookId: const drift.Value('book-phm'),
        displayMode: const drift.Value('spine'),
        positionIndex: 0,
      ),
    ]);

    // Add Reading Sessions
    await db.sessionDao.insertSession(
      ReadingSessionsCompanion.insert(
        id: 'sess-1',
        bookId: 'book-dune',
        startTime: now - 3600000 * 2,
        durationSeconds: 1800,
        startPage: 200,
        endPage: 245,
      ),
    );
    await db.sessionDao.insertSession(
      ReadingSessionsCompanion.insert(
        id: 'sess-2',
        bookId: 'book-dune',
        startTime: now - 86400000,
        durationSeconds: 2400,
        startPage: 150,
        endPage: 200,
      ),
    );

    // Add Book Notes
    await db.sessionDao.insertNote(
      BookNotesCompanion.insert(
        id: 'note-1',
        bookId: 'book-dune',
        noteType: 'quote',
        content:
            'I must not fear. Fear is the mind-killer. Fear is the little-death that brings total obliteration.',
        pageNumber: const drift.Value(8),
        createdAt: now - 3600000 * 5,
      ),
    );
    await db.sessionDao.insertNote(
      BookNotesCompanion.insert(
        id: 'note-2',
        bookId: 'book-dune',
        noteType: 'thought',
        content:
            'The ecology of Arrakis and the cultural evolution of the Fremen is masterclass worldbuilding.',
        pageNumber: const drift.Value(142),
        createdAt: now - 3600000 * 3,
      ),
    );

    // Wait for DB reactive updates
    await tester.pumpAndSettle();
    await saveScreenshot(tester, appKey, '01_bookshelf_3d/02_populated_shelves.png');

    // ---------------------------------------------------------
    // 3. REORDER MODE ON BOOKSHELF
    // ---------------------------------------------------------
    final reorderBtn = find.byTooltip('Reorder Books');
    expect(reorderBtn, findsOneWidget);
    await tester.tap(reorderBtn);
    await tester.pumpAndSettle();
    await saveScreenshot(tester, appKey, '01_bookshelf_3d/03_reorder_mode.png');

    // Exit reorder mode
    final doneReorderBtn = find.byTooltip('Done Reordering');
    await tester.tap(doneReorderBtn);
    await tester.pumpAndSettle();

    // ---------------------------------------------------------
    // 4. ADD BOOK DIALOG
    // ---------------------------------------------------------
    final addBookFab = find.widgetWithText(FloatingActionButton, 'Add Book');
    await tester.tap(addBookFab);
    await tester.pumpAndSettle();
    await saveScreenshot(tester, appKey, '01_bookshelf_3d/05_add_book_dialog.png');

    // Dismiss dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Shelf Customization & Props (Wood theme, Wall theme, Props)
    final shelfMoreBtn = find.byIcon(Icons.more_horiz);
    if (shelfMoreBtn.evaluate().isNotEmpty) {
      // Wood Theme Dialog
      await tester.tap(shelfMoreBtn.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Wood Style'));
      await tester.pumpAndSettle();
      await saveScreenshot(
          tester, appKey, '01_bookshelf_3d/06_wood_theme_dialog.png');
      Navigator.of(tester.element(find.byType(SimpleDialog))).pop();
      await tester.pumpAndSettle();

      // Wall Theme Dialog
      await tester.tap(shelfMoreBtn.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Background Theme'));
      await tester.pumpAndSettle();
      await saveScreenshot(
          tester, appKey, '01_bookshelf_3d/07_wall_theme_dialog.png');
      Navigator.of(tester.element(find.byType(SimpleDialog))).pop();
      await tester.pumpAndSettle();

      // Prop Selection Sheet
      await tester.tap(shelfMoreBtn.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Prop / Spacer'));
      await tester.pumpAndSettle();
      await saveScreenshot(
          tester, appKey, '01_bookshelf_3d/08_prop_selection_sheet.png');
      Navigator.of(tester.element(find.byType(PropSelectionSheet))).pop();
      await tester.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // 5. ADD SHELF DIALOG
    // ---------------------------------------------------------
    final appBarMoreBtn = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.more_vert),
    );
    await tester.tap(appBarMoreBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Shelf'));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, appKey, '01_bookshelf_3d/04_add_shelf_dialog.png');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // ---------------------------------------------------------
    // 6. TOGGLE TO 2D MIHON LIBRARY GRID (02_library_grid_and_filter)
    // ---------------------------------------------------------
    final viewToggleBtn = find.byTooltip('View Library Grid');
    expect(viewToggleBtn, findsOneWidget);
    await tester.tap(viewToggleBtn);
    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, appKey, '02_library_grid_and_filter/01_library_grid_view.png');

    // Toggle to List View
    final listViewToggle = find.byTooltip('List View');
    expect(listViewToggle, findsOneWidget);
    await tester.tap(listViewToggle);
    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, appKey, '02_library_grid_and_filter/02_library_list_view.png');

    // Toggle back to Grid View
    final gridViewToggle = find.byTooltip('Grid View');
    await tester.tap(gridViewToggle);
    await tester.pumpAndSettle();

    // Filter Bottom Sheet (Filter Tab)
    final filterBtn = find.byTooltip('Filter & Sort');
    expect(filterBtn, findsOneWidget);
    await tester.tap(filterBtn);
    await tester.pumpAndSettle();

    await saveScreenshot(tester, appKey,
        '02_library_grid_and_filter/04_filter_bottom_sheet_filter_tab.png');

    // Switch to Sort Tab
    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();

    await saveScreenshot(tester, appKey,
        '02_library_grid_and_filter/05_filter_bottom_sheet_sort_tab.png');

    // Close bottom sheet
    Navigator.of(tester.element(find.byType(LibraryFilterBottomSheet))).pop();
    await tester.pumpAndSettle();

    // Live FTS Search
    final searchBtn = find.byTooltip('Search Library');
    expect(searchBtn, findsOneWidget);
    await tester.tap(searchBtn);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).first, 'desert Arrakis');
    await tester.pump();
    final container = ProviderScope.containerOf(
        tester.element(find.byType(TextField).first));
    await container.read(filteredBooksProvider.future);
    await tester.pump();

    await saveScreenshot(
        tester, appKey, '02_library_grid_and_filter/03_fts_live_search.png');

    // Clear search
    final clearSearch = find.byIcon(Icons.clear);
    if (clearSearch.evaluate().isNotEmpty) {
      await tester.tap(clearSearch);
      await tester.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // 7. BOOK DETAIL SCREEN (03_book_detail)
    // ---------------------------------------------------------
    // Tap Dune card to open BookDetailScreen
    await tester.tap(find.text('Dune').first);
    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, appKey, '03_book_detail/01_book_detail_overview.png');

    // Edit Details Dialog
    final editBtn = find.byTooltip('Edit Details');
    if (editBtn.evaluate().isNotEmpty) {
      await tester.tap(editBtn.first);
      await tester.pumpAndSettle();
      await saveScreenshot(
          tester, appKey, '03_book_detail/04_edit_book_dialog.png');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }

    // Scroll down to Notes section
    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();
    await saveScreenshot(
        tester, appKey, '03_book_detail/02_book_detail_notes_tab.png');

    // Scroll down to Reading Sessions section
    await tester.drag(find.byType(ListView).first, const Offset(0, -360));
    await tester.pumpAndSettle();
    await saveScreenshot(
        tester, appKey, '03_book_detail/03_book_detail_sessions_tab.png');

    // Scroll back to top before launching 3D viewer
    await tester.drag(find.byType(ListView).first, const Offset(0, 680));
    await tester.pumpAndSettle();

    // ---------------------------------------------------------
    // 8. INTERACTIVE 3D BOOK VIEWER (04_3d_book_viewer)
    // ---------------------------------------------------------
    final inspectBtn = find.byIcon(Icons.view_in_ar);
    if (inspectBtn.evaluate().isNotEmpty) {
      await tester.tap(inspectBtn.first);
      await tester.pumpAndSettle();

      await saveScreenshot(tester, appKey, '04_3d_book_viewer/01_3d_front_angle.png');

      // Drag to rotate to spine
      await tester.drag(find.byType(Interactive3dBookViewer), const Offset(150, 0));
      await tester.pumpAndSettle();
      await saveScreenshot(tester, appKey, '04_3d_book_viewer/02_3d_spine_view.png');

      // Drag to rotate to back
      await tester.drag(find.byType(Interactive3dBookViewer), const Offset(200, 0));
      await tester.pumpAndSettle();
      await saveScreenshot(tester, appKey, '04_3d_book_viewer/03_3d_back_cover.png');

      // Close 3D viewer
      final close3d = find.byIcon(Icons.close);
      if (close3d.evaluate().isNotEmpty) {
        await tester.tap(close3d.first);
        await tester.pumpAndSettle();
      }
    }

    // Pop BookDetailScreen back to Bookshelf
    final backBtn = find.byType(BackButton);
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn.first);
      await tester.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // 9. MANAGE SHELVES SCREEN (07_manage_shelves)
    // ---------------------------------------------------------
    final appBarMoreForManage = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.more_vert),
    );
    await tester.tap(appBarMoreForManage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage Shelves'));
    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, appKey, '07_manage_shelves/01_manage_shelves_list.png');

    // Tap edit to show rename dialog
    final editShelfBtn = find.byIcon(Icons.edit_outlined).first;
    await tester.tap(editShelfBtn);
    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, appKey, '07_manage_shelves/02_rename_shelf_dialog.png');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Pop ManageShelvesScreen
    final backFromManage = find.byType(BackButton);
    if (backFromManage.evaluate().isNotEmpty) {
      await tester.tap(backFromManage.first);
      await tester.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // 10. BOOK SEARCH & FREE E-BOOKS SCREEN (05_search_and_free_books)
    // ---------------------------------------------------------
    final appBarMoreForSearch = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.more_vert),
    );
    await tester.tap(appBarMoreForSearch);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find Free Books'));
    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, appKey, '05_search_and_free_books/01_search_screen_empty.png');

    // Enter search query and perform search
    await tester.enterText(find.byType(TextField).first, 'Frankenstein');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search'));
    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, appKey, '05_search_and_free_books/02_search_results.png');

    // Pop search screen
    final backFromSearch = find.byType(BackButton);
    if (backFromSearch.evaluate().isNotEmpty) {
      await tester.tap(backFromSearch.first);
      await tester.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // 11. BARCODE SCANNER SCREEN (06_scanner)
    // ---------------------------------------------------------
    final barcodeIcon = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.qr_code_scanner),
    );
    await tester.tap(barcodeIcon);
    await tester.pumpAndSettle();

    await saveScreenshot(tester, appKey, '06_scanner/01_barcode_scanner.png');

    // Pop scanner screen
    final backFromScanner = find.byType(BackButton);
    if (backFromScanner.evaluate().isNotEmpty) {
      await tester.tap(backFromScanner);
      await tester.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // 12. READING TIMER SCREEN (08_reading_timer)
    // ---------------------------------------------------------
    // Push timer directly for book-dune
    final duneBook = await db.bookDao.getBookById('book-dune');
    if (duneBook != null) {
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(
        MaterialPageRoute(
          builder: (_) => ReadingTimerScreen(
            book: duneBook,
            initialStartPage: 245,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(
          tester, appKey, '08_reading_timer/01_reading_timer_active.png');

      // Manual Session Log Dialog
      final timerContext = tester.element(find.byType(ReadingTimerScreen));
      LogManualSessionDialog.show(timerContext, book: duneBook);
      await tester.pumpAndSettle();
      await saveScreenshot(
          tester, appKey, '08_reading_timer/02_log_manual_session_dialog.png');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Pop reading timer to cancel timer cleanly
      nav.pop();
      await tester.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // 13. STATS & ANALYTICS SCREEN (09_stats_screen)
    // ---------------------------------------------------------
    // Switch bottom nav to Stats (index 1)
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle();

    await saveScreenshot(tester, appKey, '09_stats_screen/01_stats_overview.png');

    // ---------------------------------------------------------
    // 14. SETTINGS & DATA BACKUP SCREEN (10_settings_and_backup)
    // ---------------------------------------------------------
    // Switch bottom nav to Settings & Backup (index 2)
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await saveScreenshot(tester, appKey,
        '10_settings_and_backup/01_settings_backup_overview.png');

    // Pro Paywall Sheet (tap ProStatusBanner at top)
    final proBanner = find.byType(ProStatusBanner);
    if (proBanner.evaluate().isNotEmpty) {
      await tester.tap(proBanner);
      await tester.pumpAndSettle();
      await saveScreenshot(tester, appKey,
          '10_settings_and_backup/02_pro_paywall_sheet.png');
      Navigator.of(tester.element(find.byType(ProPaywallSheet))).pop();
      await tester.pumpAndSettle();
    }

    // Gift Redeem Dialog
    final giftTile = find.text('Redeem Gift Code / Voucher');
    if (giftTile.evaluate().isNotEmpty) {
      await tester.tap(giftTile);
      await tester.pumpAndSettle();
      await saveScreenshot(tester, appKey,
          '10_settings_and_backup/03_gift_redeem_dialog.png');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // 15. SPINE CROPPER SCREEN (11_spine_cropper)
    // ---------------------------------------------------------
    final navRoot = tester.state<NavigatorState>(find.byType(Navigator));
    navRoot.push(
      MaterialPageRoute(
        builder: (_) => const SpineCropperScreen(bookId: 'book-dune'),
      ),
    );
    await tester.pumpAndSettle();
    await saveScreenshot(
        tester, appKey, '11_spine_cropper/01_spine_cropper_screen.png');
    navRoot.pop();
    await tester.pumpAndSettle();

    // ---------------------------------------------------------
    // 16. EPUB READER SCREEN (12_reader)
    // ---------------------------------------------------------
    if (duneBook != null) {
      navRoot.push(
        MaterialPageRoute(
          builder: (_) => EpubReaderScreen(
            book: duneBook.copyWith(
              format: 'ebook',
              lastReadPage: 1,
              pdfPath: const drift.Value('books/dune.epub'),
            ),
          ),
        ),
      );
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await saveScreenshot(
          tester, appKey, '12_reader/01_epub_reader_screen.png');
      navRoot.pop();
      await tester.pumpAndSettle();
    }

    // Unmount widget tree and close DB so all reactive stream timers are drained
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await db.close();
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
}
