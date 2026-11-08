import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/books.dart';

part 'book_dao.g.dart';

@DriftAccessor(tables: [Books])
class BookDao extends DatabaseAccessor<AppDatabase> with _$BookDaoMixin {
  BookDao(super.db);

  Stream<List<Book>> watchAllBooks() {
    return (select(books)
          ..orderBy([
            (t) => OrderingTerm(expression: t.title, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Future<List<Book>> getAllBooks() {
    return (select(books)
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
          ..where((t) => t.seriesName.equals(seriesName))
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
          ..where((t) => t.seriesName.equals(seriesName))
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
    return (select(books)..where((t) => t.status.equals(status))).watch();
  }

  Future<List<Book>> getBooksByStatus(String status) {
    return (select(books)..where((t) => t.status.equals(status))).get();
  }

  Future<int> insertBook(Insertable<Book> book) {
    return into(books).insert(book);
  }

  Future<void> insertBooks(List<Insertable<Book>> bookList) {
    return transaction(() async {
      for (final book in bookList) {
        await into(books).insert(book, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<bool> updateBook(Insertable<Book> book) {
    return update(books).replace(book);
  }

  Future<int> upsertBook(Insertable<Book> book) {
    return into(books).insertOnConflictUpdate(book);
  }

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
    return (update(books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        lastReadPage: Value(page),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
