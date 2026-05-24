class HarvestSession {
  final String id;
  final String lotId;
  final String ownerId;
  final String varietyId;
  final double altitudeMasl;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const HarvestSession({
    required this.id,
    required this.lotId,
    required this.ownerId,
    required this.varietyId,
    required this.altitudeMasl,
    required this.startedAt,
    this.completedAt,
    required this.createdAt,
  });
}

class HarvestPass {
  final String id;
  final String sessionId;
  final String lotId;
  final String ownerId;
  final int passNumber;
  final DateTime passDate;
  final double kgCollected;
  final int pickerCount;

  // Ripeness breakdown — all nullable (retrospective entries may omit)
  final double? ripenessRipePct;
  final double? ripenessGreenPct;
  final double? ripenessOverripePct;
  final double? ripenesDryPct;

  final double? brixDegrees;
  final double rainProbabilityPct;
  final String aiAlertLevel;
  final String? aiAlertMessage;
  final String? notes;
  final DateTime recordedAt;

  bool get hasRipenessData => ripenessRipePct != null;

  double? get ripenessTotal {
    if (!hasRipenessData) return null;
    return (ripenessRipePct ?? 0) +
        (ripenessGreenPct ?? 0) +
        (ripenessOverripePct ?? 0) +
        (ripenesDryPct ?? 0);
  }

  const HarvestPass({
    required this.id,
    required this.sessionId,
    required this.lotId,
    required this.ownerId,
    required this.passNumber,
    required this.passDate,
    required this.kgCollected,
    required this.pickerCount,
    this.ripenessRipePct,
    this.ripenessGreenPct,
    this.ripenessOverripePct,
    this.ripenesDryPct,
    this.brixDegrees,
    this.rainProbabilityPct = 0.0,
    this.aiAlertLevel = 'none',
    this.aiAlertMessage,
    this.notes,
    required this.recordedAt,
  });
}
