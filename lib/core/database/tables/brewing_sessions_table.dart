import 'package:drift/drift.dart';

@DataClassName('DbBrewingSession')
class BrewingSessions extends Table {
  TextColumn get id          => text()();
  TextColumn get ownerId     => text().named('owner_id')();
  TextColumn get method      => text()();
  RealColumn get doseG       => real().named('dose_g')();
  RealColumn get waterG      => real().named('water_g')();
  RealColumn get waterTempC  => real().named('water_temp_c')();
  IntColumn  get actualTimeSec => integer().named('actual_time_sec').nullable()();
  RealColumn get tdsPct      => real().named('tds_pct').nullable()();
  RealColumn get yieldG      => real().named('yield_g').nullable()();
  TextColumn get notes       => text().nullable()();
  DateTimeColumn get brewedAt  => dateTime().named('brewed_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  String? get tableName => 'brewing_sessions_local';

  @override
  Set<Column> get primaryKey => {id};
}
