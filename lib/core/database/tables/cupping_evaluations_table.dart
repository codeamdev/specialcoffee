import 'package:drift/drift.dart';

// SCA Cupping Protocol formal evaluation — sibling of cupping_sessions, not a replacement.
// cupping_sessions: field/process cupping (quick score, no SCA breakdown)
// cupping_evaluations: formal Q Grader SCA scoresheet (Coffee Master role)
@DataClassName('DbCuppingEvaluation')
class CuppingEvaluations extends Table {
  TextColumn get id            => text()();
  TextColumn get lotId         => text().named('lot_id')();
  TextColumn get roastProfileId => text().named('roast_profile_id').nullable()();
  TextColumn get cupperId      => text().named('cupper_id')();
  DateTimeColumn get cuppedAt  => dateTime().named('cupped_at')();

  // SCA attributes — each 6–10 pts scale
  RealColumn get fragranceAroma    => real().named('fragrance_aroma').nullable()();
  RealColumn get flavor            => real().nullable()();
  RealColumn get aftertaste        => real().nullable()();
  RealColumn get acidity           => real().nullable()();
  RealColumn get acidityIntensity  => real().named('acidity_intensity').nullable()();
  RealColumn get body              => real().nullable()();
  RealColumn get bodyTexture       => real().named('body_texture').nullable()();
  RealColumn get balance           => real().nullable()();
  RealColumn get uniformity        => real().nullable()();
  RealColumn get cleanCup          => real().named('clean_cup').nullable()();
  RealColumn get sweetness         => real().nullable()();
  RealColumn get overall           => real().nullable()();

  // Defects subtract from score: fault × 4, taint × 2
  IntColumn get defectsTaint => integer().named('defects_taint').withDefault(const Constant(0))();
  IntColumn get defectsFault => integer().named('defects_fault').withDefault(const Constant(0))();

  // total = sum + 36 - (4 × faults) - (2 × taints)
  RealColumn get totalScore => real().named('total_score').nullable()();

  TextColumn get flavorDescriptors => text().named('flavor_descriptors').nullable()(); // JSON list
  TextColumn get notes             => text().nullable()();

  @override
  String? get tableName => 'cupping_evaluations';

  @override
  Set<Column> get primaryKey => {id};
}
