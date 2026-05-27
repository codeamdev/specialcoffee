class WashingSession {
  const WashingSession({
    required this.id,
    required this.lotId,
    required this.ownerId,
    this.fermentationSessionId,
    required this.waterTempC,
    required this.waterChanges,
    required this.effluentPhFinal,
    required this.durationH,
    required this.washedAt,
    this.aiAlertLevel = 'none',
    this.aiAlertMessage,
    this.notes,
    required this.createdAt,
  });

  final String   id;
  final String   lotId;
  final String   ownerId;
  final String?  fermentationSessionId;

  final double   waterTempC;
  final int      waterChanges;
  final double   effluentPhFinal;
  final double   durationH;
  final DateTime washedAt;

  final String   aiAlertLevel;
  final String?  aiAlertMessage;
  final String?  notes;
  final DateTime createdAt;
}
