import 'package:drift/drift.dart';

// SCA Classic Cupping Form 2004 — official standard until CVA adoption.
// D-9: migrate to CVA Affective Assessment when FNC publishes Colombian adaptation.
@DataClassName('DbCuppingSession')
class CuppingSessions extends Table {
  TextColumn     get id      => text()();
  TextColumn     get lotId   => text().named('lot_id')();
  TextColumn     get ownerId => text().named('owner_id')();
  DateTimeColumn get cuppedAt => dateTime().named('cupped_at')();

  // ── 10 SCA attributes (6.00–10.00 in 0.25 steps) ─────────────────────────
  RealColumn get fragranceAroma   => real().named('fragrance_aroma')();
  RealColumn get flavor           => real()();
  RealColumn get aftertaste       => real()();
  RealColumn get acidity          => real()();
  TextColumn get acidityIntensity => text().named('acidity_intensity').withDefault(const Constant('medium'))();
  RealColumn get body             => real()();
  TextColumn get bodyLevel        => text().named('body_level').withDefault(const Constant('medium'))();
  RealColumn get balance          => real()();
  // Uniformity / Clean Cup / Sweetness: stored as cup count (0–5); score = count × 2
  IntColumn  get uniformityCups   => integer().named('uniformity_cups').withDefault(const Constant(5))();
  IntColumn  get cleanCupCups     => integer().named('clean_cup_cups').withDefault(const Constant(5))();
  IntColumn  get sweetnessCups    => integer().named('sweetness_cups').withDefault(const Constant(5))();
  RealColumn get overall          => real()();

  // ── Defects ───────────────────────────────────────────────────────────────
  IntColumn get defectsCat1Count => integer().named('defects_cat1_count').withDefault(const Constant(0))();
  IntColumn get defectsCat2Count => integer().named('defects_cat2_count').withDefault(const Constant(0))();

  // ── AI outputs ────────────────────────────────────────────────────────────
  TextColumn get aiAlertLevel   => text().named('ai_alert_level').withDefault(const Constant('none'))();
  TextColumn get aiAlertMessage => text().named('ai_alert_message').nullable()();

  // Stored for query efficiency — avoids recomputing across large result sets
  RealColumn get totalScore => real().named('total_score')();

  TextColumn     get notes     => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt  => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'cupping_sessions';

  @override
  Set<Column> get primaryKey => {id};
}
