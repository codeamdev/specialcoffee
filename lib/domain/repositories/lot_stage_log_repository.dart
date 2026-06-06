import 'package:special_coffee/domain/entities/lot_stage_log.dart';

abstract interface class LotStageLogRepository {
  Future<List<LotStageLog>> getByLotId(String lotId);
  Future<LotStageLog?> getActiveStage(String lotId);
  Future<LotStageLog> startStage({
    required String lotId,
    required String stage,
    String? processType,
    double? expectedDurationH,
  });
  Future<void> completeStage(
    String id, {
    DateTime? completedAt,
    double? phStart,
    double? phEnd,
    double? tempC,
    double? brixValue,
    String? notes,
    String? aiNotes,
  });
}
