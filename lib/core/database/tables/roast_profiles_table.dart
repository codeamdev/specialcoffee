import 'package:drift/drift.dart';

@DataClassName('DbRoastProfile')
class RoastProfiles extends Table {
  TextColumn get id          => text()();
  TextColumn get lotId       => text().named('lot_id')();
  TextColumn get roastedBy   => text().named('roasted_by')();
  DateTimeColumn get roastedAt => dateTime().named('roasted_at')();

  RealColumn get greenWeightKg    => real().named('green_weight_kg').nullable()();
  RealColumn get roastedWeightKg  => real().named('roasted_weight_kg').nullable()();
  // Calculated automatically: (green - roasted) / green * 100
  RealColumn get roastLossPct     => real().named('roast_loss_pct').nullable()();

  RealColumn get chargeTempC      => real().named('charge_temp_c').nullable()();
  RealColumn get dropTempC        => real().named('drop_temp_c').nullable()();
  // Scott Rao: first crack typically 195–205°C
  IntColumn  get firstCrackTimeS  => integer().named('first_crack_time_s').nullable()();
  RealColumn get firstCrackTempC  => real().named('first_crack_temp_c').nullable()();
  // DTR% = development_time / total_time * 100, ref 20–25%
  IntColumn  get developmentTimeS => integer().named('development_time_s').nullable()();
  IntColumn  get totalTimeS       => integer().named('total_time_s').nullable()();
  RealColumn get dtrPct           => real().named('dtr_pct').nullable()();

  // SCA Roast Color Classification: 25–95
  IntColumn get agtronWhole  => integer().named('agtron_whole').nullable()();
  IntColumn get agtronGround => integer().named('agtron_ground').nullable()();
  TextColumn get colorLabel  => text().named('color_label').nullable()(); // 'claro'|'medio'|'oscuro'
  TextColumn get roastNotes  => text().named('roast_notes').nullable()();

  @override
  String? get tableName => 'roast_profiles';

  @override
  Set<Column> get primaryKey => {id};
}
