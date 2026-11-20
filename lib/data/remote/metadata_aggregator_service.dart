import 'dart:async';
import '../../domain/entities/book_metadata.dart';
import '../../domain/sources/book_metadata_source.dart';
import 'google_books_api.dart';

/// Aggregator service inspired by Mihon's source fallback and catalogue resolution.
/// Queries sources in priority order and falls back gracefully on timeout, rate-limit (429),
/// or empty/error results. Optionally enriches partial results from secondary providers.
class MetadataAggregatorService {
  final List<BookMetadataSource> _sources;

  MetadataAggregatorService({required List<BookMetadataSource> sources})
      : _sources = List<BookMetadataSource>.from(sources)
          ..sort((a, b) => a.priority.compareTo(b.priority));

  /// Unmodifiable view of registered sources in priority order.
  List<BookMetadataSource> get sources => List.unmodifiable(_sources);

  /// Cleans and sanitizes raw ISBN input.
  static String cleanIsbn(String raw) => GoogleBooksApi.cleanIsbn(raw);

  /// Looks up a book by ISBN with automatic fallback and optional secondary enrichment.
  Future<BookMetadata?> lookupByIsbn(
    String rawIsbn, {
    bool enrich = true,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final isbn = cleanIsbn(rawIsbn);
    if (isbn.isEmpty) return null;

    BookMetadata? primaryResult;
    int primaryIndex = -1;

    for (int i = 0; i < _sources.length; i++) {
      final source = _sources[i];
      try {
        final result = await source.fetchByIsbn(isbn).timeout(timeout);
        if (result != null) {
          primaryResult = result;
          primaryIndex = i;
          break;
        }
      } catch (_) {
        // Fall back gracefully on error, timeout, or rate-limit
        continue;
      }
    }

    if (primaryResult == null) return null;

    var current = primaryResult;

    // Check if enrichment is enabled and needed
    final needsEnrichment = enrich &&
        (current.pageCount == null ||
            current.coverUrl == null ||
            current.authors.isEmpty ||
            current.description == null);

    if (needsEnrichment && primaryIndex + 1 < _sources.length) {
      for (int i = primaryIndex + 1; i < _sources.length; i++) {
        final secondarySource = _sources[i];
        try {
          final secondary =
              await secondarySource.fetchByIsbn(isbn).timeout(timeout);
          if (secondary != null) {
            current = current.copyWith(
              title:
                  current.title.isNotEmpty ? current.title : secondary.title,
              subtitle: current.subtitle ?? secondary.subtitle,
              authors: current.authors.isNotEmpty
                  ? current.authors
                  : secondary.authors,
              pageCount: current.pageCount ?? secondary.pageCount,
              coverUrl: current.coverUrl ?? secondary.coverUrl,
              publisher: current.publisher ?? secondary.publisher,
              publishYear: current.publishYear ?? secondary.publishYear,
              description: current.description ?? secondary.description,
              isbn13: current.isbn13 ?? secondary.isbn13,
            );
          }
        } catch (_) {
          continue;
        }
      }
    }

    return current;
  }

  /// Searches books by free text query across sources by priority.
  Future<List<BookMetadata>> search(
    String query, {
    int limit = 20,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (query.trim().isEmpty) return [];

    for (final source in _sources) {
      try {
        final results = await source
            .searchByQuery(query, limit: limit)
            .timeout(timeout);
        if (results.isNotEmpty) {
          return results;
        }
      } catch (_) {
        // Fall back gracefully to next source
        continue;
      }
    }

    return [];
  }
}
