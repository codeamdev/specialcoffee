import 'package:drift/drift.dart';

@DataClassName('DbFermentationSession')
class FermentationSessions extends Table {
  TextColumn get id => text()();
  TextColumn get lotId => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get processType => text().named('process_type')();
  DateTimeColumn get startedAt => dateTime().named('started_at')();
  DateTimeColumn get endedAt => dateTime().named('ended_at').nullable()();
  RealColumn get actualDurationH => real().named('actual_duration_h').nullable()();
  TextColumn get endReason => text().named('end_reason').nullable()();
  RealColumn get phInitial => real().named('ph_initial').nullable()();
  RealColumn get phFinal => real().named('ph_final').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  String? get tableName => 'fermentation_sessions';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbFermentationReading')
class FermentationReadings extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().named('session_id')();
  TextColumn get lotId => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();
  IntColumn get readingNumber => integer().named('reading_number')();
  RealColumn get hoursElapsed => real().named('hours_elapsed')();
  RealColumn get phValue => real().named('ph_value')();
  RealColumn get mucilagoTempC => real().named('mucilago_temp_c')();
  RealColumn get ambientTempC => real().named('ambient_temp_c').nullable()();
  TextColumn get mucilageState =>
      text().named('mucilage_state').withDefault(const Constant('liquid'))();
  TextColumn get aiAlertLevel =>
      text().named('ai_alert_level').withDefault(const Constant('none'))();
  TextColumn get aiAlertRuleId => text().named('ai_alert_rule_id').nullable()();
  RealColumn get aiProjectedEndH => real().named('ai_projected_end_h').nullable()();
  DateTimeColumn get recordedAt => dateTime().named('recorded_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'fermentation_readings';

  @override
  Set<Column> get primaryKey => {id};
}
