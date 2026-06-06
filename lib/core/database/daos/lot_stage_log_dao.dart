import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/lot_stage_log_table.dart';

part 'lot_stage_log_dao.g.dart';

@DriftAccessor(tables: [LotStageLogs])
class LotStageLogDao extends DatabaseAccessor<AppDatabase>
    with _$LotStageLogDaoMixin {
  LotStageLogDao(super.db);

  Future<List<DbLotStageLog>> getByLotId(String lotId) =>
      (select(lotStageLogs)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .get();

  Future<DbLotStageLog?> getActiveStage(String lotId) =>
      (select(lotStageLogs)
            ..where((t) => t.lotId.equals(lotId) & t.completedAt.isNull())
            ..limit(1))
          .getSingleOrNull();

  Future<void> insert(LotStageLogsCompanion entry) =>
      into(lotStageLogs).insertOnConflictUpdate(entry);

  Future<void> complete(
    String id, {
    required DateTime completedAt,
    double? phStart,
    double? phEnd,
    double? tempC,
    double? brixValue,
    String? notes,
    String? aiNotes,
  }) =>
      (update(lotStageLogs)..where((t) => t.id.equals(id))).write(
        LotStageLogsCompanion(
          completedAt: Value(completedAt),
          phStart:     Value(phStart),
          phEnd:       Value(phEnd),
          tempC:       Value(tempC),
          brixValue:   Value(brixValue),
          notes:       Value(notes),
          aiNotes:     Value(aiNotes),
        ),
      );
}
