import 'package:special_coffee/domain/entities/harvest_session.dart';

abstract class HarvestRepository {
  Future<HarvestSession> createSession({
    required String lotId,
    required String varietyId,
    required double altitudeMasl,
  });

  Future<HarvestSession?> getActiveSession(String lotId);

  Future<HarvestPass> addPass({
    required String sessionId,
    required String lotId,
    required int passNumber,
    required DateTime passDate,
    required double kgCollected,
    required int pickerCount,
    double? ripenessRipePct,
    double? ripenessGreenPct,
    double? ripenessOverripePct,
    double? ripenesDryPct,
    double? brixDegrees,
    double rainProbabilityPct = 0.0,
    String aiAlertLevel = 'none',
    String? aiAlertMessage,
    String? notes,
  });

  Future<List<HarvestPass>> getPasses(String sessionId);

  Future<void> closeSession(String sessionId);
}
