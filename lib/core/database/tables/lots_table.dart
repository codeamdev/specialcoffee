import 'package:drift/drift.dart';

@DataClassName('DbLot')
class Lots extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get lotCode => text().named('lot_code')();
  TextColumn get varietyId => text().named('variety_id')();
  RealColumn get altitudeMasl => real().named('altitude_masl')();
  TextColumn get region => text().named('region').withDefault(const Constant(''))();
  RealColumn get areaHectares => real().named('area_hectares').nullable()();
  IntColumn get treeCount => integer().named('tree_count').nullable()();
  IntColumn get harvestYear => integer().named('harvest_year').nullable()();
  RealColumn get ambientTempC => real().named('ambient_temp_c').nullable()();
  RealColumn get ambientHumidityPct => real().named('ambient_humidity_pct').nullable()();
  RealColumn get rainProbabilityPct =>
      real().named('rain_probability_pct').withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  String? get tableName => 'lots';

  @override
  Set<Column> get primaryKey => {id};
}
