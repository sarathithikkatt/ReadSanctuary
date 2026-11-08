import 'package:drift/drift.dart';
import 'books.dart';

@DataClassName('BookNote')
class BookNotes extends Table {
  TextColumn get id => text()();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get noteType => text()(); // 'quote', 'thought', 'character'
  TextColumn get content => text()(); // Text or OCR-scanned quote
  IntColumn get pageNumber => integer().nullable()();
  IntColumn get createdAt => integer()(); // Unix epoch ms

  @override
  Set<Column> get primaryKey => {id};
}
