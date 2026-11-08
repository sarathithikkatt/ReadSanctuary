import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/image_storage_helper.dart';
import '../../domain/models/book_metadata.dart';
import 'open_library_api.dart';

/// Service responsible for finding, fetching, and downloading free public domain books
/// and open-access PDFs from Project Gutenberg, Internet Archive, OpenLibrary, and Google Books.
class FreeBookService {
  final Dio _dio;
  final ImageStorageHelper _imageStorageHelper;

  FreeBookService({
    Dio? dio,
    ImageStorageHelper? imageStorageHelper,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent': 'ShelfCraft/1.0 (free-books-reader)',
                },
              ),
            ),
        _imageStorageHelper = imageStorageHelper ?? ImageStorageHelper();

  /// Searches for free books and PDFs across OpenLibrary/Internet Archive and Project Gutenberg.
  Future<List<BookMetadata>> searchFreeBooks(String query, {int limit = 20}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final results = <BookMetadata>[];

    // 1. Search Open Library with Internet Archive full-text flags
    try {
      final olResponse = await _dio.get(
        'https://openlibrary.org/search.json',
        queryParameters: {
          'q': cleanQuery,
          'fields':
              'title,author_name,cover_i,ia,has_fulltext,public_scan_b,first_publish_year,number_of_pages_median,isbn',
          'limit': limit,
        },
      );

      if (olResponse.statusCode == 200 && olResponse.data is Map<String, dynamic>) {
        final docs = (olResponse.data['docs'] as List<dynamic>?) ?? [];
        for (final doc in docs.whereType<Map<String, dynamic>>()) {
          final hasFullText = doc['has_fulltext'] == true;
          final isPublicScan = doc['public_scan_b'] == true;
          final iaList = (doc['ia'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          String? freePdfUrl;
          if (iaList.isNotEmpty) {
            // Find a valid IA item ID (preferring non-isbn prefixes)
            final iaId = iaList.firstWhere(
              (id) => !id.startsWith('isbn_') && !id.startsWith('bwb_'),
              orElse: () => iaList.first,
            );
            if (hasFullText || isPublicScan || iaId.isNotEmpty) {
              freePdfUrl = 'https://archive.org/download/$iaId/$iaId.pdf';
            }
          }

          final title = doc['title']?.toString() ?? 'Unknown Title';
          final authors = (doc['author_name'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          String? coverUrl;
          if (doc['cover_i'] is int && (doc['cover_i'] as int) > 0) {
            coverUrl = OpenLibraryApi.coverUrlFromId(doc['cover_i'] as int);
          }

          results.add(
            BookMetadata(
              title: title,
              authors: authors,
              publishYear: doc['first_publish_year']?.toString(),
              pageCount: doc['number_of_pages_median'] as int?,
              coverUrl: coverUrl,
              freePdfUrl: freePdfUrl,
              source: freePdfUrl != null ? 'Internet Archive' : 'OpenLibrary',
              format: 'ebook',
            ),
          );
        }
      }
    } catch (_) {}

    // 2. Search Project Gutenberg via Gutendex
    try {
      final gbResponse = await _dio.get(
        'https://gutendex.com/books/',
        queryParameters: {'search': cleanQuery},
      );

      if (gbResponse.statusCode == 200 && gbResponse.data is Map<String, dynamic>) {
        final gutenbergList = (gbResponse.data['results'] as List<dynamic>?) ?? [];
        for (final item in gutenbergList.whereType<Map<String, dynamic>>()) {
          final title = item['title']?.toString() ?? 'Unknown';
          final authors = (item['authors'] as List<dynamic>?)
                  ?.map((a) => (a is Map && a['name'] != null)
                      ? _formatGutenbergAuthor(a['name'].toString())
                      : '')
                  .where((a) => a.isNotEmpty)
                  .toList() ??
              [];

          final formats = (item['formats'] as Map<String, dynamic>?) ?? {};
          final coverUrl = formats['image/jpeg']?.toString();
          final downloadUrl = extractGutenbergFormatUrl(formats);

          results.add(
            BookMetadata(
              title: title,
              authors: authors,
              coverUrl: coverUrl,
              freePdfUrl: downloadUrl,
              source: 'Project Gutenberg',
              format: 'ebook',
            ),
          );
        }
      }
    } catch (_) {}

    return results;
  }

  /// Looks up a specific book on Project Gutenberg via Gutendex by its ID.
  /// Extracts the download URL for the requested MIME type format (e.g. 'text/plain; charset=us-ascii',
  /// 'application/epub+zip', 'application/pdf'), or chooses the best available format.
  Future<BookMetadata?> getGutenbergBookById(
    int bookId, {
    String? preferredFormat,
  }) async {
    try {
      final response = await _dio.get('https://gutendex.com/books/$bookId/');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final item = response.data as Map<String, dynamic>;
        final title = item['title']?.toString() ?? 'Unknown';
        final authors = (item['authors'] as List<dynamic>?)
                ?.map((a) => (a is Map && a['name'] != null)
                    ? _formatGutenbergAuthor(a['name'].toString())
                    : '')
                .where((a) => a.isNotEmpty)
                .toList() ??
            [];
        final formats = (item['formats'] as Map<String, dynamic>?) ?? {};
        final coverUrl = formats['image/jpeg']?.toString();
        final downloadUrl = extractGutenbergFormatUrl(
          formats,
          preferredMimeType: preferredFormat,
        );

        return BookMetadata(
          title: title,
          authors: authors,
          coverUrl: coverUrl,
          freePdfUrl: downloadUrl,
          source: 'Project Gutenberg',
          format: 'ebook',
        );
      }
    } catch (_) {}
    return null;
  }

  /// Extracts the best downloadable file URL from Gutendex's formats map.
  /// Handles EPUB, UTF-8/US-ASCII plain text, PDF, and HTML formats.
  static String? extractGutenbergFormatUrl(
    Map<String, dynamic> formats, {
    String? preferredMimeType,
  }) {
    if (preferredMimeType != null) {
      if (formats[preferredMimeType] != null && formats[preferredMimeType].toString().isNotEmpty) {
        return formats[preferredMimeType].toString();
      }
      // Fuzzy/prefix match: e.g. 'text/plain; charset=us-ascii' or 'text/plain' matches 'text/plain; charset=utf-8'
      final baseType = preferredMimeType.split(';').first.trim().toLowerCase();
      for (final entry in formats.entries) {
        final entryBase = entry.key.split(';').first.trim().toLowerCase();
        if (entryBase == baseType && entry.value != null && entry.value.toString().isNotEmpty) {
          return entry.value.toString();
        }
      }
    }

    // Default priority: PDF -> EPUB -> Plain text UTF-8 -> Plain text US-ASCII -> General text -> HTML
    final prioritizedKeys = [
      'application/pdf',
      'application/epub+zip',
      'text/plain; charset=utf-8',
      'text/plain; charset=us-ascii',
      'text/plain',
      'text/html',
    ];

    for (final key in prioritizedKeys) {
      if (formats[key] != null && formats[key].toString().isNotEmpty) {
        return formats[key].toString();
      }
    }

    for (final entry in formats.entries) {
      if (entry.key.startsWith('text/plain') && entry.value != null) {
        return entry.value.toString();
      }
    }

    return null;
  }

  /// Searches specifically for an available free PDF for an existing book by title and author.
  Future<String?> findFreePdfForBook(String title, {String? author}) async {
    final query = author != null && author.isNotEmpty ? '$title $author' : title;
    final results = await searchFreeBooks(query, limit: 8);

    for (final book in results) {
      if (book.freePdfUrl != null && book.freePdfUrl!.isNotEmpty) {
        // Basic fuzzy title match
        if (book.title.toLowerCase().contains(title.toLowerCase().trim()) ||
            title.toLowerCase().contains(book.title.toLowerCase().trim())) {
          return book.freePdfUrl;
        }
      }
    }

    // If no exact match, return first available if results exist
    final firstWithPdf = results.firstWhere(
      (b) => b.freePdfUrl != null && b.freePdfUrl!.isNotEmpty,
      orElse: () => const BookMetadata(title: ''),
    );

    return firstWithPdf.freePdfUrl;
  }

  /// Downloads a remote PDF and saves it locally in `<AppDocuments>/media/pdfs/{bookId}.pdf`.
  /// Returns the relative path e.g. `'pdfs/{bookId}.pdf'`.
  Future<String> downloadAndSavePdf(
    String url,
    String bookId, {
    void Function(int count, int total)? onProgress,
  }) async {
    return await _imageStorageHelper.downloadAndSavePdf(
      url,
      filename: '$bookId.pdf',
      onProgress: onProgress,
    );
  }

  static String _formatGutenbergAuthor(String raw) {
    // Converts "Austen, Jane" to "Jane Austen"
    final parts = raw.split(',');
    if (parts.length >= 2) {
      return '${parts[1].trim()} ${parts[0].trim()}';
    }
    return raw.trim();
  }
}

final freeBookServiceProvider = Provider<FreeBookService>((ref) {
  return FreeBookService(
    imageStorageHelper: ref.watch(imageStorageHelperProvider),
  );
});
