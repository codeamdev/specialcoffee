import 'package:drift/drift.dart';

@DataClassName('DbLotStageLog')
class LotStageLogs extends Table {
  TextColumn get id          => text()();
  TextColumn get lotId       => text().named('lot_id')();
  // 'harvest'|'classification'|'depulping'|'fermentation'|'washing'|'drying'|'milling'|'cupping'
  TextColumn get stage       => text()();
  TextColumn get processType => text().named('process_type').nullable()();

  DateTimeColumn get startedAt         => dateTime().named('started_at')();
  RealColumn     get expectedDurationH => real().named('expected_duration_h').nullable()();
  DateTimeColumn get completedAt       => dateTime().named('completed_at').nullable()();

  RealColumn get phStart   => real().named('ph_start').nullable()();
  RealColumn get phEnd     => real().named('ph_end').nullable()();
  RealColumn get tempC     => real().named('temp_c').nullable()();
  RealColumn get brixValue => real().named('brix_value').nullable()();

  TextColumn get notes   => text().nullable()();
  TextColumn get aiNotes => text().named('ai_notes').nullable()();

  @override
  String? get tableName => 'lot_stage_log';

  @override
  Set<Column> get primaryKey => {id};
}
