import 'package:drift/drift.dart';

@DataClassName('DbMillingSession')
class MillingSessions extends Table {
  TextColumn get id      => text()();
  TextColumn get lotId   => text().named('lot_id')();
  TextColumn get ownerId => text().named('owner_id')();

  // ── Core measurements ─────────────────────────────────────────────────────
  RealColumn get inputKgParchment => real().named('input_kg_parchment')();
  RealColumn get outputKgGreen    => real().named('output_kg_green')();
  RealColumn get yieldPct         => real().named('yield_pct')();

  // ── AI outputs ────────────────────────────────────────────────────────────
  TextColumn get aiAlertLevel   => text().named('ai_alert_level').withDefault(const Constant('none'))();
  TextColumn get aiAlertMessage => text().named('ai_alert_message').nullable()();

  TextColumn     get notes     => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt  => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'milling_sessions';

  @override
  Set<Column> get primaryKey => {id};
}
