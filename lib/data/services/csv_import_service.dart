import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/formatters.dart';
import '../local/database.dart';
import '../../core/utils/color_extractor.dart';

class CsvImportResult {
  final List<BooksCompanion> books;
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<String> warnings;

  const CsvImportResult({
    required this.books,
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    this.warnings = const [],
  });
}

/// Service to parse and import book libraries from Goodreads, StoryGraph, or generic CSV.
class CsvImportService {
  final Uuid _uuid;

  CsvImportService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Sanitizes Goodreads' `="978..."` or standard ISBN strings using regex.
  static String? sanitizeIsbn(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty || str == '=""') return null;

    final cleaned = str.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (cleaned.length == 10 || cleaned.length == 13) {
      return cleaned;
    }
    return cleaned.isNotEmpty ? cleaned : null;
  }

  /// Parses CSV content into a list of [BooksCompanion] ready for database insertion.
  CsvImportResult parseCsv(String csvContent) {
    if (csvContent.trim().isEmpty) {
      return const CsvImportResult(
        books: [],
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        warnings: ['CSV content is empty'],
      );
    }

    // Convert CSV content into rows, normalizing line breaks
    final normalizedContent =
        csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    const converter = CsvToListConverter(shouldParseNumbers: false, eol: '\n');
    final allRows = converter.convert(normalizedContent.trim());
    final rows = allRows
        .where((r) =>
            r.isNotEmpty &&
            !(r.length == 1 && r.first.toString().trim().isEmpty))
        .toList();
    if (rows.isEmpty) {
      return const CsvImportResult(
        books: [],
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        warnings: ['No data rows found in CSV'],
      );
    }

    final rawHeaders = rows.first.map((e) => e.toString().trim()).toList();
    final headerIndexMap = <String, int>{};
    for (int i = 0; i < rawHeaders.length; i++) {
      headerIndexMap[rawHeaders[i].toLowerCase()] = i;
    }

    final isGoodreads = headerIndexMap.containsKey('book id') ||
        headerIndexMap.containsKey('exclusive shelf');
    final isStoryGraph = headerIndexMap.containsKey('read status') ||
        headerIndexMap.containsKey('star rating');

    final books = <BooksCompanion>[];
    final warnings = <String>[];
    int errorCount = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (int rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.isEmpty ||
          (row.length == 1 && row.first.toString().trim().isEmpty)) {
        continue;
      }

      try {
        final BooksCompanion? book = isGoodreads
            ? _parseGoodreadsRow(row, headerIndexMap, now)
            : isStoryGraph
                ? _parseStoryGraphRow(row, headerIndexMap, now)
                : _parseGenericRow(row, headerIndexMap, now);

        if (book != null) {
          books.add(book);
        } else {
          errorCount++;
          warnings
              .add('Row $rowIndex skipped: missing required title or author');
        }
      } catch (e) {
        errorCount++;
        warnings.add('Row $rowIndex error: $e');
      }
    }

    return CsvImportResult(
      books: books,
      totalRows: rows.length - 1,
      successCount: books.length,
      errorCount: errorCount,
      warnings: warnings,
    );
  }

  BooksCompanion? _parseGoodreadsRow(
    List<dynamic> row,
    Map<String, int> headers,
    int now,
  ) {
    String? getCol(String colName) {
      final idx = headers[colName];
      if (idx != null && idx < row.length) {
        final val = row[idx].toString().trim();
        return val.isEmpty ? null : val;
      }
      return null;
    }

    final rawTitle = getCol('title');
    final author = getCol('author');
    if (rawTitle == null || rawTitle.isEmpty) return null;

    final parsedSeries = _extractSeriesFromTitle(rawTitle);
    final title = parsedSeries.cleanTitle;
    final seriesName = parsedSeries.seriesName;
    final seriesIndex = parsedSeries.seriesIndex;

    // Authors JSON
    final authorsList = <String>[
      if (author != null && author.isNotEmpty) author
    ];
    final addlAuthors = getCol('additional authors');
    if (addlAuthors != null && addlAuthors.isNotEmpty) {
      authorsList.addAll(
        addlAuthors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }
    final authorsJson =
        jsonEncode(authorsList.isEmpty ? ['Unknown Author'] : authorsList);

    // ISBN-13
    final isbn13 =
        sanitizeIsbn(getCol('isbn13')) ?? sanitizeIsbn(getCol('isbn'));

    // Pages
    int pageCount = 250;
    final pagesRaw = getCol('number of pages');
    if (pagesRaw != null) {
      final parsed = int.tryParse(pagesRaw.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null && parsed > 0) {
        pageCount = parsed;
      }
    }

    // Status
    final exclusiveShelf =
        getCol('exclusive shelf')?.toLowerCase() ?? 'to-read';
    final status = _mapStatus(exclusiveShelf);

    // Rating
    double? rating;
    final ratingRaw = getCol('my rating');
    if (ratingRaw != null) {
      final parsedRating = double.tryParse(ratingRaw);
      if (parsedRating != null && parsedRating > 0.0) {
        rating = parsedRating;
      }
    }

    // Format
    final binding = getCol('binding')?.toLowerCase() ?? '';
    final format = _mapFormat(binding);

    // Spine colors
    final spineColors = _generateSpineColors(title);

    return BooksCompanion.insert(
      id: _uuid.v4(),
      isbn13: Value(isbn13),
      title: title,
      authors: authorsJson,
      pageCount: Value(pageCount),
      format: Value(format),
      status: status,
      seriesName: Value(seriesName),
      seriesIndex: Value(seriesIndex),
      spineColorHex: spineColors.spineColorHex,
      spineTextHex: spineColors.spineTextHex,
      rating: Value(rating),
      createdAt: now,
      updatedAt: now,
    );
  }

  BooksCompanion? _parseStoryGraphRow(
    List<dynamic> row,
    Map<String, int> headers,
    int now,
  ) {
    String? getCol(String colName) {
      final idx = headers[colName];
      if (idx != null && idx < row.length) {
        final val = row[idx].toString().trim();
        return val.isEmpty ? null : val;
      }
      return null;
    }

    final rawTitle = getCol('title');
    final authorsRaw = getCol('authors') ?? getCol('author');
    if (rawTitle == null || rawTitle.isEmpty) return null;

    final parsedSeries = _extractSeriesFromTitle(rawTitle);
    final title = parsedSeries.cleanTitle;

    final authorsList = <String>[];
    if (authorsRaw != null && authorsRaw.isNotEmpty) {
      authorsList.addAll(
        authorsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }
    final authorsJson =
        jsonEncode(authorsList.isEmpty ? ['Unknown Author'] : authorsList);

    final isbn =
        sanitizeIsbn(getCol('isbn/uid')) ?? sanitizeIsbn(getCol('isbn'));

    int pageCount = 250;
    final pagesRaw = getCol('number of pages');
    if (pagesRaw != null) {
      final parsed = int.tryParse(pagesRaw.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null && parsed > 0) {
        pageCount = parsed;
      }
    }

    final statusRaw = getCol('read status')?.toLowerCase() ?? 'to-read';
    final status = _mapStatus(statusRaw);

    double? rating;
    final ratingRaw = getCol('star rating');
    if (ratingRaw != null) {
      final parsed = double.tryParse(ratingRaw);
      if (parsed != null && parsed > 0.0) {
        rating = parsed;
      }
    }

    final formatRaw = getCol('format')?.toLowerCase() ?? '';
    final format = _mapFormat(formatRaw);

    final spineColors = _generateSpineColors(title);

    return BooksCompanion.insert(
      id: _uuid.v4(),
      isbn13: Value(isbn),
      title: title,
      authors: authorsJson,
      pageCount: Value(pageCount),
      format: Value(format),
      status: status,
      seriesName: Value(parsedSeries.seriesName),
      seriesIndex: Value(parsedSeries.seriesIndex),
      spineColorHex: spineColors.spineColorHex,
      spineTextHex: spineColors.spineTextHex,
      rating: Value(rating),
      createdAt: now,
      updatedAt: now,
    );
  }

  BooksCompanion? _parseGenericRow(
    List<dynamic> row,
    Map<String, int> headers,
    int now,
  ) {
    String? getCol(List<String> possibleNames) {
      for (final name in possibleNames) {
        final idx = headers[name];
        if (idx != null && idx < row.length) {
          final val = row[idx].toString().trim();
          if (val.isNotEmpty) return val;
        }
      }
      return null;
    }

    final title = getCol(['title', 'book title', 'name']);
    final author = getCol(['author', 'authors', 'writer']);
    if (title == null || title.isEmpty) return null;

    final parsedSeries = _extractSeriesFromTitle(title);
    final authorsJson = jsonEncode([author ?? 'Unknown Author']);
    final isbn = sanitizeIsbn(getCol(['isbn13', 'isbn', 'isbn-13']));

    int pageCount = 250;
    final pagesRaw = getCol(['pages', 'number of pages', 'page count']);
    if (pagesRaw != null) {
      final parsed = int.tryParse(pagesRaw.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null && parsed > 0) {
        pageCount = parsed;
      }
    }

    final statusRaw =
        getCol(['status', 'shelf', 'read status'])?.toLowerCase() ?? 'tbr';
    final status = _mapStatus(statusRaw);

    double? rating;
    final ratingRaw = getCol(['rating', 'my rating', 'score']);
    if (ratingRaw != null) {
      final parsed = double.tryParse(ratingRaw);
      if (parsed != null && parsed > 0.0) {
        rating = parsed;
      }
    }

    double? ratingPlot;
    final ratingPlotRaw = getCol(['rating plot', 'plot rating', 'plot']);
    if (ratingPlotRaw != null) {
      final parsed = double.tryParse(ratingPlotRaw);
      if (parsed != null && parsed > 0.0) ratingPlot = parsed;
    }

    double? ratingCharacters;
    final ratingCharactersRaw =
        getCol(['rating characters', 'characters rating', 'characters']);
    if (ratingCharactersRaw != null) {
      final parsed = double.tryParse(ratingCharactersRaw);
      if (parsed != null && parsed > 0.0) ratingCharacters = parsed;
    }

    double? ratingWriting;
    final ratingWritingRaw =
        getCol(['rating writing', 'writing rating', 'writing']);
    if (ratingWritingRaw != null) {
      final parsed = double.tryParse(ratingWritingRaw);
      if (parsed != null && parsed > 0.0) ratingWriting = parsed;
    }

    double? ratingPacing;
    final ratingPacingRaw = getCol(['rating pacing', 'pacing rating', 'pacing']);
    if (ratingPacingRaw != null) {
      final parsed = double.tryParse(ratingPacingRaw);
      if (parsed != null && parsed > 0.0) ratingPacing = parsed;
    }

    final spineColors = _generateSpineColors(parsedSeries.cleanTitle);

    final explicitSeriesName = getCol(['series name', 'series']);
    final explicitSeriesIdxRaw =
        getCol(['series index', 'series vol', 'series number', 'volume']);
    final explicitSeriesIdx = explicitSeriesIdxRaw != null
        ? double.tryParse(explicitSeriesIdxRaw)
        : null;

    final finalSeriesName = explicitSeriesName ?? parsedSeries.seriesName;
    final finalSeriesIndex = explicitSeriesIdx ?? parsedSeries.seriesIndex;

    final formatRaw =
        getCol(['format', 'binding', 'edition'])?.toLowerCase() ?? 'paperback';
    final format = _mapFormat(formatRaw);

    return BooksCompanion.insert(
      id: _uuid.v4(),
      isbn13: Value(isbn),
      title: parsedSeries.cleanTitle,
      authors: authorsJson,
      pageCount: Value(pageCount),
      format: Value(format),
      status: status,
      seriesName: Value(finalSeriesName),
      seriesIndex: Value(finalSeriesIndex),
      spineColorHex: spineColors.spineColorHex,
      spineTextHex: spineColors.spineTextHex,
      rating: Value(rating),
      ratingPlot: Value(ratingPlot),
      ratingCharacters: Value(ratingCharacters),
      ratingWriting: Value(ratingWriting),
      ratingPacing: Value(ratingPacing),
      createdAt: now,
      updatedAt: now,
    );
  }

  String _mapStatus(String raw) {
    if (raw.contains('reading') || raw.contains('current')) {
      return 'reading';
    }
    if (raw.contains('read') && !raw.contains('to-read')) {
      return 'finished';
    }
    if (raw.contains('dnf') ||
        raw.contains('did not finish') ||
        raw.contains('abandoned')) {
      return 'dnf';
    }
    if (raw.contains('lent')) {
      return 'lent';
    }
    return 'tbr';
  }

  String _mapFormat(String raw) {
    if (raw.contains('hardcover')) return 'hardcover';
    if (raw.contains('ebook') ||
        raw.contains('kindle') ||
        raw.contains('digital')) return 'ebook';
    if (raw.contains('audio')) return 'audiobook';
    return 'paperback';
  }

  _SeriesParseResult _extractSeriesFromTitle(String rawTitle) {
    // E.g. "The Way of Kings (The Stormlight Archive, #1)" or "(Mistborn, #0.5)"
    final regex = RegExp(
        r'^(.*?)\s*\((.*?),\s*(?:#|book\s*)?([0-9]+(?:\.[0-9]+)?)\)\s*$');
    final match = regex.firstMatch(rawTitle);
    if (match != null) {
      final cleanTitle = match.group(1)?.trim() ?? rawTitle;
      final seriesName = match.group(2)?.trim();
      final seriesIndex = double.tryParse(match.group(3) ?? '');
      return _SeriesParseResult(
        cleanTitle: cleanTitle.isEmpty ? rawTitle : cleanTitle,
        seriesName: seriesName,
        seriesIndex: seriesIndex,
      );
    }
    return _SeriesParseResult(cleanTitle: rawTitle);
  }

  /// Procedural spine colors palette for handsome out-of-the-box shelf rendering.
  SpineColors _generateSpineColors(String seed) {
    const palette = [
      Color(0xFF2C3E50), // Navy
      Color(0xFF8B0000), // Crimson
      Color(0xFF2E4053), // Slate
      Color(0xFF1E8449), // Forest Green
      Color(0xFF6C3483), // Royal Purple
      Color(0xFF935116), // Leather Brown
      Color(0xFF1F618D), // Ocean Blue
      Color(0xFF78281F), // Dark Mahogany
      Color(0xFF117A65), // Dark Teal
      Color(0xFF4A235A), // Deep Plum
    ];

    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    final color = palette[hash.abs() % palette.length];
    return ColorExtractor.fromColor(color);
  }

  /// Exports a list of [Book] entities to standard RFC-4180 CSV format.
  String exportToCsv(List<Book> books) {
    final headers = [
      'Title',
      'Authors',
      'ISBN13',
      'Page Count',
      'Format',
      'Status',
      'Rating',
      'Rating Plot',
      'Rating Characters',
      'Rating Writing',
      'Rating Pacing',
      'Series Name',
      'Series Index',
      'Date Added',
      'Last Read Page',
    ];

    final rows = <List<dynamic>>[headers];

    for (final book in books) {
      final dateAddedStr = DateTime.fromMillisecondsSinceEpoch(book.createdAt)
          .toIso8601String()
          .split('T')
          .first;

      rows.add([
        book.title,
        Formatters.formatAuthors(book.authors),
        book.isbn13 ?? '',
        book.pageCount,
        book.format,
        book.status,
        book.rating ?? '',
        book.ratingPlot ?? '',
        book.ratingCharacters ?? '',
        book.ratingWriting ?? '',
        book.ratingPacing ?? '',
        book.seriesName ?? '',
        book.seriesIndex ?? '',
        dateAddedStr,
        book.lastReadPage,
      ]);
    }

    const converter = ListToCsvConverter(eol: '\n');
    return converter.convert(rows);
  }
}

class _SeriesParseResult {
  final String cleanTitle;
  final String? seriesName;
  final double? seriesIndex;

  _SeriesParseResult({
    required this.cleanTitle,
    this.seriesName,
    this.seriesIndex,
  });
}

final csvImportServiceProvider = Provider<CsvImportService>((ref) {
  return CsvImportService();
});
