import 'dart:convert';
import 'dart:io';
import '../local/database.dart';
import 'models/backup_snapshot_dto.dart';

/// Serializes local SQLite database state into a versioned, portable, Gzipped JSON payload (.rsbk).
class BackupSerializer {
  static const int currentSchemaVersion = 1;
  static const String currentAppVersion = '1.1.0';

  /// Serializes the entire database into a Gzipped byte list (.rsbk).
  Future<List<int>> serializeDatabase(
    AppDatabase db, {
    String deviceId = 'primary-device',
  }) async {
    // 1. Fetch all records from all tables
    final books = await db.bookDao.getAllBooks(includeDeleted: true);
    final shelves = await db.shelfDao.getAllShelves();
    final shelfItems = await db.select(db.shelfItems).get();
    final bookShelves = await db.select(db.bookShelves).get();
    final readingSessions = await db.sessionDao.getAllSessions();
    final bookNotes = await db.select(db.bookNotes).get();

    // 2. Build JSON mapping
    final dataMap = {
      'books': books.map((b) => _bookToJson(b)).toList(),
      'shelves': shelves.map((s) => _shelfToJson(s)).toList(),
      'shelf_items': shelfItems.map((si) => _shelfItemToJson(si)).toList(),
      'book_shelves': bookShelves.map((bs) => _bookShelfToJson(bs)).toList(),
      'reading_sessions':
          readingSessions.map((rs) => _sessionToJson(rs)).toList(),
      'book_notes': bookNotes.map((bn) => _noteToJson(bn)).toList(),
    };

    final snapshot = BackupSnapshotDto(
      schemaVersion: currentSchemaVersion,
      appVersion: currentAppVersion,
      exportedAt: DateTime.now().millisecondsSinceEpoch,
      deviceId: deviceId,
      data: dataMap,
    );

    // 3. Encode to JSON string, then compress with Gzip
    final jsonString = jsonEncode(snapshot.toJson());
    final utf8Bytes = utf8.encode(jsonString);
    return gzip.encode(utf8Bytes);
  }

  /// Exports database directly to a target .rsbk file.
  Future<File> exportToFile(
    AppDatabase db,
    File destinationFile, {
    String deviceId = 'primary-device',
  }) async {
    final gzippedBytes = await serializeDatabase(db, deviceId: deviceId);
    return destinationFile.writeAsBytes(gzippedBytes, flush: true);
  }

  Map<String, dynamic> _bookToJson(Book b) => {
        'id': b.id,
        'isbn13': b.isbn13,
        'title': b.title,
        'subtitle': b.subtitle,
        'description': b.description,
        'publisher': b.publisher,
        'publish_year': b.publishYear,
        'authors': b.authors,
        'page_count': b.pageCount,
        'format': b.format,
        'status': b.status,
        'finished_at': b.finishedAt,
        'series_name': b.seriesName,
        'series_index': b.seriesIndex,
        'cover_path': b.coverPath,
        'back_cover_path': b.backCoverPath,
        'custom_spine_path': b.customSpinePath,
        'pdf_path': b.pdfPath,
        'last_read_page': b.lastReadPage,
        'spine_color_hex': b.spineColorHex,
        'spine_text_hex': b.spineTextHex,
        'rating': b.rating,
        'rating_plot': b.ratingPlot,
        'rating_characters': b.ratingCharacters,
        'rating_writing': b.ratingWriting,
        'rating_pacing': b.ratingPacing,
        'last_read_at': b.lastReadAt,
        'created_at': b.createdAt,
        'updated_at': b.updatedAt,
        'deleted_at': b.deletedAt,
      };

  Map<String, dynamic> _shelfToJson(Shelf s) => {
        'id': s.id,
        'name': s.name,
        'wood_theme_id': s.woodThemeId,
        'wall_theme_id': s.wallThemeId,
        'sort_order': s.sortOrder,
        'created_at': s.createdAt,
        'updated_at': s.updatedAt,
        'deleted_at': s.deletedAt,
      };

  Map<String, dynamic> _shelfItemToJson(ShelfItem si) => {
        'id': si.id,
        'shelf_id': si.shelfId,
        'item_type': si.itemType,
        'book_id': si.bookId,
        'prop_asset_id': si.propAssetId,
        'display_mode': si.displayMode,
        'position_index': si.positionIndex,
      };

  Map<String, dynamic> _bookShelfToJson(BookShelf bs) => {
        'book_id': bs.bookId,
        'shelf_id': bs.shelfId,
      };

  Map<String, dynamic> _sessionToJson(ReadingSession rs) => {
        'id': rs.id,
        'book_id': rs.bookId,
        'start_time': rs.startTime,
        'duration_seconds': rs.durationSeconds,
        'start_page': rs.startPage,
        'end_page': rs.endPage,
      };

  Map<String, dynamic> _noteToJson(BookNote bn) => {
        'id': bn.id,
        'book_id': bn.bookId,
        'note_type': bn.noteType,
        'content': bn.content,
        'page_number': bn.pageNumber,
        'created_at': bn.createdAt,
      };
}
