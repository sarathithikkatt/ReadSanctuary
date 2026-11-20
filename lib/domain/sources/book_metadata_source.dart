import '../entities/book_metadata.dart';

/// Pluggable contract for remote book metadata providers, inspired by Mihon's source-api.
/// Implementations must not depend on Flutter widgets or Drift.
abstract class BookMetadataSource {
  /// Unique machine identifier (e.g. 'google_books', 'open_library', 'gutendex').
  String get sourceId;

  /// User-facing display name.
  String get displayName;

  /// Priority in fallback chains (lower integer = tried first).
  int get priority;

  /// Searches books by free text query or keywords.
  Future<List<BookMetadata>> searchByQuery(String query, {int limit = 20});

  /// Fetches rich metadata by ISBN-10 or ISBN-13.
  Future<BookMetadata?> fetchByIsbn(String isbn);
}
