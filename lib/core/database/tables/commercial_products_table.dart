import 'package:drift/drift.dart';

// packaged_date feeds into CoffeeReference.packaged_date for freshness tracking.
@DataClassName('DbCommercialProduct')
class CommercialProducts extends Table {
  TextColumn get id                 => text()();
  TextColumn get roastedInventoryId => text().named('roasted_inventory_id')();
  TextColumn get name               => text()();
  TextColumn get description        => text().nullable()();
  IntColumn  get formatG            => integer().named('format_g').withDefault(const Constant(250))();
  IntColumn  get unitsProduced      => integer().named('units_produced').withDefault(const Constant(0))();
  IntColumn  get unitsAvailable     => integer().named('units_available').withDefault(const Constant(0))();
  RealColumn get costUsd            => real().named('cost_usd').nullable()();
  RealColumn get priceUsd           => real().named('price_usd').nullable()();
  DateTimeColumn get packagedDate   => dateTime().named('packaged_date').nullable()();
  TextColumn get barcode            => text().nullable()();
  DateTimeColumn get createdAt      => dateTime().named('created_at')();

  @override
  String? get tableName => 'commercial_products';

  @override
  Set<Column> get primaryKey => {id};
}
