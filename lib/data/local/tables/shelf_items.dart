import 'package:drift/drift.dart';
import 'books.dart';
import 'shelves.dart';

@DataClassName('ShelfItem')
@TableIndex(name: 'shelf_items_shelf_idx', columns: {#shelfId, #positionIndex})
@TableIndex(name: 'shelf_items_book_idx', columns: {#bookId})
class ShelfItems extends Table {
  TextColumn get id => text()();
  TextColumn get shelfId =>
      text().references(Shelves, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemType => text()(); // 'book', 'prop', 'gap'
  TextColumn get bookId =>
      text().nullable().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get propAssetId =>
      text().nullable()(); // e.g. plant_monstera, candle_amber
  TextColumn get displayMode => text().withDefault(
      const Constant('spine'))(); // 'spine', 'cover_out', 'stacked'
  IntColumn get positionIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
