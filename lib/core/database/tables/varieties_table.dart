import 'package:drift/drift.dart';

@DataClassName('DbCoffeeVariety')
class CoffeeVarietiesCatalog extends Table {
  TextColumn get id                  => text()();
  TextColumn get name                => text()();
  TextColumn get sensitivity         => text().withDefault(const Constant('medium'))();
  RealColumn get scaPotential        => real().withDefault(const Constant(84.0))();
  IntColumn  get sortOrder           => integer().withDefault(const Constant(0))();
  // Added v24 — agronomic & sensory data (Cenicafé / WCR)
  TextColumn get especie             => text().withDefault(const Constant('arabica'))();
  IntColumn  get altitudMinMasl      => integer().nullable()();
  IntColumn  get altitudMaxMasl      => integer().nullable()();
  TextColumn get procesoRecomendado  => text().nullable()();
  TextColumn get perfilesSabor       => text().nullable()(); // JSON array

  @override
  String? get tableName => 'coffee_varieties_catalog';

  @override
  Set<Column> get primaryKey => {id};
}
