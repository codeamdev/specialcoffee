class LotStageLog {
  const LotStageLog({
    required this.id,
    required this.lotId,
    required this.stage,
    this.processType,
    required this.startedAt,
    this.expectedDurationH,
    this.completedAt,
    this.phStart,
    this.phEnd,
    this.tempC,
    this.brixValue,
    this.notes,
    this.aiNotes,
  });

  final String    id;
  final String    lotId;
  final String    stage;
  final String?   processType;
  final DateTime  startedAt;
  final double?   expectedDurationH;
  final DateTime? completedAt;
  final double?   phStart;
  final double?   phEnd;
  final double?   tempC;
  final double?   brixValue;
  final String?   notes;
  final String?   aiNotes;

  bool get isCompleted => completedAt != null;

  bool get isOverdue {
    if (isCompleted || expectedDurationH == null || expectedDurationH! <= 0) return false;
    return DateTime.now().difference(startedAt).inMinutes > expectedDurationH! * 60;
  }

  double get elapsedHours =>
      DateTime.now().difference(startedAt).inMinutes / 60.0;

  double get overdueHours =>
      isOverdue ? (elapsedHours - (expectedDurationH ?? 0)) : 0.0;
}
