import 'package:drift/drift.dart';

// Calculated from green_inventory × (1 - roast_loss_pct%).
@DataClassName('DbRoastedInventory')
class RoastedInventories extends Table {
  TextColumn get id             => text()();
  TextColumn get roastProfileId => text().named('roast_profile_id')();
  RealColumn get weightKg       => real().named('weight_kg')();
  DateTimeColumn get updatedAt  => dateTime().named('updated_at')();

  @override
  String? get tableName => 'roasted_inventory';

  @override
  Set<Column> get primaryKey => {id};
}
