class MillingSession {
  const MillingSession({
    required this.id,
    required this.lotId,
    required this.ownerId,
    required this.inputKgParchment,
    required this.outputKgGreen,
    required this.yieldPct,
    this.aiAlertLevel = 'none',
    this.aiAlertMessage,
    this.notes,
    required this.createdAt,
  });

  final String   id;
  final String   lotId;
  final String   ownerId;
  final double   inputKgParchment;
  final double   outputKgGreen;
  final double   yieldPct;
  final String   aiAlertLevel;
  final String?  aiAlertMessage;
  final String?  notes;
  final DateTime createdAt;
}
