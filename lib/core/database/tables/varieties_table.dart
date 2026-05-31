import 'package:drift/drift.dart';

@DataClassName('DbCoffeeVariety')
class CoffeeVarietiesCatalog extends Table {
  TextColumn get id            => text()();
  TextColumn get name          => text()();
  TextColumn get sensitivity   => text().withDefault(const Constant('medium'))();
  RealColumn get scaPotential  => real().withDefault(const Constant(84.0))();
  IntColumn  get sortOrder     => integer().withDefault(const Constant(0))();

  @override
  String? get tableName => 'coffee_varieties_catalog';

  @override
  Set<Column> get primaryKey => {id};
}
