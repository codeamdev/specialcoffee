import 'package:drift/drift.dart';

@DataClassName('DbWashingSession')
class WashingSessions extends Table {
  TextColumn get id      => text()();
  TextColumn get lotId   => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get fermentationSessionId =>
      text().named('fermentation_session_id').nullable()();

  // ── Core measurements ────────────────────────────────────────────────────
  RealColumn     get waterTempC      => real().named('water_temp_c')();
  IntColumn      get waterChanges    => integer().named('water_changes')();
  RealColumn     get effluentPhFinal => real().named('effluent_ph_final')();
  RealColumn     get durationH       => real().named('duration_h')();
  DateTimeColumn get washedAt        => dateTime().named('washed_at')();

  // ── AI outputs ────────────────────────────────────────────────────────────
  TextColumn get aiAlertLevel   => text().named('ai_alert_level').withDefault(const Constant('none'))();
  TextColumn get aiAlertMessage => text().named('ai_alert_message').nullable()();

  TextColumn     get notes     => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt  => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'washing_sessions';

  @override
  Set<Column> get primaryKey => {id};
}
