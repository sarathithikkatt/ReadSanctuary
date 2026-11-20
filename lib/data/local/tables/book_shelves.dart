import 'package:drift/drift.dart';
import 'books.dart';
import 'shelves.dart';

/// Junction table supporting Many-to-Many relationship between Books and Shelves (Categories).
@DataClassName('BookShelf')
@TableIndex(name: 'book_shelves_shelf_idx', columns: {#shelfId})
class BookShelves extends Table {
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get shelfId =>
      text().references(Shelves, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {bookId, shelfId};
}
