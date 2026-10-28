# Product & System Requirements Document (requirement.md)

## 1. Project Overview
- **Project Name:** ShelfCraft (SlowRead Alternative)
- **Platform:** Android & iOS (Flutter 3.24+ / Dart 3.5+)
- **Architecture:** Local-First, Offline-Capable MVVM with Riverpod & Drift (SQLite)
- **Monetization Model:** Generous Free Tier + Fair Pro Unlock (One-time Lifetime or Low Annual Sub via RevenueCat) gating Automated Google Drive Cloud Backup & Premium Cosmetics.

---

## 2. Competitive Pain Points Addressed (Why We Exist)
1. **Zero Forced Manual Spine Photography:** Automatically generate realistic 2.5D book spines out-of-the-box by extracting dominant/vibrant colors from book covers (`palette_generator`) and calculating width from page count. Users *can* still upload custom spine/sprayed-edge photos, but the shelf looks great immediately after CSV import.
2. **Fractional Series Support:** Native `REAL` (`double`) support for series indices (e.g., Book `0.5`, `1.5`, `2.5`) so novellas never break sorting.
3. **True Local-First Ownership:** Zero proprietary cloud lock-in. 100% SQLite local storage with 1-click CSV/JSON export for Free users, and sandboxed Google Drive (`appDataFolder`) automated sync for Pro users.
4. **Resilient Dual-API Book Lookup:** Primary lookup via **OpenLibrary API** (Work + Edition resolution) with automatic fallback to **Google Books API v1** when cover images or page counts are missing.

---

## 3. Functional Requirements

### 3.1 Book Intake & Library Management
- **FR-1 (Search):** Search books by Title, Author, or ISBN using OpenLibrary API with automatic fallback to Google Books API.
- **FR-2 (Barcode Scanner):** Scan physical ISBN-10 / ISBN-13 barcodes using `mobile_scanner` with batch-scan mode (scan multiple books consecutively onto a shelf).
- **FR-3 (Manual Entry & Edit):** Full override capability for any book field (Title, Author, Pages, Format, Edition, Publication Year, Series Name, Fractional Series Number).
- **FR-4 (Multi-Format Support):** Support `Paperback`, `Hardcover`, `eBook`, and `Audiobook` (storing total duration in minutes for audiobooks).
- **FR-5 (Reading Statuses):** `WantToRead (TBR)`, `CurrentlyReading`, `Finished`, `DidNotFinish (DNF)`, `LentOut`. Support multiple read-throughs (Reread logs).
- **FR-6 (CSV Migration):** Import from Goodreads CSV, StoryGraph CSV, and Openreads CSV. Export full library to standard CSV.

### 3.2 2.5D Virtual Bookshelf & Customization
- **FR-7 (Dual Display Modes):** Toggle any book on the shelf between **Spine View** (default), **Front Cover View** (face-out display), or **Horizontal Stack**.
- **FR-8 (Procedural 2.5D Spine Rendering):**
  - Spine width proportional to page count: `clamp(pages / 12.0, 24.0, 64.0)`.
  - Spine height modulated by format (`Hardcover`: 220dp, `Paperback`: 200dp, `MassMarket`: 180dp).
  - Auto-extracted background color (`dominantColor`) and contrasting text color (`titleTextColor`) from cover image.
  - 3D cylindrical lighting shader (`LinearGradient` overlay simulating crease shadow, ridge highlight, and edge drop-off).
- **FR-9 (Custom Physical Spine & Sprayed Edge Cropper):** Capture photo via camera/gallery, crop rectangular spine or sprayed edge via interactive 4-point/rect cropper, and map as texture onto the spine widget.
- **FR-10 (Shelf Styling & Props):** Customize shelf wood grain, wall background color/texture, and insert decorative props (plants, candles, bookends, empty gaps) at specific shelf indices.
- **FR-11 (Social Export):** Render high-resolution (1080x1920 / 1080x1350) PNG of any shelf or yearly wrap-up using `RenderRepaintBoundary` for Instagram/TikTok sharing.

### 3.3 Active Reading, Habits & Notes
- **FR-12 (Focus Reading Timer):** Stopwatch & countdown timer logging session start, end, duration, and ending page/minute.
- **FR-13 (Streak & Heatmap Engine):** Daily reading streak counter with ability to backfill missed days manually.
- **FR-14 (OCR Quote Scanner):** Extract text from physical book pages via camera (`google_mlkit_text_recognition`) and save with page number and chapter note.
- **FR-15 (Granular Ratings):** Support 0.25-star increment ratings (`0.25` to `5.0`) + custom sub-ratings (Plot, Characters, Writing, Pacing).

