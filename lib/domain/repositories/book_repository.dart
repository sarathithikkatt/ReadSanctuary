import '../entities/book_entity.dart';

/// Abstract repository interface for Book operations.
/// Follows Clean Architecture: pure Dart contract with zero Flutter/Drift imports.
abstract class BookRepository {
  /// Watches all active books as a reactive stream.
  Stream<List<BookEntity>> watchAllBooks({bool includeDeleted = false});

  /// Watches a single book by its UUID.
  Stream<BookEntity?> watchBookById(String id);

  /// Retrieves a single book by UUID once.
  Future<BookEntity?> getBookById(String id);

  /// Retrieves a book by ISBN-13 once.
  Future<BookEntity?> getBookByIsbn(String isbn);

  /// Searches books by title, author, or description.
  Future<List<BookEntity>> searchBooks(String query);

  /// Inserts or updates a book entity.
  Future<void> upsertBook(BookEntity book);

  /// Updates page progress and optionally status.
  Future<void> updateProgress(String bookId, int currentPage, {String? status});

  /// Deletes a book (defaults to soft-delete if supported).
  Future<void> deleteBook(String bookId, {bool softDelete = true});
}
