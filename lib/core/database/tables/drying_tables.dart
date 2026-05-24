import 'package:drift/drift.dart';

@DataClassName('DbDryingSession')
class DryingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get lotId => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get dryingMethod => text().named('drying_method')();
  DateTimeColumn get startedAt => dateTime().named('started_at')();
  DateTimeColumn get endedAt => dateTime().named('ended_at').nullable()();
  RealColumn get targetMoisturePct =>
      real().named('target_moisture_pct').withDefault(const Constant(11.0))();
  RealColumn get finalMoisturePct => real().named('final_moisture_pct').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  String? get tableName => 'drying_sessions';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbDryingReading')
class DryingReadings extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().named('session_id')();
  TextColumn get lotId => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();
  RealColumn get moisturePct => real().named('moisture_pct')();
  RealColumn get ambientTempC => real().named('ambient_temp_c')();
  RealColumn get ambientHumidityPct => real().named('ambient_humidity_pct')();
  RealColumn get uvIndex =>
      real().named('uv_index').withDefault(const Constant(0.0))();
  TextColumn get aiRecommendation => text().named('ai_recommendation').nullable()();
  DateTimeColumn get recordedAt => dateTime().named('recorded_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'drying_readings';

  @override
  Set<Column> get primaryKey => {id};
}
