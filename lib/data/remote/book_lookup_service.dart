import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book_metadata.dart';
import 'google_books_api.dart';
import 'open_library_api.dart';

/// Unified service providing dual-API book lookup with OpenLibrary as primary
/// and Google Books as automatic enrichment/fallback.
class BookLookupService {
  final OpenLibraryApi _openLibraryApi;
  final GoogleBooksApi _googleBooksApi;

  BookLookupService({
    OpenLibraryApi? openLibraryApi,
    GoogleBooksApi? googleBooksApi,
  })  : _openLibraryApi = openLibraryApi ?? OpenLibraryApi(),
        _googleBooksApi = googleBooksApi ?? GoogleBooksApi();

  /// Looks up a book by ISBN-10 or ISBN-13.
  /// Queries OpenLibrary first; if page count or cover is missing, enriches from Google Books.
  Future<BookMetadata?> lookupByIsbn(String rawIsbn) async {
    final clean = OpenLibraryApi.cleanIsbn(rawIsbn);
    if (clean.isEmpty) return null;

    BookMetadata? olResult;
    try {
      olResult = await _openLibraryApi.getByIsbn(clean);
    } catch (_) {}

    // If OpenLibrary completely failed or returned null, try Google Books
    if (olResult == null) {
      try {
        return await _googleBooksApi.getByIsbn(clean);
      } catch (_) {
        return null;
      }
    }

    // Check if enrichment is required (missing pageCount, coverUrl, or authors)
    final needsEnrichment = olResult.pageCount == null ||
        olResult.coverUrl == null ||
        olResult.authors.isEmpty;

    if (needsEnrichment) {
      try {
        final gbResult = await _googleBooksApi.getByIsbn(clean);
        if (gbResult != null) {
          return olResult.copyWith(
            title: olResult.title.isNotEmpty ? olResult.title : gbResult.title,
            subtitle: olResult.subtitle ?? gbResult.subtitle,
            authors: olResult.authors.isNotEmpty ? olResult.authors : gbResult.authors,
            pageCount: olResult.pageCount ?? gbResult.pageCount,
            coverUrl: olResult.coverUrl ?? gbResult.coverUrl,
            publisher: olResult.publisher ?? gbResult.publisher,
            publishYear: olResult.publishYear ?? gbResult.publishYear,
            description: olResult.description ?? gbResult.description,
            isbn13: olResult.isbn13 ?? gbResult.isbn13,
          );
        }
      } catch (_) {}
    }

    return olResult;
  }

  /// Searches books by keywords/title/author.
  /// First checks OpenLibrary, falling back to Google Books if no results.
  Future<List<BookMetadata>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final olResults = await _openLibraryApi.search(query);
      if (olResults.isNotEmpty) {
        return olResults;
      }
    } catch (_) {}

    try {
      return await _googleBooksApi.search(query);
    } catch (_) {
      return [];
    }
  }
}

final bookLookupServiceProvider = Provider<BookLookupService>((ref) {
  return BookLookupService(
    openLibraryApi: ref.watch(openLibraryApiProvider),
    googleBooksApi: ref.watch(googleBooksApiProvider),
  );
});