### 3.4 Storage, Backup & Pro Monetization
- **FR-16 (Local Storage):** All structured data stored in `drift` (SQLite). All downloaded covers and cropped spines stored in `<AppDocuments>/media/` with relative paths saved in SQLite.
- **FR-17 (Google Drive Sandbox Sync - Pro):**
  - Authenticate via `google_sign_in` using strictly `https://www.googleapis.com/auth/drive.appdata` scope.
  - Bundle `app_database.sqlite` + `/media` directory into a compressed `.shelfbackup` (ZIP) archive.
  - Upload/update and restore from Google Drive `appDataFolder`.
- **FR-18 (Paywall Gate):** Integrate `purchases_flutter` (RevenueCat) to gate Google Drive Sync, unlimited custom shelf themes, and premium decorative props.

---

## 4. Database Schema Specification (Drift / SQLite)

### Table: `books`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` (UUID) | PRIMARY KEY | Unique local identifier |
| `isbn13` | `TEXT` | NULLABLE, INDEXED | ISBN-13 identifier |
| `title` | `TEXT` | NOT NULL | Book title |
| `subtitle` | `TEXT` | NULLABLE | Book subtitle |
| `authors` | `TEXT` | NOT NULL | JSON array of author names |
| `page_count` | `INTEGER` | DEFAULT 250 | Number of pages (used for spine math) |
| `format` | `TEXT` | DEFAULT 'paperback' | `paperback`, `hardcover`, `ebook`, `audiobook` |
| `status` | `TEXT` | NOT NULL | `tbr`, `reading`, `finished`, `dnf`, `lent` |
| `series_name` | `TEXT` | NULLABLE | Name of saga/series |
| `series_index` | `REAL` | NULLABLE | Fractional float (`0.5`, `1.0`, `2.5`) |
| `cover_path` | `TEXT` | NULLABLE | Relative path to cached local cover image |
| `custom_spine_path`| `TEXT` | NULLABLE | Relative path to user-cropped spine image |
| `spine_color_hex` | `INTEGER` | NOT NULL | ARGB int extracted from cover or user-picked |
| `spine_text_hex` | `INTEGER` | NOT NULL | Contrasting ARGB int for spine typography |
| `rating` | `REAL` | NULLABLE | `0.0` to `5.0` (supports `0.25` steps) |
| `created_at` | `INTEGER` | NOT NULL | Unix epoch ms |
| `updated_at` | `INTEGER` | NOT NULL | Unix epoch ms |

### Table: `shelves`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` (UUID) | PRIMARY KEY | Unique shelf ID |
| `name` | `TEXT` | NOT NULL | Display name |
| `wood_theme_id` | `TEXT` | DEFAULT 'oak' | Wood texture key |
| `wall_theme_id` | `TEXT` | DEFAULT 'warm_cream'| Backdrop theme key |
| `sort_order` | `INTEGER` | NOT NULL | Vertical shelf order |

### Table: `shelf_items` (Supports Books AND Props on Shelves)
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` (UUID) | PRIMARY KEY | Item placement ID |
| `shelf_id` | `TEXT` | FK -> `shelves.id` | Target shelf |
| `item_type` | `TEXT` | NOT NULL | `book`, `prop`, `gap` |
| `book_id` | `TEXT` | NULLABLE, FK | Populated if `item_type == 'book'` |
| `prop_asset_id` | `TEXT` | NULLABLE | E.g., `plant_monstera`, `candle_amber` |
| `display_mode` | `TEXT` | DEFAULT 'spine' | `spine`, `cover_out`, `stacked` |
| `position_index` | `INTEGER` | NOT NULL | Horizontal order on shelf |

### Table: `reading_sessions`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` (UUID) | PRIMARY KEY | Session ID |
| `book_id` | `TEXT` | FK -> `books.id` | Associated book |
| `start_time` | `INTEGER` | NOT NULL | Unix epoch ms |
| `duration_seconds`| `INTEGER` | NOT NULL | Active reading time |
| `start_page` | `INTEGER` | NOT NULL | Starting page |
| `end_page` | `INTEGER` | NOT NULL | Ending page |

### Table: `book_notes`
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` (UUID) | PRIMARY KEY | Note/Quote ID |
| `book_id` | `TEXT` | FK -> `books.id` | Associated book |
| `note_type` | `TEXT` | NOT NULL | `quote`, `thought`, `character` |
| `content` | `TEXT` | NOT NULL | Text or OCR-scanned quote |
| `page_number` | `INTEGER` | NULLABLE | Associated page |
| `created_at` | `INTEGER` | NOT NULL | Unix epoch ms |

---

## 5. Non-Functional & Legal Requirements
- **NFR-1 (60/120 FPS Scrolling):** Each shelf row and procedural spine must be wrapped in `RepaintBoundary` and use cached image dimensions so scrolling a library of 500+ books drops zero frames.
- **NFR-2 (Strict Clean-Room Licensing):** Zero code files may be copied from `mateusz-bak/openreads` (GPL-2.0). All dependencies in `pubspec.yaml` must use MIT, BSD, or Apache-2.0 licenses.
- **NFR-3 (Offline First):** Every core feature (except ISBN search and Google Drive backup) must function in Airplane Mode.