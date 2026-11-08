# 📚 ShelfCraft — Visual Bookshelf & Reading Companion

> **A tactile, local-first, 2.5D visual book tracker, in-app eBook reader, and personal library crafted for readers who love books.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.24%2B-02569B?logo=flutter)](https://flutter.dev)
[![Local First](https://img.shields.io/badge/Storage-100%25%20Local%20SQLite-success)](#privacy--local-first-promise)
[![Developer Guide](https://img.shields.io/badge/Documentation-Developer%20README-orange)](README_DEV.md)

---

## 🧭 Navigation
- Looking for technical architecture, database schemas, and build setup? 👉 Check out the [**Developer Guide (README_DEV.md)**](README_DEV.md).
- Reading this guide? Below is the complete walkthrough of every ShelfCraft feature and how to make the most of it as a reader.

---

## Table of Contents
1. [Why ShelfCraft?](#-why-shelfcraft)
2. [Feature Highlights at a Glance](#-feature-highlights-at-a-glance)
3. [Getting Started](#-getting-started)
   - [Initial Launch](#initial-launch)
   - [App Navigation Layout](#app-navigation-layout)
4. [Comprehensive Feature Walkthrough & How to Use](#-comprehensive-feature-walkthrough--how-to-use)
   - [1. Bookshelf Experience & 2.5D Display](#1-bookshelf-experience--25d-display)
     - [Procedural 2.5D Book Spines](#procedural-25d-book-spines)
     - [Custom Spine & Sprayed-Edge Cropper](#custom-spine--sprayed-edge-cropper)
     - [Display Modes: Spines, Cover-Out, and Stacks](#display-modes-spines-cover-out-and-stacks)
     - [Custom Wood Shelves & Backdrop Themes](#custom-wood-shelves--backdrop-themes)
     - [Decorative Props & Spacer Gaps](#decorative-props--spacer-gaps)
     - [Horizontal Shelf Drag-and-Drop Reordering](#horizontal-shelf-drag-and-drop-reordering)
     - [Interactive 3D Book Viewer](#interactive-3d-book-viewer)
     - [Android Home Screen App Widget](#android-home-screen-app-widget)
     - [1-Click Social Shelf Exporter](#1-click-social-shelf-exporter)
   - [2. Book Intake & Library Management](#2-book-intake--library-management)
     - [Fast ISBN Barcode Scanner](#fast-isbn-barcode-scanner)
     - [Rapid Batch Scanning Mode](#rapid-batch-scanning-mode)
     - [Manual Book Creation & Editing](#manual-book-creation--editing)
     - [Fractional Series Sorting (Novellas & #0.5)](#fractional-series-sorting-novellas--05)
     - [Dual-API Automatic Metadata Lookup](#dual-api-automatic-metadata-lookup)
     - [Reading Statuses & Multiple Formats](#reading-statuses--multiple-formats)
     - [Book Lending Tracking](#book-lending-tracking)
     - [Free Public Domain eBook Catalog (Gutenberg)](#free-public-domain-ebook-catalog-gutenberg)
   - [3. Deep Book Detail, Ratings & Notes](#3-deep-book-detail-ratings--notes)
     - [Granular 0.25-Star Ratings & Sub-Ratings Breakdown](#granular-025-star-ratings--sub-ratings-breakdown)
     - [OCR Camera Quote Scanner](#ocr-camera-quote-scanner)
     - [Categorized Notes (Quotes, Thoughts, Characters)](#categorized-notes-quotes-thoughts-characters)
     - [1-Click Social Review Sharing](#1-click-social-review-sharing)
   - [4. In-App eBook & PDF Reading](#4-in-app-ebook--pdf-reading)
     - [Reflowable EPUB Reader](#reflowable-epub-reader)
     - [Reading Themes & Typography Controls](#reading-themes--typography-controls)
     - [Chapter Table of Contents Drawer](#chapter-table-of-contents-drawer)
     - [Automatic Reading Session Logging](#automatic-reading-session-logging)
     - [In-App PDF Reader](#in-app-pdf-reader)
   - [5. Active Focus Reading Timer](#5-active-focus-reading-timer)
     - [Using the Reading Timer](#using-the-reading-timer)
     - [Background-Kill Protection](#background-kill-protection)
     - [Pages-per-Minute Speed Calculations](#pages-per-minute-speed-calculations)
   - [6. Reading Stats, Streaks & Insights](#6-reading-stats-streaks--insights)
     - [Daily Reading Streak & Streak Protection](#daily-reading-streak--streak-protection)
     - [Manual Missed-Day Backfill](#manual-missed-day-backfill)
     - [Monthly Reading Velocity Charts](#monthly-reading-velocity-charts)
     - [Format Distribution Analysis](#format-distribution-analysis)
     - [Editable Yearly Reading Challenge Goal](#editable-yearly-reading-challenge-goal)
   - [7. Anti-Lock-In Backups, Data Freedom & Cloud Sync](#7-anti-lock-in-backups-data-freedom--cloud-sync)
     - [Goodreads & StoryGraph CSV Migration](#goodreads--storygraph-csv-migration)
     - [100% Free Offline ZIP Backups & Full Restoration](#100-free-offline-zip-backups--full-restoration)
     - [RFC-4180 CSV Export with Sub-Ratings](#rfc-4180-csv-export-with-sub-ratings)
     - [Offline Gift Codes & Creator Passkey](#offline-gift-codes--creator-passkey)
     - [Automated Google Drive AppData Sync (Pro)](#automated-google-drive-appdata-sync-pro)
5. [Free vs. Pro Features](#-free-vs-pro-features)
6. [Frequently Asked Questions (FAQ)](#-frequently-asked-questions-faq)
7. [Privacy & Local-First Promise](#-privacy--local-first-promise)

---

## 🌟 Why ShelfCraft?

Most modern reading trackers treat books like flat spreadsheets or ad-stuffed social feeds. You are forced into proprietary ecosystems, bombarded with recommendations you didn't ask for, or forced to photograph hundreds of spines manually just to get a bookshelf that looks decent.

**ShelfCraft is built differently:**
* **Instant Procedural Beauty:** Books look like real, tangible volumes the second you add them. Spines scale their thickness based on actual page count, heights adjust for hardcovers vs mass-market paperbacks, and lighting shaders create realistic depth.
* **Built-in eBook Reading:** Read your own `.epub` and `.pdf` files directly in the app with customized typography, night themes, and automatic reading session tracking.
* **True Local Ownership:** Your reading log belongs to you. Everything is stored in an open SQLite database directly on your device.
* **Fractional Series Novellas:** Read a `#0.5` prequel or `#2.5` interlude? ShelfCraft places it in the exact reading order instead of breaking sorting.
* **Granular Sub-Ratings:** Rate books across Plot, Characters, Writing, and Pacing with 0.25-step precision and an auto-averaging helper.
* **Camera-Ready OCR Quotes:** Scan passages right off the physical page using on-device machine learning. No typing required.
* **Zero Hostile Lock-In:** Export all your books, covers, and notes as portable files anytime for free.

---

## ⚡ Feature Highlights at a Glance

| Feature | What It Does | Why Readers Love It |
| :--- | :--- | :--- |
| **In-App EPUB Reader** | Pure-Dart reflowable `.epub` reader with Light, Sepia, and Night themes | Seamless reading without switching apps; auto-logs reading time and pages |
| **Sub-Ratings Breakdown** | 0.25-star sliders for Plot, Characters, Writing, and Pacing | Nuanced book evaluations with 1-tap auto-average to overall rating |
| **2.5D Procedural Spines** | Generates 3D-shaded book spines scaled by page count and cover palette | Shelves look gorgeous instantly without taking manual spine photos |
| **Interactive 3D Viewer** | Gyroscopic tilt and touch-drag 3D book perspective view | Experience cover art and book depth as a tangible physical volume |
| **Android Home Widget** | Glanceable home screen widget showing current book and streak | Keep reading habits front-and-center every time you unlock your phone |
| **Physical Spine Cropper** | Photo capture and crop tool for real spines and sprayed edges | Perfect for displaying special sprayed-edge editions or antique books |
| **Batch Barcode Scanner** | Scans ISBN barcodes continuously with tactile haptic feedback | Digitize an entire physical bookshelf in under 5 minutes |
| **Free Gutenberg Catalog** | Search and download free public domain classics in one tap | Instant access to thousands of classic masterpieces at zero cost |
| **Book Lending Tracker** | Track borrower name and lent date when books are borrowed | Never lose track of which friend has your favorite paperback |
| **Dual-API Auto Lookup** | Combines OpenLibrary API with Google Books API fallback | Max cover image resolution and accurate page counts every time |
| **Fractional Series Engine** | Supports novella numbers like `0.5`, `1.5`, `2.5` | Prequels and side-novellas stay in canonical narrative order |
| **Focus Reading Timer** | Stopwatch tracking start/end pages and reading pace (pages/min) | Crash-proof and OS-kill proof; preserves timer even if phone reboots |
| **OCR Quote Scanner** | Uses on-device camera ML to extract quotes from physical pages | Save favorite book quotes in seconds with exact page attribution |
| **Streak Engine with Backfill** | Daily habit counter with pending-day safety and retroactive logging | Never lose your hard-earned streak due to forgetting to tap the app |
| **1-Click Social Sharing** | Renders 1080x1920 story graphics of shelves and formatted review cards | Share your aesthetic bookshelf and book reviews effortlessly |
| **Goodreads / StoryGraph Import**| Imports existing library CSVs, sanitizing Excel-escaped ISBNs | Effortless 1-click migration from legacy reading trackers |
| **Local ZIP & CSV Freedom** | Full archive export of database + media folder, plus free restore | 100% offline security; never pay to backup or restore your own data |
| **Offline Pro Gift Codes** | Curated promo codes, `GIFT-XXXXX` vouchers, and 7-tap creator unlock | Gift full Pro features to friends and book club members without paying |

---

## 🚀 Getting Started

### Initial Launch
1. When you first launch ShelfCraft, three default shelves are automatically set up:
   - 📖 **Currently Reading**
   - ⏳ **Want to Read (TBR)**
   - 🏆 **Finished**
2. You can immediately tap **Add Book** or jump to the **Scan ISBN** tab to add your first physical book.
3. If you have years of reading history on Goodreads or The StoryGraph, head to **Settings & Backup** to import your CSV file right away.

### App Navigation Layout
ShelfCraft is organized into four main tabs along the bottom navigation bar:

1. **Bookshelf (Home):** Your 2.5D wooden shelves, displaying your books, props, and decorative items.
2. **Scan ISBN:** The camera scanner for adding single books or batch-scanning entire physical stacks.
3. **Stats:** Reading habits, daily streak counters, monthly reading charts, and yearly challenge progress.
4. **Backup & Pro:** Data migration (CSV import), offline archive backup/restore, gift redemption, and cloud synchronization.

---

## 📖 Comprehensive Feature Walkthrough & How to Use

### 1. Bookshelf Experience & 2.5D Display

#### Procedural 2.5D Book Spines
Every book placed on your shelf is rendered in 2.5D perspective with realistic depth:
* **Dynamic Thickness:** A 1,000-page fantasy tome appears thick and imposing, while a 120-page poetry chapbook appears slim. Spine width is calculated directly from the book's verified page count:
  $$\text{Width} = \text{clamp}\left(\frac{\text{Pages}}{14.0},\ 26.0\text{ dp},\ 62.0\text{ dp}\right)$$
* **Format-Aware Heights:**
  * **Hardcover:** 185 dp tall with bold profile
  * **Paperback:** 170 dp tall standard trade size
  * **eBook / Audio:** 160 dp compact size
* **Smart Contrast Typography:** ShelfCraft analyzes the cover art's vibrant and dominant colors using palette extraction. If the book spine is dark, it renders crisp white title and author lettering; if light, it uses rich dark charcoal lettering.
* **3D Cylindrical Shader:** Overlaid gradient shading simulates crease shadows, ridge highlights, and edge drop-offs for tactile realism.

#### Custom Spine & Sprayed-Edge Cropper
Have a gorgeous special edition, an antique binding, or a book with stenciled/sprayed edges?
1. Tap any book on your shelf to open its **Book Detail** screen.
2. Tap the **Crop Spine / Edges** button.
3. Choose **Camera** to snap a photo or **Gallery** to select an existing picture.
4. Drag the cropping handles to isolate the rectangular spine or sprayed edge.
5. Tap **Save & Apply Texture**.
6. The custom photo is mapped directly onto your 2.5D book spine with cylindrical lighting overlays applied over your photo.

#### Display Modes: Spines, Cover-Out, and Stacks
You don't have to keep every book in spine mode!
1. Open any book's detail screen.
2. In the **Display On Shelf** section, toggle between:
   * **Spine View (Default):** Compact vertical spine showing title and author.
   * **Cover-Out (Face-Out):** Displays the front cover with a 3D isometric tilt and realistic shadow, spotlighting current favorites or beautiful cover designs.
   * **Horizontal Stack:** Displays the book resting horizontally, perfect for TBR piles or endcaps.

#### Custom Wood Shelves & Backdrop Themes
Personalize each individual shelf to match your home aesthetic:
1. Tap the three dots (**⋮**) on the right of any shelf row.
2. Select **Change Wood Style**.
3. Choose your favorite material:
   * **Classic Oak:** Warm golden honey grain.
   * **Dark Walnut:** Deep, luxurious espresso tone.
   * **Rich Mahogany:** Elegant reddish-brown finish.
   * **Light Birch:** Clean, minimalist Scandinavian look.
4. Each shelf features a 3D perspective top-surface trapezoid, front wooden fascia with beveled highlights, and soft bottom drop shadows.

#### Decorative Props & Spacer Gaps
Bring your virtual shelf to life with plants, candles, and cozy accents:
1. Tap the shelf menu (**⋮**) and choose **Add Prop / Spacer**.
2. Pick any decorative element:
   * 🌿 **Monstera Plant:** Vibrant leafy greenery in a modern pot.
   * 🪴 **Succulent Pot:** Compact desert desk plant.
   * 🕯️ **Amber Candle:** Warm glowing candle jar.
   * ☕ **Coffee Mug:** Steaming ceramic reading mug.
   * 🐱 **Sleeping Cat:** Cozy curled-up companion.
   * ⏰ **Vintage Clock:** Antique brass tabletop clock.
   * ⏸️ **Empty Spacer Gap:** Creates breathing room or separates genres/authors.
3. Props can be placed anywhere on the shelf and reordered just like books.

#### Horizontal Shelf Drag-and-Drop Reordering
Want to rearrange books on a shelf?
1. On the main Bookshelf screen, tap the **Reorder** icon (`⇄`) in the top app bar.
2. Each shelf enters interactive reorder mode.
3. Long-press and drag any book, prop, or spacer horizontally to its new position.
4. Tap the **Done** icon (`✓`) in the app bar when finished. All new positions are immediately saved to the database.

#### Interactive 3D Book Viewer
Experience your books in tactile 3D:
1. Open any book in Book Detail and tap the 3D cover preview.
2. Drag with your finger to rotate the book in 3D perspective space.
3. On supported devices, gyro sensors allow the book to gently tilt and catch light highlights as you move your phone.

#### Android Home Screen App Widget
Keep your reading journey front and center without launching the app:
1. Add the **ShelfCraft Widget** to your Android home screen.
2. The widget displays your Currently Reading book cover, title, author, reading progress bar, and your active streak flame counter.
3. Automatically updates whenever you log a session or change book status.

#### 1-Click Social Shelf Exporter
Show off your monthly reads or favorite collections on Instagram Stories, Threads, or TikTok:
1. Tap the **Share** (`📤`) icon in the top app bar of the Bookshelf screen.
2. ShelfCraft captures a crisp, high-resolution graphic (rendered at 3.0× pixel density for crisp retina screens) of your entire bookshelf.
3. The system share sheet appears automatically, allowing you to save the image, send it in messages, or post directly to social apps.

---

### 2. Book Intake & Library Management

#### Fast ISBN Barcode Scanner
1. Tap the **Scan ISBN** tab in the bottom bar.
2. Point your camera at the ISBN-13 or ISBN-10 barcode on the back of any physical book.
3. The red aiming reticle instantly recognizes the barcode and triggers a medium haptic pulse.
4. ShelfCraft queries OpenLibrary and Google Books in the background and opens the book entry with cover, title, author, and page count pre-populated.
5. Tap **Add to Shelf**.

#### Rapid Batch Scanning Mode
Cataloging an entire room or bookshelf?
1. In the **Scan ISBN** tab, toggle **Batch Mode** in the top-right corner.
2. Select the target shelf where scanned books should go.
3. Scan barcodes one after another. ShelfCraft chirps/vibrates on each scan, increments the scanned counter, and queues background lookups and shelf insertions automatically without interrupting your camera stream.
4. Scan 20 books in 30 seconds!

#### Manual Book Creation & Editing
For indie books, self-published titles, or uncataloged editions:
1. On the Bookshelf screen, tap the floating **+ Add Book** button.
2. Enter the Title, Author, Page Count, Format, and Reading Status.
3. ShelfCraft automatically creates a complementary color scheme based on the title letters and assigns the book to your selected shelf.
4. You can edit every single field (including custom cover images, authors, sub-ratings, and series info) at any time from the Book Detail screen.

#### Fractional Series Sorting (Novellas & #0.5)
Fantasy and romance series frequently have prequel novellas, companion shorts, and half-volumes (e.g., Book `0.5`, `1.5`, `2.5`).
* Unlike other apps that force integers or break ordering, ShelfCraft natively stores series numbers as high-precision decimals (`double`/`REAL`).
* If you set **Series Name:** `The Way of Kings` and **Series Vol:** `2.5`, your novella (*Edgedancer*) sorts canonically between Book 2 (*Words of Radiance*) and Book 3 (*Oathbringer*).

#### Dual-API Automatic Metadata Lookup
ShelfCraft features an intelligent dual-engine lookup system:
1. **Primary Lookup (OpenLibrary):** Queries the non-profit OpenLibrary API for work and edition records to fetch community-curated metadata and high-resolution book covers.
2. **Fallback & Field Enrichment (Google Books):** If OpenLibrary returns a 404, or if page count or cover art is missing, ShelfCraft automatically supplements the missing fields from Google Books API v1.
3. You get complete metadata and cover art without worrying about dead APIs.

#### Reading Statuses & Multiple Formats
Organize your library across all formats:
* **Formats Supported:** Paperback, Hardcover, eBook, Audiobook (logs duration in minutes).
* **Statuses Supported:**
  * ⏳ **Want to Read (TBR)**
  * 📖 **Currently Reading**
  * 🏆 **Finished**
  * 🛑 **Did Not Finish (DNF)**
  * 🤝 **Lent Out**

#### Book Lending Tracking
Never lose a loaned book again:
1. In the Book Detail edit dialog, set the book's status to **Lent Out**.
2. Enter the **Borrower Name** (e.g., *"Alex"*) and the **Lent Date**.
3. ShelfCraft displays a friendly reminder badge showing who has the book and for how many days.

#### Free Public Domain eBook Catalog (Gutenberg)
Looking for something classic to read?
1. Open the search/browse catalog screen.
2. Search through thousands of free public domain classics from Project Gutenberg.
3. Download `.epub` files directly into your local library with one tap!

---

### 3. Deep Book Detail, Ratings & Notes

#### Granular 0.25-Star Ratings & Sub-Ratings Breakdown
Five generic stars aren't enough for avid reviewers.
* **Overall Rating:** 0.25-star increments (`3.25`, `3.75`, `4.5`, `4.75` stars).
* **Four Sub-Ratings Dimensions:**
  * 📖 **Plot:** Narrative tension, pacing arcs, and story resolution.
  * 👥 **Characters:** Depth, growth, voice, and memorable arcs.
  * ✍️ **Writing Style:** Prose beauty, flow, and evocative dialogue.
  * ⏱️ **Pacing:** Story momentum and page-turning quality.
* **Auto-Average Helper:** Tap **Auto-Average** in the edit dialog to calculate the exact mean of your sub-ratings and update your overall book star rating automatically.
* **Color-Coded Badges:** Sub-ratings are prominently displayed on the Book Detail screen with custom pill badges.

#### OCR Camera Quote Scanner
Save unforgettable quotes directly from the printed page without manual typing:
1. Open the book detail screen and tap **Scan Quote (OCR)**.
2. Snap a clear photo of the printed page.
3. ShelfCraft's on-device Machine Learning (`google_mlkit_text_recognition`) analyzes the text blocks.
4. Tap recognized text segments to insert them into your quote editor.
5. Add the page number and optional chapter notes, then tap **Save Quote**.
6. The quote is saved locally to your book notes and can be copied or shared anytime.

#### Categorized Notes (Quotes, Thoughts, Characters)
Keep reading notes organized:
* **Quote:** Memorable lines from the book with page attribution.
* **Thought:** Your personal reactions, theorycrafting, or plot reflections while reading.
* **Character:** Notes on character names, relationships, and descriptions.

#### 1-Click Social Review Sharing
Share your ratings and thoughts with fellow readers:
1. On the Book Detail screen, tap the **Share** (`📤`) button in the app bar.
2. ShelfCraft formats your review into a clean card containing:
   * Book Title & Authors
   * Overall Star Rating (e.g., `★★★★½ (4.50 / 5)`)
   * Sub-ratings breakdown (Plot, Characters, Writing, Pacing)
   * Top featured quote from your notes
3. Shares via the native system share sheet (`SharePlus`) to WhatsApp, Twitter, Instagram, or clipboard.

---

### 4. In-App eBook & PDF Reading

#### Reflowable EPUB Reader
ShelfCraft includes a pure-Dart, high-performance EPUB reader built right into the app:
* **Zero Bloat:** No external reading apps required.
* **Clean Reading Surface:** Distraction-free pagination with chapter headers, progress percentage, and tap zones.
* **Automatic Status Promotion:** Opening a book from Want to Read (TBR) automatically marks it as Currently Reading.

#### Reading Themes & Typography Controls
Customize your reading experience for maximum comfort:
* **Themes:**
  * ☀️ **Light:** Crisp daylight contrast with clean white background.
  * 📜 **Sepia:** Warm paper tone (`#F8F1E3`) that minimizes eye strain during daytime reading.
  * 🌙 **Night:** Deep OLED-friendly zinc background (`#18181B`) with soft muted text for dark rooms.
* **Typography:**
  * Toggle between **Serif**, **Sans-Serif**, and **Monospace** typefaces.
  * Adjust font size dynamically from `13pt` to `26pt` using an intuitive slider.

#### Chapter Table of Contents Drawer
* Tap the center of the screen to reveal top/bottom navigation bars.
* Tap the **Table of Contents** icon to view the full chapter list.
* Jump directly to any chapter with one tap.

#### Automatic Reading Session Logging
* When you exit the reader, ShelfCraft computes the active reading duration and chapter progress.
* Automatically records a `ReadingSession` into your database, updating your reading streak and speed metrics!

#### In-App PDF Reader
* For PDFs, research papers, and graphic novels, ShelfCraft provides an integrated PDF viewer with zoom, horizontal/vertical paging, and thumbnail navigation.

---

### 5. Active Focus Reading Timer

#### Using the Reading Timer
Track your reading sessions and focus without distraction:
1. Open any book in your "Currently Reading" list and tap **Start Reading Session**.
2. ShelfCraft displays a distraction-free, large-numeral timer with your starting page.
3. Tap **Start Timer**. Read at your own pace.
4. When finished reading, tap **Finish Session**.
5. Enter your new current page number.
6. ShelfCraft records your active reading duration, total pages turned, and your reading speed.

#### Background-Kill Protection
Never lose a reading session to an operating system memory clean-up:
* ShelfCraft continuously syncs timer state and start timestamps to resilient on-device storage (`SharedPreferences`).
* If your phone battery dies, incoming phone calls interrupt you, or the OS terminates background processes, your timer resumes from the exact second when you reopen the app.

#### Pages-per-Minute Speed Calculations
Upon finishing a session, ShelfCraft calculates:
* Total minutes read
* Total pages read
* **Reading Pace:** Pages per minute (e.g., `0.85 pages/min`)
* Estimated time to finish the remaining chapters in your book!

---

### 6. Reading Stats, Streaks & Insights

Tap the **Stats** tab to see your reading habits visualized:

#### Daily Reading Streak & Streak Protection
* **Current Streak:** Consecutive days with at least one logged reading session.
* **Longest Streak:** Your all-time personal best reading streak.
* **"Today Pending" Grace Period:** If you read yesterday, ShelfCraft keeps your streak flame alive throughout today with a `Today Pending ⏳` badge, giving you until midnight to log your reading.

#### Manual Missed-Day Backfill
Life happens. If you read offline during a flight or forgot your phone during a weekend camping trip:
1. In the Book Detail screen or Stats screen, tap **Log Session Manually**.
2. Select the past date you read, along with minutes and pages.
3. ShelfCraft's streak engine recalculates the timeline, bridges the gap, and restores your active streak!

#### Monthly Reading Velocity Charts
* Interactive bar charts (`fl_chart`) display pages read month-by-month.
* Compare reading volume across seasons and track surges in reading momentum.

#### Format Distribution Analysis
* A clean pie chart breaks down your library by physical and digital formats:
  * 📕 Paperback
  * 📘 Hardcover
  * 📱 eBook
  * 🎧 Audiobook

#### Editable Yearly Reading Challenge Goal
* Set your target number of books for the year (e.g., 25 or 52 books).
* Tap the pencil icon directly on the **Yearly Challenge Card** to update your goal anytime.
* An animated progress ring displays completed books, percentage progress, and pace status.

---

### 7. Anti-Lock-In Backups, Data Freedom & Cloud Sync

#### Goodreads & StoryGraph CSV Migration
Moving your library to ShelfCraft is seamless:
1. Export your library CSV from Goodreads (Account Settings → Export Library) or The StoryGraph (Manage Account → Export Data).
2. Save the CSV file onto your phone.
3. In ShelfCraft, open **Settings & Backup** and tap **Import from Goodreads / StoryGraph CSV**.
4. Select your CSV file.
5. ShelfCraft cleans Excel-escaped ISBN strings (e.g., `="9780140283297"`), maps exclusive shelves (`to-read`, `currently-reading`, `read`), parses fractional novella series entries, and transactionally imports your entire reading history into your local SQLite database in seconds!

#### 100% Free Offline ZIP Backups & Full Restoration
We believe you should never pay to access or export your own data:
1. **Export Local Archive (.zip):** Flushes SQLite WAL (`PRAGMA wal_checkpoint(FULL);`) and bundles `app_database.sqlite`, a JSON schema manifest, and all local covers/cropped spines into a single compressed `.zip` archive.
2. **Restore Local Archive (.zip):** Tap **Restore Local .ZIP Backup** under Settings & Backup to restore your entire library, book spines, and notes byte-for-byte on any device. Completely free!

#### RFC-4180 CSV Export with Sub-Ratings
Export your entire collection anytime:
* Exports Title, Authors, ISBN, Pages, Format, Status, Overall Rating, and all four Sub-Ratings (`Rating Plot`, `Rating Characters`, `Rating Writing`, `Rating Pacing`).
* 100% roundtrip fidelity: any CSV exported from ShelfCraft can be imported right back with zero data loss.

#### Offline Gift Codes & Creator Passkey
Want to gift Pro features to friends, beta testers, or book club members without paying?
* Open **Settings & Backup** and tap **Redeem Gift Code / Voucher** (or tap *"Have a Gift Code? Redeem Here"* on the upgrade paywall).
* **Supported Codes:**
  * Curated codes: `GIFT-SHELFCRAFT`, `BOOKWORM-PRO`, `SLOWREAD-VIP`, `READMORE-2026`
  * Voucher pattern: Any `GIFT-` followed by letters or digits (e.g. `GIFT-FRIEND100`, `GIFT-SARATH`)
  * Creator debug passkey: `DEV-OVERRIDE-2026`
* Pro is permanently unlocked in on-device persistent storage (`SharedPreferences`) without requiring app store payments or internet connection!
* **Creator Easter Egg:** Tap the *"ShelfCraft v1.0.0"* footer 7 times in Settings to open the secret redemption dialog.

#### Automated Google Drive AppData Sync (Pro)
For hands-free cloud redundancy:
* Connect your Google account. ShelfCraft uses strictly the sandboxed `drive.appdata` scope.
* **Privacy Guarantee:** The app *only* reads and writes inside its own hidden application folder; it cannot view, access, or modify your personal files, Google Docs, or Google Photos.
* 1-click automatic backup and cloud restoration across devices.

---

## 💎 Free vs. Pro Features

ShelfCraft is committed to a **generous free tier with zero lock-in**:

| Capability | Free Community Edition | Pro Supporter Tier |
| :--- | :---: | :---: |
| **Complete Offline Bookshelf** | Unlimited books | Unlimited books |
| **In-App EPUB & PDF Reader** | ✅ 100% Free | ✅ 100% Free |
| **Sub-Ratings Breakdown (Plot, Characters, Writing, Pacing)** | ✅ 100% Free | ✅ 100% Free |
| **Interactive 3D Book Viewer** | ✅ 100% Free | ✅ 100% Free |
| **Android Home Screen App Widget** | ✅ 100% Free | ✅ 100% Free |
| **Procedural 2.5D Spines** | ✅ Yes | ✅ Yes |
| **Custom Spine & Edge Cropper** | ✅ Yes | ✅ Yes |
| **Barcode Scanner (Single & Batch)** | ✅ Yes | ✅ Yes |
| **Reading Timer & OCR Quotes** | ✅ Yes | ✅ Yes |
| **Reading Streaks & Full Stats** | ✅ Yes | ✅ Yes |
| **Goodreads / StoryGraph CSV Import** | ✅ 100% Free | ✅ 100% Free |
| **Local ZIP Archive Backup & Restore** | ✅ 100% Free | ✅ 100% Free |
| **Full CSV Export / Import with Sub-Ratings** | ✅ 100% Free | ✅ 100% Free |
| **Offline Gift / Promo Code Redemption** | ✅ 100% Free | ✅ 100% Free |
| **Shelves & Wood Themes** | 3 Classic Themes | Unlimited Artisan Styles |
| **Shelf Props & Spacers** | Starter Greenery & Gap | Full Premium Prop Catalog |
| **Automated Google Drive Sync** | — | ✅ Automated Cloud Backup |

---

## ❓ Frequently Asked Questions (FAQ)

### Does ShelfCraft require an Internet connection?
**No.** ShelfCraft is offline-first. All books, in-app EPUB reading, reading timers, streaks, notes, and local backups work completely offline in Airplane Mode. Internet access is only used when looking up new ISBN barcodes, downloading Gutenberg eBooks, or backing up to Google Drive.

### Can I read EPUB and PDF books directly inside ShelfCraft?
**Yes!** ShelfCraft has a built-in reflowable EPUB reader with Light, Sepia, and Night modes, customizable fonts and font sizes, and chapter navigation. You can also view PDF files without third-party apps.

### Will ShelfCraft show advertisements?
**Never.** ShelfCraft is an ad-free experience.

### What happens to my library if I switch phones?
Simply tap **Export Local Archive (.zip)** under Settings & Backup. Move that single zip file to your new phone (via AirDrop, USB, Drive, or email), tap **Restore Local Archive (.zip)** in ShelfCraft, and your entire library—including all covers, custom spines, sub-ratings, and notes—will load identically. Pro users can also restore from Google Drive in one tap.

### How does ShelfCraft calculate spine thickness?
Spine thickness is calculated directly from the book's verified page count using a smooth proportional curve (`pages / 14.0`, bounded between 26 and 62 logical pixels). A 150-page novella will look visibly slimmer than an 800-page hardcover.

### Can I give Pro to a friend or activate it offline?
**Yes!** In Settings & Backup, tap **Redeem Gift Code / Voucher** and type any code prefixed with `GIFT-` (or use `GIFT-SHELFCRAFT`, `BOOKWORM-PRO`, etc.). Pro features will be unlocked permanently on that device without any payment.

---

## 🛡️ Privacy & Local-First Promise

1. **No Accounts Required:** You don't need to create a username or password to use ShelfCraft.
2. **On-Device Database:** Your reading list, ratings, notes, and reading times live in an open SQLite database on your hardware.
3. **Zero Analytics Tracking:** We do not track your reading speed, what books you read, or sell reading habits to publishers or advertisers.
4. **Sandboxed Cloud:** Even if you use Pro Google Drive sync, ShelfCraft requests only `drive.appdata` permissions, keeping your cloud backup encrypted in your private sandboxed folder.

---

*ShelfCraft — Handcrafted for readers, book collectors, and slow-reading enthusiasts.*  
*Have questions or want to contribute? Check out the [**Developer Guide (README_DEV.md)**](README_DEV.md).*
