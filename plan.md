## Agent Operating Instructions
You are building **ShelfCraft**, a local-first 2.5D visual book tracker in Flutter based on `requirement.md`.
- **Rule 1:** Execute one Phase at a time. Do not proceed to the next Phase until all Verification Gates (`flutter analyze` and `flutter test`) for the current Phase pass with 0 errors.
- **Rule 2:** Maintain strict Clean Architecture (`data`, `domain`, `presentation`, `core`).
- **Rule 3:** Never use absolute file paths in the SQLite database for images; always store filenames relative to `getApplicationDocumentsDirectory()/media/` so backups remain portable across devices and OS updates.
- **Rule 4:** Only use MIT, BSD, or Apache-2.0 licensed packages.

---

## Target Directory Structure
```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   │   ├── color_extractor.dart
│   │   └── image_storage_helper.dart
│   └── errors/
├── data/
│   ├── local/
│   │   ├── database.dart          # Drift database definition
│   │   ├── tables/                # books, shelves, shelf_items, sessions, notes
│   │   └── daos/
│   ├── remote/
│   │   ├── open_library_api.dart  # Primary book lookup
│   │   ├── google_books_api.dart  # Fallback lookup (Apache 2.0 pattern)
│   │   └── book_lookup_service.dart
│   ├── services/
│   │   ├── csv_import_service.dart
│   │   ├── google_drive_backup_service.dart
│   │   └── revenuecat_service.dart
│   └── repositories/
├── domain/
│   ├── models/
│   └── repositories/
└── presentation/
    ├── providers/
    ├── screens/
    │   ├── bookshelf/
    │   │   ├── bookshelf_screen.dart
    │   │   └── widgets/
    │   │       ├── wooden_shelf_row.dart
    │   │       ├── book_spine_25d_widget.dart
    │   │       ├── book_cover_tilt_widget.dart
    │   │       └── shelf_prop_widget.dart
    │   ├── scanner/
    │   ├── book_detail/
    │   ├── spine_cropper/
    │   ├── timer/
    │   ├── stats/
    │   └── settings_backup/
    └── widgets/


Phase 1: Project Scaffolding & Drift Local Database
Tasks
[ ] 1.1: Initialize Flutter project (flutter create --org com.shelfcraft shelfcraft) and configure pubspec.yaml with:

State & DI: flutter_riverpod, riverpod_annotation

Database: drift, sqlite3_flutter_libs, path_provider, path

Networking: dio

Visuals & Media: palette_generator, cached_network_image, crop_your_image, fl_chart

Hardware/ML: mobile_scanner, google_mlkit_text_recognition, image_picker

Cloud & Sync: google_sign_in, googleapis, extension_google_sign_in_as_googleapis_auth, archive

Utilities: uuid, csv, intl, share_plus

Dev Dependencies: drift_dev, build_runner, riverpod_generator, flutter_test

[ ] 1.2: Create Drift table definitions in lib/data/local/tables/ matching Section 4 of requirement.md (Books, Shelves, ShelfItems, ReadingSessions, BookNotes). Ensure seriesIndex and rating use RealColumn.

[ ] 1.3: Implement AppDatabase in lib/data/local/database.dart and write DAOs (BookDao, ShelfDao, SessionDao) supporting reactive Stream queries and transactional inserts.

[ ] 1.4: Create ImageStorageHelper in lib/core/utils/image_storage_helper.dart to download or copy images into <AppDocs>/media/covers/ and <AppDocs>/media/spines/ and return only the relative filename.

Verification Gate 1
Run dart run build_runner build --delete-conflicting-outputs.

Write unit tests in test/data/database_test.dart using NativeDatabase.memory() to verify CRUD operations, fractional seriesIndex sorting (0.5, 1.0, 1.5, 2.0), and foreign key cascades.

Run flutter test test/data/database_test.dart.

Phase 2: Dual-API Book Lookup, Palette Extraction & CSV Import
Tasks
[ ] 2.1: Implement OpenLibraryApi (lib/data/remote/open_library_api.dart):

Query by ISBN (https://openlibrary.org/isbn/{isbn}.json) and Search (https://openlibrary.org/search.json).

Extract title, author names, number_of_pages_median (or edition pages), and cover URL (https://covers.openlibrary.org/b/id/{cover_id}-L.jpg).

[ ] 2.2: Implement GoogleBooksApi (lib/data/remote/google_books_api.dart):

Query https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn} or q={query}.

Parse volumeInfo.title, authors, pageCount, imageLinks.thumbnail.

[ ] 2.3: Implement BookLookupService (lib/data/remote/book_lookup_service.dart):

Query OpenLibraryApi first. If pageCount == null or coverUrl == null, automatically enrich missing fields from GoogleBooksApi.

[ ] 2.4: Implement ColorExtractor (lib/core/utils/color_extractor.dart):

Given an ImageProvider, use PaletteGenerator.fromImageProvider to extract dominantColor (or vibrantColor) for the spine background and compute luminance (computeLuminance() > 0.5 ? Colors.black87 : Colors.white) for spineTextHex.

[ ] 2.5: Implement CsvImportService (lib/data/services/csv_import_service.dart):

Clean-room implementation supporting Goodreads CSV (Book Id, Title, Author, ISBN13, My Rating, Number of Pages, Exclusive Shelf, Date Read) and StoryGraph CSV.

Sanitize Goodreads' ="978..." Excel-escaped ISBN strings using regex.

Verification Gate 2
Write unit tests in test/data/csv_import_test.dart testing Goodreads CSV rows with escaped quotes, ="9780140283297" ISBN formatting, and missing page counts.

Write unit tests in test/data/book_lookup_test.dart with mocked Dio responses verifying the OpenLibrary -> Google Books fallback merger.

Run flutter test.

Phase 3: The 2.5D Virtual Bookshelf Engine & Spine Cropper
Tasks
[ ] 3.1: Build WoodenShelfRow (lib/presentation/screens/bookshelf/widgets/wooden_shelf_row.dart):

Render the wall backdrop, a top surface perspective trapezoid (CustomPainter), a front wooden fascia with bevel highlights, and a soft bottom drop shadow.

[ ] 3.2: Build BookSpine25DWidget (lib/presentation/screens/bookshelf/widgets/book_spine_25d_widget.dart):

Width formula: pages.clamp(80, 1200) / 14.0 clamped between 26.0 and 62.0 logical pixels.

Height formula based on format (hardcover: 185dp, paperback: 170dp, ebook: 160dp).

If customSpinePath != null, render the cropped image file with a subtle 3D cylindrical shadow gradient overlay:stops: [0.0, 0.08, 0.22, 0.88, 1.0] with Colors.black38, Colors.white24, Colors.transparent, Colors.black12, Colors.black45.

If customSpinePath == null, render procedural spine with spineColorHex, top/bottom decorative foil bands, and vertical RotatedBox(quarterTurns: 1) typography for Title and Author.

Wrap each book widget in a RepaintBoundary.

[ ] 3.3: Support drag-and-drop reordering (ReorderableListView.builder horizontal) of ShelfItem entities (books, decorative props like plants/candles, and custom spacer gaps).

[ ] 3.4: Build SpineCropperScreen (lib/presentation/screens/spine_cropper/spine_cropper_screen.dart):

Allow user to pick/take a photo and crop a tall narrow aspect ratio rectangle using crop_your_image, saving the result to <AppDocs>/media/spines/{bookId}.jpg.

[ ] 3.5: Implement ShelfShareExporter using RenderRepaintBoundary.toImage(pixelRatio: 3.0) to export a clean, watermarked or unwatermarked PNG for social sharing via share_plus.

Verification Gate 3
Write a widget test in test/presentation/bookshelf_widget_test.dart that pumps WoodenShelfRow with 15 books of varying page counts and formats, verifying zero layout overflow exceptions and accurate width scaling.

Run flutter analyze and flutter test.

Phase 4: Barcode Scanner, Focus Timer, OCR Quotes & Analytics
Tasks
[ ] 4.1: Build BarcodeScannerScreen (lib/presentation/screens/scanner/):

Use mobile_scanner with an ISBN-13/EAN-13 overlay cutout.

Support "Single Scan" and "Rapid Batch Scan" (scans ISBN -> plays haptic feedback -> queues background lookup -> adds to selected shelf without leaving camera screen).

[ ] 4.2: Build ReadingTimerScreen (lib/presentation/screens/timer/):

Active stopwatch/countdown timer that persists start timestamp in SharedPreferences so if the OS kills the background app, elapsed time remains accurate upon reopening.

On completion, prompt user for endPage, compute pages read and reading speed (pages/min), update Book.status, and insert ReadingSession.

[ ] 4.3: Build OcrQuoteScanner in lib/presentation/screens/book_detail/:

Capture page photo -> pass to TextRecognizer (google_mlkit_text_recognition) -> allow user to highlight/edit recognized text blocks -> save to book_notes.

[ ] 4.4: Build StatsScreen (lib/presentation/screens/stats/):

Calculate current daily streak, longest streak, pages read per month (fl_chart BarChart), format distribution (PieChart), and Yearly Reading Goal progress card.

Verification Gate 4
Write unit tests for Streak calculation logic (including consecutive days, today pending, and manual backfill of a missed past date).

Run flutter analyze and flutter test.

Phase 5: Pro Monetization (RevenueCat) & Google Drive Sandbox Sync
Tasks
[ ] 5.1: Implement GoogleDriveBackupService (lib/data/services/google_drive_backup_service.dart):

Configure GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]).

Backup (createAndUploadBackup):

Run PRAGMA wal_checkpoint(FULL); on Drift SQLite so all WAL data is flushed to app_database.sqlite.

Use archive (ZipFileEncoder) to bundle app_database.sqlite, backup_manifest.json (schema version, timestamp, book count), and the /media folder into shelfcraft_backup.zip.

Query driveApi.files.list(spaces: 'appDataFolder', q: "name = 'shelfcraft_backup.zip' and trashed = false").

Update existing file ID or create a new file with parents: ['appDataFolder'].

Restore (downloadAndRestoreBackup):

Download shelfcraft_backup.zip from appDataFolder to a temporary file.

Verify backup_manifest.json integrity inside the archive before touching local data.

Close active AppDatabase connection via Riverpod provider invalidation.

Extract app_database.sqlite and /media/ directory into getApplicationDocumentsDirectory().

Re-initialize AppDatabase and refresh all state providers.

[ ] 5.2: Implement RevenueCatService (lib/data/services/revenuecat_service.dart):

Manage isProUserProvider state (Lifetime Pro or Annual Pro).

Gate Google Drive Sync, custom background themes beyond the 3 free defaults, and premium shelf props behind isProUserProvider.

Ensure Local Backup Export/Import (manual .zip or .csv to local phone storage) remains 100% Free to honor our anti-lock-in promise.

Verification Gate 5
Write integration/unit test in test/data/backup_archive_test.dart that creates a dummy SQLite file and media directory, runs the ZIP packager, extracts it to a temporary restore directory, and verifies byte-for-byte SHA/size equality of the DB and spine images.

Run full suite: flutter analyze and flutter test.