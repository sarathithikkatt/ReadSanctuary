import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/book_metadata.dart';
import '../../../domain/sources/book_metadata_source.dart';
import '../google_books_api.dart';

/// Concrete BookMetadataSource using Google Books API.
class GoogleBooksMetadataSource implements BookMetadataSource {
  final GoogleBooksApi _api;

  GoogleBooksMetadataSource({GoogleBooksApi? api})
      : _api = api ?? GoogleBooksApi();

  @override
  String get sourceId => 'google_books';

  @override
  String get displayName => 'Google Books';

  @override
  int get priority => 10;

  @override
  Future<BookMetadata?> fetchByIsbn(String isbn) async {
    try {
      return await _api.getByIsbn(isbn);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const RateLimitFailure('Google Books rate limit exceeded (HTTP 429)');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure('Google Books connection timed out: ${e.message}', e);
      }
      throw ServerFailure('Google Books HTTP error: ${e.response?.statusCode}',
          e.response?.statusCode, e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Unexpected error from Google Books: $e', null, e);
    }
  }

  @override
  Future<List<BookMetadata>> searchByQuery(String query, {int limit = 20}) async {
    try {
      return await _api.search(query, maxResults: limit);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const RateLimitFailure('Google Books rate limit exceeded (HTTP 429)');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure('Google Books connection timed out: ${e.message}', e);
      }
      throw ServerFailure('Google Books HTTP error: ${e.response?.statusCode}',
          e.response?.statusCode, e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Unexpected error from Google Books: $e', null, e);
    }
  }
}
