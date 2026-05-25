class DepulpingSession {
  const DepulpingSession({
    required this.id,
    required this.lotId,
    required this.ownerId,
    this.classificationSessionId,
    required this.kgDepulped,
    required this.depulpedAt,
    required this.referenceSource,
    this.hoursFromReference,
    this.aiAlertLevel = 'none',
    this.aiAlertMessage,
    this.notes,
    required this.createdAt,
  });

  final String   id;
  final String   lotId;
  final String   ownerId;
  final String?  classificationSessionId;

  final double   kgDepulped;
  final DateTime depulpedAt;

  // ── Reference tracking ────────────────────────────────────────────────────
  // referenceSource: 'classification' | 'harvest_pass' | 'none'
  // Allows auditors to reconstruct which event was used and whether hoursFromReference
  // includes or excludes the classification window.
  final String  referenceSource;
  final double? hoursFromReference;

  final String  aiAlertLevel;
  final String? aiAlertMessage;
  final String? notes;
  final DateTime createdAt;
}
