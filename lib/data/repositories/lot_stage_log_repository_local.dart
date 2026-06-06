import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/domain/entities/lot_stage_log.dart' as entity;
import 'package:special_coffee/domain/repositories/lot_stage_log_repository.dart';

class LotStageLogLocalRepository implements LotStageLogRepository {
  LotStageLogLocalRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Future<List<entity.LotStageLog>> getByLotId(String lotId) async {
    final rows = await _db.lotStageLogDao.getByLotId(lotId);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<entity.LotStageLog?> getActiveStage(String lotId) async {
    final row = await _db.lotStageLogDao.getActiveStage(lotId);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<entity.LotStageLog> startStage({
    required String lotId,
    required String stage,
    String? processType,
    double? expectedDurationH,
  }) async {
    final id  = _uuid.v4();
    final now = DateTime.now();
    await _db.lotStageLogDao.insert(LotStageLogsCompanion(
      id:               Value(id),
      lotId:            Value(lotId),
      stage:            Value(stage),
      processType:      Value(processType),
      startedAt:        Value(now),
      expectedDurationH: Value(expectedDurationH),
    ));
    return entity.LotStageLog(
      id: id, lotId: lotId, stage: stage,
      processType: processType, startedAt: now,
      expectedDurationH: expectedDurationH,
    );
  }

  @override
  Future<void> completeStage(
    String id, {
    DateTime? completedAt,
    double? phStart,
    double? phEnd,
    double? tempC,
    double? brixValue,
    String? notes,
    String? aiNotes,
  }) =>
      _db.lotStageLogDao.complete(
        id,
        completedAt: completedAt ?? DateTime.now(),
        phStart: phStart,
        phEnd: phEnd,
        tempC: tempC,
        brixValue: brixValue,
        notes: notes,
        aiNotes: aiNotes,
      );

  entity.LotStageLog _toEntity(DbLotStageLog row) => entity.LotStageLog(
        id:               row.id,
        lotId:            row.lotId,
        stage:            row.stage,
        processType:      row.processType,
        startedAt:        row.startedAt,
        expectedDurationH: row.expectedDurationH,
        completedAt:      row.completedAt,
        phStart:          row.phStart,
        phEnd:            row.phEnd,
        tempC:            row.tempC,
        brixValue:        row.brixValue,
        notes:            row.notes,
        aiNotes:          row.aiNotes,
      );
}
