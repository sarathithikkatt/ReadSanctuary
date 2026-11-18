import 'package:drift/drift.dart';
import 'books.dart';

@DataClassName('ReadingSession')
@TableIndex(name: 'reading_sessions_book_idx', columns: {#bookId})
@TableIndex(name: 'reading_sessions_time_idx', columns: {#startTime})
class ReadingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get startTime => integer()(); // Unix epoch ms
  IntColumn get durationSeconds =>
      integer()(); // Active reading time in seconds
  IntColumn get startPage => integer()();
  IntColumn get endPage => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
