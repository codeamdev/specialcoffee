import 'package:drift/drift.dart';

@DataClassName('DbHarvestSession')
class HarvestSessions extends Table {
  TextColumn get id => text()();
  TextColumn get lotId => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get varietyId => text().named('variety_id')();
  RealColumn get altitudeMasl => real().named('altitude_masl')();
  DateTimeColumn get startedAt => dateTime().named('started_at')();
  DateTimeColumn get completedAt => dateTime().named('completed_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  String? get tableName => 'harvest_sessions';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbHarvestPass')
class HarvestPasses extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().named('session_id')();
  TextColumn get lotId => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();
  IntColumn get passNumber => integer().named('pass_number')();
  DateTimeColumn get passDate => dateTime().named('pass_date')();
  RealColumn get kgCollected => real().named('kg_collected')();
  IntColumn get pickerCount => integer().named('picker_count')();

  // Ripeness breakdown — all nullable (optional for retrospective entries)
  RealColumn get ripenessRipePct => real().named('ripeness_ripe_pct').nullable()();
  RealColumn get ripenessGreenPct => real().named('ripeness_green_pct').nullable()();
  RealColumn get ripenessOverripePct => real().named('ripeness_overripe_pct').nullable()();
  RealColumn get ripenesDryPct => real().named('ripeness_dry_pct').nullable()();

  // Optional quality measurements
  RealColumn get brixDegrees => real().named('brix_degrees').nullable()();
  RealColumn get rainProbabilityPct =>
      real().named('rain_probability_pct').withDefault(const Constant(0.0))();

  // AI outputs
  TextColumn get aiAlertLevel =>
      text().named('ai_alert_level').withDefault(const Constant('none'))();
  TextColumn get aiAlertMessage => text().named('ai_alert_message').nullable()();

  TextColumn get notes => text().named('notes').nullable()();
  DateTimeColumn get recordedAt => dateTime().named('recorded_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'harvest_passes';

  @override
  Set<Column> get primaryKey => {id};
}
