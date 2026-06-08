import 'package:drift/drift.dart';

@DataClassName('DbPhysicalAnalysis')
class PhysicalAnalyses extends Table {
  TextColumn get id          => text()();
  TextColumn get lotId       => text().named('lot_id')();
  TextColumn get analyzedBy  => text().named('analyzed_by')();
  DateTimeColumn get analyzedAt => dateTime().named('analyzed_at')();

  // SCA Defect Handbook: 0.60–0.90 g/cm³
  RealColumn get greenDensityGcm3  => real().named('green_density_gcm3').nullable()();
  // ISO 6673 / Cenicafé: 10–12%
  RealColumn get moisturePct       => real().named('moisture_pct').nullable()();
  // SCA Green Coffee Standards: 0.50–0.65
  RealColumn get waterActivityAw   => real().named('water_activity_aw').nullable()();
  IntColumn get defectsPrimary     => integer().named('defects_primary').nullable()();
  IntColumn get defectsSecondary   => integer().named('defects_secondary').nullable()();
  TextColumn get defectTypes       => text().named('defect_types').nullable()(); // JSON SCA codes
  IntColumn get screenSize         => integer().named('screen_size').nullable()();
  TextColumn get notes             => text().nullable()();

  @override
  String? get tableName => 'physical_analyses';

  @override
  Set<Column> get primaryKey => {id};
}
