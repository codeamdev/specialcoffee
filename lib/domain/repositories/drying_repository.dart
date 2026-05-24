import 'package:special_coffee/domain/entities/drying_session.dart';

abstract class DryingRepository {
  Future<DryingSession> createSession({
    required String lotId,
    required String dryingMethod,
  });

  Future<DryingSession?> getActiveSession(String lotId);

  Future<DryingReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int dayNumber,
    required double moisturePct,
    required double ambientTempC,
    required double ambientHumidityPct,
    double uvIndex = 0.0,
    String? aiRecommendation,
  });

  Future<List<DryingReadingRecord>> getReadings(String sessionId);

  Future<void> closeSession({
    required String sessionId,
    required double finalMoisturePct,
  });
}
