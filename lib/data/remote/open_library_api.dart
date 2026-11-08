import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book_metadata.dart';

class OpenLibraryApi {
  final Dio _dio;

  OpenLibraryApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'User-Agent': 'ReadSanctuary/1.0 (bookshelf-app)',
                },
              ),
            );

  /// Cleans ISBN string by removing hyphens and spaces.
  static String cleanIsbn(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
  }

  /// Builds a high-resolution cover image URL given an OpenLibrary cover ID.
  static String coverUrlFromId(int coverId) {
    return 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
  }

  /// Lookup book by ISBN using OpenLibrary ISBN endpoint, falling back to search if needed.
  Future<BookMetadata?> getByIsbn(String rawIsbn) async {
    final isbn = cleanIsbn(rawIsbn);
    if (isbn.isEmpty) return null;

    try {
      final response =
          await _dio.get('https://openlibrary.org/isbn/$isbn.json');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return _parseIsbnResponse(data, isbn);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        // Non-404 error, try search fallback
      }
    } catch (_) {}

    // Fallback: search by ISBN
    final searchResults = await search('isbn:$isbn');
    return searchResults.isNotEmpty ? searchResults.first : null;
  }

  /// Search books by free text query or ISBN via OpenLibrary search endpoint.
  Future<List<BookMetadata>> search(String query) async {
    try {
      final response = await _dio.get(
        'https://openlibrary.org/search.json',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final docs = (data['docs'] as List<dynamic>?) ?? [];
        return docs
            .whereType<Map<String, dynamic>>()
            .map(_parseSearchDoc)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  BookMetadata _parseIsbnResponse(
      Map<String, dynamic> data, String fallbackIsbn) {
    final title = data['title']?.toString() ?? 'Unknown Title';
    final subtitle = data['subtitle']?.toString();

    // Pages
    int? pageCount;
    if (data['number_of_pages'] is int) {
      pageCount = data['number_of_pages'] as int;
    } else if (data['pagination'] != null) {
      final match = RegExp(r'\d+').firstMatch(data['pagination'].toString());
      if (match != null) {
        pageCount = int.tryParse(match.group(0)!);
      }
    }

    // Cover
    String? coverUrl;
    if (data['covers'] is List && (data['covers'] as List).isNotEmpty) {
      final firstCover = (data['covers'] as List).first;
      if (firstCover is int && firstCover > 0) {
        coverUrl = coverUrlFromId(firstCover);
      }
    }

    // Authors
    final authors = <String>[];
    if (data['authors'] is List) {
      for (final a in data['authors']) {
        if (a is Map && a['name'] != null) {
          authors.add(a['name'].toString());
        }
      }
    }

    // ISBN-13
    String? isbn13;
    if (data['isbn_13'] is List && (data['isbn_13'] as List).isNotEmpty) {
      isbn13 = (data['isbn_13'] as List).first.toString();
    } else if (fallbackIsbn.length == 13) {
      isbn13 = fallbackIsbn;
    }

    // Publishers
    String? publisher;
    if (data['publishers'] is List && (data['publishers'] as List).isNotEmpty) {
      publisher = (data['publishers'] as List).first.toString();
    }

    // Physical format
    String format = 'paperback';
    final physicalFormat =
        data['physical_format']?.toString().toLowerCase() ?? '';
    if (physicalFormat.contains('hardcover')) {
      format = 'hardcover';
    } else if (physicalFormat.contains('ebook') ||
        physicalFormat.contains('electronic')) {
      format = 'ebook';
    } else if (physicalFormat.contains('audio')) {
      format = 'audiobook';
    }

    return BookMetadata(
      isbn13: isbn13 ?? (fallbackIsbn.isNotEmpty ? fallbackIsbn : null),
      title: title,
      subtitle: subtitle,
      authors: authors,
      pageCount: pageCount,
      coverUrl: coverUrl,
      publisher: publisher,
      publishYear: data['publish_date']?.toString(),
      format: format,
    );
  }

  BookMetadata _parseSearchDoc(Map<String, dynamic> doc) {
    final title = doc['title']?.toString() ?? 'Unknown Title';
    final subtitle = doc['subtitle']?.toString();

    // Authors
    final authors = <String>[];
    if (doc['author_name'] is List) {
      authors.addAll((doc['author_name'] as List).map((e) => e.toString()));
    }

    // Page count
    int? pageCount;
    if (doc['number_of_pages_median'] is int) {
      pageCount = doc['number_of_pages_median'] as int;
    } else if (doc['number_of_pages'] is int) {
      pageCount = doc['number_of_pages'] as int;
    }

    // Cover
    String? coverUrl;
    if (doc['cover_i'] is int && (doc['cover_i'] as int) > 0) {
      coverUrl = coverUrlFromId(doc['cover_i'] as int);
    }

    // ISBN-13
    String? isbn13;
    if (doc['isbn'] is List) {
      final isbns = (doc['isbn'] as List).map((e) => e.toString()).toList();
      isbn13 = isbns.firstWhere(
        (id) => id.length == 13 && id.startsWith('97'),
        orElse: () => isbns.isNotEmpty ? isbns.first : '',
      );
      if (isbn13.isEmpty) isbn13 = null;
    }

    // Publisher
    String? publisher;
    if (doc['publisher'] is List && (doc['publisher'] as List).isNotEmpty) {
      publisher = (doc['publisher'] as List).first.toString();
    }

    return BookMetadata(
      isbn13: isbn13,
      title: title,
      subtitle: subtitle,
      authors: authors,
      pageCount: pageCount,
      coverUrl: coverUrl,
      publisher: publisher,
      publishYear: doc['first_publish_year']?.toString(),
    );
  }
}

final openLibraryApiProvider = Provider<OpenLibraryApi>((ref) {
  return OpenLibraryApi();
});
