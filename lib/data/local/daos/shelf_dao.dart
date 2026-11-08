import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/shelves.dart';
import '../tables/shelf_items.dart';

part 'shelf_dao.g.dart';

/// Combined data model representing a shelf item along with its populated book details.
class ShelfItemWithBook {
  final ShelfItem item;
  final Book? book;

  const ShelfItemWithBook({
    required this.item,
    this.book,
  });
}

@DriftAccessor(tables: [Shelves, ShelfItems])
class ShelfDao extends DatabaseAccessor<AppDatabase> with _$ShelfDaoMixin {
  ShelfDao(super.db);

  Stream<List<Shelf>> watchAllShelves() {
    return (select(shelves)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Future<List<Shelf>> getAllShelves() {
    return (select(shelves)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Stream<Shelf?> watchShelfById(String id) {
    return (select(shelves)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<Shelf?> getShelfById(String id) {
    return (select(shelves)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertShelf(Insertable<Shelf> shelf) {
    return into(shelves).insert(shelf);
  }

  Future<bool> updateShelf(Insertable<Shelf> shelf) {
    return update(shelves).replace(shelf);
  }

  Future<int> deleteShelf(String id) {
    return (delete(shelves)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ShelfItem>> watchItemsForShelf(String shelfId) {
    return (select(shelfItems)
          ..where((t) => t.shelfId.equals(shelfId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.positionIndex, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Future<List<ShelfItem>> getItemsForShelf(String shelfId) {
    return (select(shelfItems)
          ..where((t) => t.shelfId.equals(shelfId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.positionIndex, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// High-performance reactive joined stream fetching items and populated books in a single SQL query.
  Stream<List<ShelfItemWithBook>> watchItemsWithBooksForShelf(String shelfId) {
    final query = (select(shelfItems)
          ..where((t) => t.shelfId.equals(shelfId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.positionIndex, mode: OrderingMode.asc)
          ]))
        .join([
      leftOuterJoin(db.books, db.books.id.equalsExp(shelfItems.bookId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ShelfItemWithBook(
          item: row.readTable(shelfItems),
          book: row.readTableOrNull(db.books),
        );
      }).toList();
    });
  }

  /// High-performance joined query fetching items and populated books in a single SQL query.
  Future<List<ShelfItemWithBook>> getItemsWithBooksForShelf(
      String shelfId) async {
    final query = (select(shelfItems)
          ..where((t) => t.shelfId.equals(shelfId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.positionIndex, mode: OrderingMode.asc)
          ]))
        .join([
      leftOuterJoin(db.books, db.books.id.equalsExp(shelfItems.bookId)),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      return ShelfItemWithBook(
        item: row.readTable(shelfItems),
        book: row.readTableOrNull(db.books),
      );
    }).toList();
  }

  Future<int> insertShelfItem(Insertable<ShelfItem> item) {
    return into(shelfItems).insert(item);
  }

  Future<void> insertShelfItems(List<Insertable<ShelfItem>> items) {
    return transaction(() async {
      for (final item in items) {
        await into(shelfItems).insert(item, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<ShelfItem?> getItemByBookId(String bookId) {
    return (select(shelfItems)..where((t) => t.bookId.equals(bookId)))
        .getSingleOrNull();
  }

  Future<bool> updateShelfItem(Insertable<ShelfItem> item) {
    return update(shelfItems).replace(item);
  }

  Future<int> deleteShelfItemByBookId(String bookId) {
    return (delete(shelfItems)..where((t) => t.bookId.equals(bookId))).go();
  }

  Future<int> deleteShelfItem(String id) {
    return (delete(shelfItems)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reorderShelfItems(String shelfId, List<String> itemIdsInOrder) {
    return transaction(() async {
      for (int i = 0; i < itemIdsInOrder.length; i++) {
        await (update(shelfItems)
              ..where((t) =>
                  t.id.equals(itemIdsInOrder[i]) & t.shelfId.equals(shelfId)))
            .write(ShelfItemsCompanion(positionIndex: Value(i)));
      }
    });
  }
}
