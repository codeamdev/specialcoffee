import 'package:drift/drift.dart';

@DataClassName('DbWaterProfile')
class WaterProfiles extends Table {
  TextColumn get id      => text()();
  TextColumn get ownerId => text().named('owner_id')();

  TextColumn get name         => text()();
  RealColumn get hardnessPpm  => real().named('hardness_ppm').withDefault(const Constant(0.0))();
  RealColumn get phLevel      => real().named('ph_level').withDefault(const Constant(7.0))();
  RealColumn get tdsPpm       => real().named('tds_ppm').withDefault(const Constant(0.0))();
  TextColumn get notes        => text().nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  String? get tableName => 'water_profiles';

  @override
  Set<Column> get primaryKey => {id};
}
