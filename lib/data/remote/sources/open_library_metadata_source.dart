import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/book_metadata.dart';
import '../../../domain/sources/book_metadata_source.dart';
import '../open_library_api.dart';

/// Concrete BookMetadataSource using Open Library (Internet Archive) API.
class OpenLibraryMetadataSource implements BookMetadataSource {
  final OpenLibraryApi _api;

  OpenLibraryMetadataSource({OpenLibraryApi? api})
      : _api = api ?? OpenLibraryApi();

  @override
  String get sourceId => 'open_library';

  @override
  String get displayName => 'Open Library';

  @override
  int get priority => 20;

  @override
  Future<BookMetadata?> fetchByIsbn(String isbn) async {
    try {
      return await _api.getByIsbn(isbn);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const RateLimitFailure('Open Library rate limit exceeded (HTTP 429)');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure('Open Library connection timed out: ${e.message}', e);
      }
      throw ServerFailure('Open Library HTTP error: ${e.response?.statusCode}',
          e.response?.statusCode, e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Unexpected error from Open Library: $e', null, e);
    }
  }

  @override
  Future<List<BookMetadata>> searchByQuery(String query, {int limit = 20}) async {
    try {
      final results = await _api.search(query);
      if (results.length > limit) {
        return results.sublist(0, limit);
      }
      return results;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const RateLimitFailure('Open Library rate limit exceeded (HTTP 429)');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure('Open Library connection timed out: ${e.message}', e);
      }
      throw ServerFailure('Open Library HTTP error: ${e.response?.statusCode}',
          e.response?.statusCode, e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Unexpected error from Open Library: $e', null, e);
    }
  }
}
