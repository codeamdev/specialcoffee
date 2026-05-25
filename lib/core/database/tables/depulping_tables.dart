import 'package:drift/drift.dart';

@DataClassName('DbDepulpingSession')
class DepulpingSessions extends Table {
  TextColumn get id      => text()();
  TextColumn get lotId   => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get classificationSessionId =>
      text().named('classification_session_id').nullable()();

  // ── Core ─────────────────────────────────────────────────────────────────
  RealColumn     get kgDepulped  => real().named('kg_depulped')();
  DateTimeColumn get depulpedAt  => dateTime().named('depulped_at')();

  // ── Reference tracking ────────────────────────────────────────────────────
  // reference_source: 'classification' | 'harvest_pass' | 'none'
  TextColumn  get referenceSource    => text().named('reference_source').withDefault(const Constant('none'))();
  RealColumn  get hoursFromReference => real().named('hours_from_reference').nullable()();

  // ── AI outputs ────────────────────────────────────────────────────────────
  TextColumn get aiAlertLevel   => text().named('ai_alert_level').withDefault(const Constant('none'))();
  TextColumn get aiAlertMessage => text().named('ai_alert_message').nullable()();

  TextColumn     get notes     => text().named('notes').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt  => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'depulping_sessions';

  @override
  Set<Column> get primaryKey => {id};
}
