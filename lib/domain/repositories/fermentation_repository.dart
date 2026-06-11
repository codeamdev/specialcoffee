import 'package:special_coffee/domain/entities/fermentation_session.dart';

abstract class FermentationRepository {
  Future<FermentationSession> createSession({
    required String lotId,
    required String processType,
  });

  Future<FermentationSession?> getActiveSession(String lotId);

  Future<FermentationReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int    readingNumber,
    required double hoursElapsed,
    required double phValue,
    required double mucilagoTempC,
    String  mucilageState  = 'liquid',
    double? ambientTempC,
    String  aiAlertLevel   = 'none',
    String? aiAlertRuleId,
    double? aiProjectedEndH,
  });

  Future<List<FermentationReadingRecord>> getReadings(String sessionId);

  Future<void> closeSession({
    required String sessionId,
    required String endReason,
    required double actualDurationH,
    required double phFinal,
  });

  Future<double> getAvgCompletedDurationH();
  Future<double> getLastCompletedDurationH();
}
