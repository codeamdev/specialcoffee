import 'package:drift/drift.dart';

// Auto-populated when a milling session is closed.
@DataClassName('DbGreenInventory')
class GreenInventories extends Table {
  TextColumn get id                => text()();
  TextColumn get lotId             => text().named('lot_id')();
  RealColumn get weightKg          => real().named('weight_kg')();
  TextColumn get sackType          => text().named('sack_type').withDefault(const Constant('60kg'))();
  IntColumn  get sackCount         => integer().named('sack_count').withDefault(const Constant(0))();
  TextColumn get warehouseLocation => text().named('warehouse_location').nullable()();
  DateTimeColumn get updatedAt     => dateTime().named('updated_at')();

  @override
  String? get tableName => 'green_inventory';

  @override
  Set<Column> get primaryKey => {id};
}
