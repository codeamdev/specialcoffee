import 'package:special_coffee/domain/entities/brew_session.dart';

abstract class BrewSessionRepository {
  Future<BrewSession> create({
    required String userId,
    required String method,
    String? lotId,
    // Receta IA
    required bool   aiRecipeGenerated,
    double? aiDoseG,
    double? aiWaterG,
    double? aiRatio,
    double? aiWaterTempC,
    double? aiGrindSetting,
    double? aiBloomG,
    int?    aiBloomSeconds,
    int?    aiTotalTimeTargetS,
    double? aiTdsTargetMin,
    double? aiTdsTargetMax,
    double? aiYieldTargetMin,
    double? aiYieldTargetMax,
    String? aiRecipeVersion,
    Map<String, dynamic>? aiRecipeBasedOn,
  });

  Future<BrewSession> updateResult({
    required String sessionId,
    required double tdsPct,
    required double extractionYieldPct,
    required bool   tdsInTarget,
    String? aiSessionQuality,
    Map<String, dynamic>? aiDiagnosis,
  });

  Future<List<BrewSession>> getUserSessions({
    required String userId,
    String? method,
    int limit = 20,
  });
}
