import 'dart:async';
import '../../domain/entities/book_entity.dart';
import '../../domain/repositories/book_repository.dart';
import '../local/daos/book_dao.dart';
import '../local/mappers/entity_mappers.dart';

/// Concrete BookRepository delegating to Drift BookDao with FTS5 search support.
class BookRepositoryImpl implements BookRepository {
  final BookDao _bookDao;

  BookRepositoryImpl({required BookDao bookDao}) : _bookDao = bookDao;

  @override
  Stream<List<BookEntity>> watchAllBooks({bool includeDeleted = false}) {
    return _bookDao
        .watchAllBooks(includeDeleted: includeDeleted)
        .map((books) => books.map((b) => b.toEntity()).toList());
  }

  @override
  Stream<BookEntity?> watchBookById(String id) {
    return _bookDao.watchBookById(id).map((b) => b?.toEntity());
  }

  @override
  Future<BookEntity?> getBookById(String id) async {
    final book = await _bookDao.getBookById(id);
    return book?.toEntity();
  }

  @override
  Future<BookEntity?> getBookByIsbn(String isbn) async {
    final all = await _bookDao.getAllBooks();
    final match = all.where((b) => b.isbn13 == isbn).firstOrNull;
    return match?.toEntity();
  }

  @override
  Future<List<BookEntity>> searchBooks(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final ftsResults = await _bookDao.searchBooksFts(clean);
      if (ftsResults.isNotEmpty) {
        return ftsResults.map((b) => b.toEntity()).toList();
      }
    } catch (_) {}

    // Fallback to substring matching if FTS query is empty or failed
    final all = await _bookDao.getAllBooks();
    final lower = clean.toLowerCase();
    return all
        .map((b) => b.toEntity())
        .where((b) =>
            b.title.toLowerCase().contains(lower) ||
            b.authors.any((a) => a.toLowerCase().contains(lower)) ||
            (b.description?.toLowerCase().contains(lower) ?? false))
        .toList();
  }

  @override
  Future<void> upsertBook(BookEntity book) async {
    await _bookDao.upsertBook(book.toCompanion());
  }

  @override
  Future<void> updateProgress(String bookId, int currentPage,
      {String? status}) async {
    await _bookDao.updateBookLastReadPage(bookId, currentPage);
    if (status != null) {
      final current = await _bookDao.getBookById(bookId);
      if (current != null) {
        await _bookDao.updateBook(
          current.copyWith(
            status: status,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    }
  }

  @override
  Future<void> deleteBook(String bookId, {bool softDelete = true}) async {
    if (softDelete) {
      await _bookDao.softDeleteBook(bookId);
    } else {
      await _bookDao.deleteBook(bookId);
    }
  }
}
