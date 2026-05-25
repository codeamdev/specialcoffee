class ClassificationSession {
  const ClassificationSession({
    required this.id,
    required this.lotId,
    required this.ownerId,
    this.harvestSessionId,
    required this.kgEntrada,
    this.brixCereza,
    this.kgFlotantes = 0.0,
    this.kgDescarteManual = 0.0,
    this.aiAlertLevel = 'none',
    this.aiAlertMessage,
    this.notes,
    required this.classifiedAt,
    required this.createdAt,
  });

  final String   id;
  final String   lotId;
  final String   ownerId;
  final String?  harvestSessionId;
  final double   kgEntrada;
  final double?  brixCereza;
  final double   kgFlotantes;
  final double   kgDescarteManual;
  final String   aiAlertLevel;
  final String?  aiAlertMessage;
  final String?  notes;
  final DateTime classifiedAt;
  final DateTime createdAt;

  // ── Computed (no almacenados para evitar inconsistencias) ─────────────────
  double get kgSeleccionado =>
      (kgEntrada - kgFlotantes - kgDescarteManual).clamp(0.0, kgEntrada);

  double get pctAprovechamiento =>
      kgEntrada > 0 ? (kgSeleccionado / kgEntrada * 100) : 0.0;

  double get pctFlotacion =>
      kgEntrada > 0 ? (kgFlotantes / kgEntrada * 100) : 0.0;

  double get pctDescarteTotal =>
      kgEntrada > 0 ? ((kgFlotantes + kgDescarteManual) / kgEntrada * 100) : 0.0;
}
