import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book_metadata.dart';

class GoogleBooksApi {
  final Dio _dio;

  GoogleBooksApi({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Cleans ISBN string by removing hyphens and spaces.
  static String cleanIsbn(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
  }

  /// Lookup book by ISBN using Google Books API.
  Future<BookMetadata?> getByIsbn(String rawIsbn) async {
    final isbn = cleanIsbn(rawIsbn);
    if (isbn.isEmpty) return null;

    try {
      final response = await _dio.get(
        'https://www.googleapis.com/books/v1/volumes',
        queryParameters: {'q': 'isbn:$isbn'},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          return _parseVolumeItem(items.first as Map<String, dynamic>, fallbackIsbn: isbn);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Search books by free text query or keywords.
  Future<List<BookMetadata>> search(String query, {int maxResults = 20}) async {
    try {
      final response = await _dio.get(
        'https://www.googleapis.com/books/v1/volumes',
        queryParameters: {
          'q': query,
          'maxResults': maxResults,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items
            .whereType<Map<String, dynamic>>()
            .map((item) => _parseVolumeItem(item))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  BookMetadata _parseVolumeItem(Map<String, dynamic> item, {String? fallbackIsbn}) {
    final volumeInfo = (item['volumeInfo'] as Map<String, dynamic>?) ?? {};
    final title = volumeInfo['title']?.toString() ?? 'Unknown Title';
    final subtitle = volumeInfo['subtitle']?.toString();

    // Authors
    final authors = <String>[];
    if (volumeInfo['authors'] is List) {
      authors.addAll((volumeInfo['authors'] as List).map((e) => e.toString()));
    }

    // Page count
    int? pageCount;
    if (volumeInfo['pageCount'] is int) {
      pageCount = volumeInfo['pageCount'] as int;
    }

    // Cover image: upgrade http to https for transport security
    String? coverUrl;
    if (volumeInfo['imageLinks'] is Map) {
      final images = volumeInfo['imageLinks'] as Map<String, dynamic>;
      final rawUrl = images['thumbnail']?.toString() ?? images['smallThumbnail']?.toString();
      if (rawUrl != null) {
        coverUrl = rawUrl.replaceFirst('http://', 'https://');
      }
    }

    // ISBN-13
    String? isbn13;
    if (volumeInfo['industryIdentifiers'] is List) {
      for (final id in volumeInfo['industryIdentifiers']) {
        if (id is Map && id['type'] == 'ISBN_13') {
          isbn13 = id['identifier']?.toString();
          break;
        }
      }
    }
    isbn13 ??= fallbackIsbn;

    return BookMetadata(
      isbn13: isbn13,
      title: title,
      subtitle: subtitle,
      authors: authors,
      pageCount: pageCount,
      coverUrl: coverUrl,
      publisher: volumeInfo['publisher']?.toString(),
      publishYear: volumeInfo['publishedDate']?.toString(),
      description: volumeInfo['description']?.toString(),
    );
  }
}

final googleBooksApiProvider = Provider<GoogleBooksApi>((ref) {
  return GoogleBooksApi();
});
