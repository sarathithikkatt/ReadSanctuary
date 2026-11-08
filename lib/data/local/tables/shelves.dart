import 'package:drift/drift.dart';

@DataClassName('Shelf')
class Shelves extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get woodThemeId => text().withDefault(const Constant('oak'))();
  TextColumn get wallThemeId =>
      text().withDefault(const Constant('warm_cream'))();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
