import 'package:drift/drift.dart';

@DataClassName('Shelf')
@TableIndex(name: 'shelves_sort_order_idx', columns: {#sortOrder})
class Shelves extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get woodThemeId => text().withDefault(const Constant('oak'))();
  TextColumn get wallThemeId =>
      text().withDefault(const Constant('warm_cream'))();
  IntColumn get sortOrder => integer()();
  IntColumn get createdAt =>
      integer().withDefault(const Constant(0))(); // Unix epoch ms
  IntColumn get updatedAt =>
      integer().withDefault(const Constant(0))(); // Unix epoch ms
  IntColumn get deletedAt =>
      integer().nullable()(); // Unix epoch ms for soft delete

  @override
  Set<Column> get primaryKey => {id};
}
