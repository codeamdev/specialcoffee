class DryingSession {
  final String id;
  final String lotId;
  final String ownerId;
  final String dryingMethod;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double targetMoisturePct;
  final double? finalMoisturePct;
  final DateTime createdAt;

  const DryingSession({
    required this.id,
    required this.lotId,
    required this.ownerId,
    required this.dryingMethod,
    required this.startedAt,
    this.endedAt,
    this.targetMoisturePct = 11.0,
    this.finalMoisturePct,
    required this.createdAt,
  });
}

class DryingReadingRecord {
  final String id;
  final String sessionId;
  final String lotId;
  final String ownerId;
  final int dayNumber;
  final double moisturePct;
  final double ambientTempC;
  final double ambientHumidityPct;
  final double uvIndex;
  final String? aiRecommendation;
  final DateTime recordedAt;

  const DryingReadingRecord({
    required this.id,
    required this.sessionId,
    required this.lotId,
    required this.ownerId,
    required this.dayNumber,
    required this.moisturePct,
    required this.ambientTempC,
    required this.ambientHumidityPct,
    this.uvIndex = 0.0,
    this.aiRecommendation,
    required this.recordedAt,
  });
}
