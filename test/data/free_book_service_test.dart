import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readsanctuary/core/utils/image_storage_helper.dart';
import 'package:readsanctuary/data/remote/free_book_service.dart';

class MockAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('FreeBookService Tests', () {
    late Directory tempDir;
    late ImageStorageHelper storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('shelfcraft_free_books_');
      storage = ImageStorageHelper(baseDirProvider: () async => tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('searchFreeBooks parses OpenLibrary full-text and Gutendex books', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapter((options) {
        if (options.path.contains('openlibrary.org/search.json')) {
          return ResponseBody.fromString(
            jsonEncode({
              'docs': [
                {
                  'title': 'Pride and Prejudice',
                  'author_name': ['Jane Austen'],
                  'first_publish_year': 1813,
                  'number_of_pages_median': 350,
                  'has_fulltext': true,
                  'public_scan_b': true,
                  'ia': ['prideprejudice00austuoft'],
                  'cover_i': 123456,
                }
              ]
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        } else if (options.path.contains('gutendex.com/books')) {
          return ResponseBody.fromString(
            jsonEncode({
              'results': [
                {
                  'id': 1342,
                  'title': 'Pride and Prejudice',
                  'authors': [
                    {'name': 'Austen, Jane'}
                  ],
                  'formats': {
                    'application/pdf': 'https://www.gutenberg.org/files/1342/1342-pdf.pdf',
                    'image/jpeg': 'https://www.gutenberg.org/cover.jpg',
                  }
                }
              ]
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString('{}', 200);
      });

      final service = FreeBookService(dio: dio, imageStorageHelper: storage);
      final results = await service.searchFreeBooks('Pride and Prejudice');

      expect(results.length, 2);

      // OpenLibrary result
      final olBook = results[0];
      expect(olBook.title, 'Pride and Prejudice');
      expect(olBook.authors, ['Jane Austen']);
      expect(olBook.freePdfUrl, 'https://archive.org/download/prideprejudice00austuoft/prideprejudice00austuoft.pdf');
      expect(olBook.source, 'Internet Archive');

      // Gutenberg result
      final gbBook = results[1];
      expect(gbBook.title, 'Pride and Prejudice');
      expect(gbBook.authors, ['Jane Austen']); // Formatted from "Austen, Jane"
      expect(gbBook.freePdfUrl, 'https://www.gutenberg.org/files/1342/1342-pdf.pdf');
      expect(gbBook.source, 'Project Gutenberg');
    });

    test('findFreePdfForBook returns matching download URL', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapter((options) {
        if (options.path.contains('openlibrary.org/search.json')) {
          return ResponseBody.fromString(
            jsonEncode({
              'docs': [
                {
                  'title': 'Frankenstein',
                  'author_name': ['Mary Shelley'],
                  'has_fulltext': true,
                  'ia': ['frankenstein00shelley'],
                }
              ]
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString(jsonEncode({'results': []}), 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
      });

      final service = FreeBookService(dio: dio, imageStorageHelper: storage);
      final pdfUrl = await service.findFreePdfForBook('Frankenstein', author: 'Mary Shelley');

      expect(pdfUrl, 'https://archive.org/download/frankenstein00shelley/frankenstein00shelley.pdf');
    });

    test('getGutenbergBookById fetches formats and extracts plain text / epub download URL', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapter((options) {
        if (options.path.contains('/books/1342/')) {
          return ResponseBody.fromString(
            jsonEncode({
              'id': 1342,
              'title': 'Pride and Prejudice',
              'authors': [
                {'name': 'Austen, Jane', 'birth_year': 1775, 'death_year': 1817}
              ],
              'formats': {
                'text/html': 'https://www.gutenberg.org/ebooks/1342.html.images',
                'application/epub+zip': 'https://www.gutenberg.org/ebooks/1342.epub3.images',
                'image/jpeg': 'https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg',
                'text/plain; charset=us-ascii': 'https://www.gutenberg.org/ebooks/1342.txt.utf-8',
              }
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      });

      final service = FreeBookService(dio: dio, imageStorageHelper: storage);
      
      // Default prioritization (EPUB over plain text)
      final book = await service.getGutenbergBookById(1342);
      expect(book, isNotNull);
      expect(book!.title, 'Pride and Prejudice');
      expect(book.authors, ['Jane Austen']);
      expect(book.freePdfUrl, 'https://www.gutenberg.org/ebooks/1342.epub3.images');
      expect(book.coverUrl, 'https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg');

      // Specific MIME format extraction (matching user's python request: 'text/plain; charset=us-ascii')
      final textBook = await service.getGutenbergBookById(
        1342,
        preferredFormat: 'text/plain; charset=us-ascii',
      );
      expect(textBook, isNotNull);
      expect(textBook!.freePdfUrl, 'https://www.gutenberg.org/ebooks/1342.txt.utf-8');
    });
  });
}
