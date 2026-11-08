import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readsanctuary/core/utils/color_extractor.dart';
import 'package:readsanctuary/data/remote/book_lookup_service.dart';
import 'package:readsanctuary/data/remote/google_books_api.dart';
import 'package:readsanctuary/data/remote/open_library_api.dart';

/// Lightweight custom HttpClientAdapter to mock Dio HTTP responses.
class MockDioAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) responseHandler;

  MockDioAdapter(this.responseHandler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return responseHandler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  const testIsbn = '9780765326355';

  group('OpenLibraryApi & GoogleBooksApi Individual Tests', () {
    test('OpenLibrary parses ISBN JSON correctly', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) {
        if (options.path.contains('/isbn/$testIsbn.json')) {
          return jsonResponse({
            'title': 'The Way of Kings',
            'subtitle': 'The Stormlight Archive #1',
            'number_of_pages': 1007,
            'covers': [823456],
            'authors': [
              {'name': 'Brandon Sanderson'}
            ],
            'publishers': ['Tor Books'],
            'publish_date': 'August 31, 2010',
            'physical_format': 'Hardcover',
          });
        }
        return ResponseBody.fromString('Not Found', 404);
      });

      final olApi = OpenLibraryApi(dio: dio);
      final metadata = await olApi.getByIsbn(testIsbn);

      expect(metadata, isNotNull);
      expect(metadata!.title, 'The Way of Kings');
      expect(metadata.subtitle, 'The Stormlight Archive #1');
      expect(metadata.pageCount, 1007);
      expect(metadata.coverUrl,
          'https://covers.openlibrary.org/b/id/823456-L.jpg');
      expect(metadata.authors, ['Brandon Sanderson']);
      expect(metadata.format, 'hardcover');
      expect(metadata.publisher, 'Tor Books');
    });

    test(
        'GoogleBooksApi parses volume item correctly and upgrades image to HTTPS',
        () async {
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) {
        return jsonResponse({
          'items': [
            {
              'volumeInfo': {
                'title': 'Project Hail Mary',
                'authors': ['Andy Weir'],
                'pageCount': 496,
                'imageLinks': {
                  'thumbnail':
                      'http://books.google.com/books/content?id=xyz&printsec=frontcover',
                },
                'industryIdentifiers': [
                  {'type': 'ISBN_13', 'identifier': testIsbn},
                ],
                'publisher': 'Ballantine Books',
                'publishedDate': '2021-05-04',
              }
            }
          ]
        });
      });

      final gbApi = GoogleBooksApi(dio: dio);
      final metadata = await gbApi.getByIsbn(testIsbn);

      expect(metadata, isNotNull);
      expect(metadata!.title, 'Project Hail Mary');
      expect(metadata.authors, ['Andy Weir']);
      expect(metadata.pageCount, 496);
      expect(metadata.coverUrl,
          'https://books.google.com/books/content?id=xyz&printsec=frontcover');
    });
  });

  group('BookLookupService - Dual API Fallback & Enrichment Tests', () {
    test(
        'Enriches missing pageCount and coverUrl from OpenLibrary when Google Books is incomplete',
        () async {
      // Google Books mock: contains title and authors, but null pageCount and no covers
      final gbDio = Dio();
      gbDio.httpClientAdapter = MockDioAdapter((options) {
        return jsonResponse({
          'items': [
            {
              'volumeInfo': {
                'title': 'The Name of the Wind',
                'authors': ['Patrick Rothfuss'],
                // Missing pageCount and imageLinks
              }
            }
          ]
        });
      });

      // OpenLibrary mock: returns pageCount and cover
      final olDio = Dio();
      olDio.httpClientAdapter = MockDioAdapter((options) {
        return jsonResponse({
          'title': 'The Name of the Wind',
          'number_of_pages': 662,
          'covers': [12345],
        });
      });

      final lookupService = BookLookupService(
        googleBooksApi: GoogleBooksApi(dio: gbDio),
        openLibraryApi: OpenLibraryApi(dio: olDio),
      );

      final result = await lookupService.lookupByIsbn(testIsbn);

      expect(result, isNotNull);
      expect(result!.title, 'The Name of the Wind');
      expect(result.authors, ['Patrick Rothfuss']);
      // Enriched from OpenLibrary
      expect(result.pageCount, 662);
      expect(result.coverUrl,
          'https://covers.openlibrary.org/b/id/12345-L.jpg');
    });

    test('Falls back to OpenLibrary entirely if Google Books returns empty/null',
        () async {
      final gbDio = Dio();
      gbDio.httpClientAdapter = MockDioAdapter((options) {
        return jsonResponse({'items': []});
      });

      final olDio = Dio();
      olDio.httpClientAdapter = MockDioAdapter((options) {
        return jsonResponse({
          'title': 'Fallback OpenLibrary Title',
          'authors': [
            {'name': 'Fallback Author'}
          ],
          'number_of_pages': 350,
          'covers': [999],
        });
      });

      final lookupService = BookLookupService(
        googleBooksApi: GoogleBooksApi(dio: gbDio),
        openLibraryApi: OpenLibraryApi(dio: olDio),
      );

      final result = await lookupService.lookupByIsbn(testIsbn);

      expect(result, isNotNull);
      expect(result!.title, 'Fallback OpenLibrary Title');
      expect(result.authors, ['Fallback Author']);
      expect(result.pageCount, 350);
      expect(result.coverUrl, 'https://covers.openlibrary.org/b/id/999-L.jpg');
    });

    test('Returns null gracefully if both APIs fail', () async {
      final olDio = Dio();
      olDio.httpClientAdapter = MockDioAdapter((options) {
        return ResponseBody.fromString('Not Found', 404);
      });

      final gbDio = Dio();
      gbDio.httpClientAdapter = MockDioAdapter((options) {
        return jsonResponse({'items': []});
      });

      final lookupService = BookLookupService(
        openLibraryApi: OpenLibraryApi(dio: olDio),
        googleBooksApi: GoogleBooksApi(dio: gbDio),
      );

      final result = await lookupService.lookupByIsbn(testIsbn);
      expect(result, isNull);
    });
  });

  group('ColorExtractor Contrast Tests', () {
    test(
        'Calculates white text for dark spine color and black87 text for light spine color',
        () {
      // Dark navy: luminance < 0.5 -> white text
      const darkColor = Color(0xFF1E3A8A);
      final darkSpine = ColorExtractor.fromColor(darkColor);
      expect(darkSpine.textColor, Colors.white);

      // Light yellow: luminance > 0.5 -> black87 text
      const lightColor = Color(0xFFFDE047);
      final lightSpine = ColorExtractor.fromColor(lightColor);
      expect(lightSpine.textColor, Colors.black87);
    });
  });
}
