import 'package:drift/drift.dart';

@DataClassName('DbClassificationSession')
class ClassificationSessions extends Table {
  TextColumn  get id               => text()();
  TextColumn  get lotId            => text().named('lot_id')();
  TextColumn  get ownerId          => text().named('owner_id')();
  TextColumn  get harvestSessionId => text().named('harvest_session_id').nullable()();

  // ── Inputs ────────────────────────────────────────────────────────────────
  RealColumn get kgEntrada        => real().named('kg_entrada')();
  RealColumn get brixCereza       => real().named('brix_cereza').nullable()();
  RealColumn get kgFlotantes      => real().named('kg_flotantes').withDefault(const Constant(0.0))();
  RealColumn get kgDescarteManual => real().named('kg_descarte_manual').withDefault(const Constant(0.0))();

  // ── AI outputs ────────────────────────────────────────────────────────────
  TextColumn get aiAlertLevel   => text().named('ai_alert_level').withDefault(const Constant('none'))();
  TextColumn get aiAlertMessage => text().named('ai_alert_message').nullable()();

  TextColumn     get notes        => text().named('notes').nullable()();
  DateTimeColumn get classifiedAt => dateTime().named('classified_at')();
  DateTimeColumn get createdAt    => dateTime().named('created_at')();
  DateTimeColumn get updatedAt    => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt     => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'classification_sessions';

  @override
  Set<Column> get primaryKey => {id};
}
