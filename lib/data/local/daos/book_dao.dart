import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/books.dart';

part 'book_dao.g.dart';

@DriftAccessor(tables: [Books])
class BookDao extends DatabaseAccessor<AppDatabase> with _$BookDaoMixin {
  BookDao(super.db);

  Stream<List<Book>> watchAllBooks({bool includeDeleted = false}) {
    return (select(books)
          ..where((t) => includeDeleted ? const Constant(true) : t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.title, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Future<List<Book>> getAllBooks({bool includeDeleted = false}) {
    return (select(books)
          ..where((t) => includeDeleted ? const Constant(true) : t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.title, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Stream<Book?> watchBookById(String id) {
    return (select(books)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<Book?> getBookById(String id) {
    return (select(books)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<Book>> watchBooksBySeries(String seriesName) {
    return (select(books)
          ..where((t) =>
              t.seriesName.equals(seriesName) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.seriesIndex,
                  mode: OrderingMode.asc,
                  nulls: NullsOrder.last,
                ),
          ]))
        .watch();
  }

  Future<List<Book>> getBooksBySeries(String seriesName) {
    return (select(books)
          ..where((t) =>
              t.seriesName.equals(seriesName) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.seriesIndex,
                  mode: OrderingMode.asc,
                  nulls: NullsOrder.last,
                ),
          ]))
        .get();
  }

  Stream<List<Book>> watchBooksByStatus(String status) {
    return (select(books)
          ..where((t) => t.status.equals(status) & t.deletedAt.isNull()))
        .watch();
  }

  Future<List<Book>> getBooksByStatus(String status) {
    return (select(books)
          ..where((t) => t.status.equals(status) & t.deletedAt.isNull()))
        .get();
  }

  /// Sanitizes raw search text into valid FTS5 prefix query string,
  /// removing syntax operators and hyphens that cause SQLite syntax errors.
  static String sanitizeFtsQuery(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'''[-"'*^:()\[\]{}+/~?><&|!\\]+'''), ' ')
        .trim();
    if (cleaned.isEmpty) return '';
    final tokens = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    if (tokens.isEmpty) return '';
    return tokens.map((t) => '$t*').join(' ');
  }

  /// Sub-10ms full-text search using SQLite FTS5 index with BM25 ranking.
  Future<List<Book>> searchBooksFts(String query) async {
    final sanitized = sanitizeFtsQuery(query);
    if (sanitized.isEmpty) return [];

    const sql = '''
      SELECT b.* FROM books b
      JOIN (
        SELECT book_id, min(rank) AS best_rank
        FROM books_fts
        WHERE books_fts MATCH ?
        GROUP BY book_id
        ORDER BY best_rank
      ) fts ON b.id = fts.book_id
      WHERE b.deleted_at IS NULL
      ORDER BY fts.best_rank;
    ''';

    return customSelect(
      sql,
      variables: [Variable.withString(sanitized)],
      readsFrom: {books},
    ).map((row) => books.map(row.data)).get();
  }

  /// Reactive stream version of FTS5 search.
  Stream<List<Book>> watchSearchBooksFts(String query) {
    final sanitized = sanitizeFtsQuery(query);
    if (sanitized.isEmpty) return Stream.value([]);

    const sql = '''
      SELECT b.* FROM books b
      JOIN (
        SELECT book_id, min(rank) AS best_rank
        FROM books_fts
        WHERE books_fts MATCH ?
        GROUP BY book_id
        ORDER BY best_rank
      ) fts ON b.id = fts.book_id
      WHERE b.deleted_at IS NULL
      ORDER BY fts.best_rank;
    ''';

    return customSelect(
      sql,
      variables: [Variable.withString(sanitized)],
      readsFrom: {books},
    ).map((row) => books.map(row.data)).watch();
  }

  Future<int> insertBook(Insertable<Book> book) {
    return into(books).insert(book);
  }

  Future<void> insertBooks(List<Insertable<Book>> bookList) {
    return batch((b) =>
        b.insertAll(books, bookList, mode: InsertMode.insertOrReplace));
  }

  Future<bool> updateBook(Insertable<Book> book) {
    return update(books).replace(book);
  }

  Future<int> upsertBook(Insertable<Book> book) {
    return into(books).insertOnConflictUpdate(book);
  }

  /// Soft deletes book by setting deletedAt timestamp.
  Future<int> softDeleteBook(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Restores a soft-deleted book.
  Future<int> restoreBook(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// Hard-deletes book permanently from SQLite.
  Future<int> deleteBook(String id) {
    return (delete(books)..where((t) => t.id.equals(id))).go();
  }

  Future<int> updateBookPdf(String id, String? pdfPath) {
    return (update(books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        pdfPath: Value(pdfPath),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> updateBookLastReadPage(String id, int page) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        lastReadPage: Value(page),
        lastReadAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
