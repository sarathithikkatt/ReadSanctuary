import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book_metadata.dart';
import 'google_books_api.dart';
import 'open_library_api.dart';

/// Unified service providing dual-API book lookup with Google Books as primary metadata source
/// and OpenLibrary (Internet Archive) as automatic enrichment/fallback.
class BookLookupService {
  final GoogleBooksApi _googleBooksApi;
  final OpenLibraryApi _openLibraryApi;

  BookLookupService({
    GoogleBooksApi? googleBooksApi,
    OpenLibraryApi? openLibraryApi,
  })  : _googleBooksApi = googleBooksApi ?? GoogleBooksApi(),
        _openLibraryApi = openLibraryApi ?? OpenLibraryApi();

  /// Looks up a book by ISBN-10 or ISBN-13.
  /// Queries Google Books API first for rich metadata (descriptions, covers, page counts).
  /// If missing key fields or not found, enriches / falls back to OpenLibrary.
  Future<BookMetadata?> lookupByIsbn(String rawIsbn) async {
    final clean = GoogleBooksApi.cleanIsbn(rawIsbn);
    if (clean.isEmpty) return null;

    BookMetadata? gbResult;
    try {
      gbResult = await _googleBooksApi.getByIsbn(clean);
    } catch (_) {}

    // If Google Books completely failed or returned null, try OpenLibrary
    if (gbResult == null) {
      try {
        return await _openLibraryApi.getByIsbn(clean);
      } catch (_) {
        return null;
      }
    }

    // Check if enrichment is required (missing pageCount, coverUrl, or authors)
    final needsEnrichment = gbResult.pageCount == null ||
        gbResult.coverUrl == null ||
        gbResult.authors.isEmpty;

    if (needsEnrichment) {
      try {
        final olResult = await _openLibraryApi.getByIsbn(clean);
        if (olResult != null) {
          return gbResult.copyWith(
            title: gbResult.title.isNotEmpty ? gbResult.title : olResult.title,
            subtitle: gbResult.subtitle ?? olResult.subtitle,
            authors: gbResult.authors.isNotEmpty
                ? gbResult.authors
                : olResult.authors,
            pageCount: gbResult.pageCount ?? olResult.pageCount,
            coverUrl: gbResult.coverUrl ?? olResult.coverUrl,
            publisher: gbResult.publisher ?? olResult.publisher,
            publishYear: gbResult.publishYear ?? olResult.publishYear,
            description: gbResult.description ?? olResult.description,
            isbn13: gbResult.isbn13 ?? olResult.isbn13,
          );
        }
      } catch (_) {}
    }

    return gbResult;
  }

  /// Searches books by keywords/title/author.
  /// First checks Google Books for rich metadata, falling back to OpenLibrary if no results.
  Future<List<BookMetadata>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final gbResults = await _googleBooksApi.search(query);
      if (gbResults.isNotEmpty) {
        return gbResults;
      }
    } catch (_) {}

    try {
      return await _openLibraryApi.search(query);
    } catch (_) {
      return [];
    }
  }
}

final bookLookupServiceProvider = Provider<BookLookupService>((ref) {
  return BookLookupService(
    googleBooksApi: ref.watch(googleBooksApiProvider),
    openLibraryApi: ref.watch(openLibraryApiProvider),
  );
});
