class PhysicalAnalysis {
  const PhysicalAnalysis({
    required this.id,
    required this.lotId,
    required this.analyzedBy,
    required this.analyzedAt,
    this.greenDensityGcm3,
    this.moisturePct,
    this.waterActivityAw,
    this.defectsPrimary,
    this.defectsSecondary,
    this.defectTypes,
    this.screenSize,
    this.notes,
  });

  final String    id;
  final String    lotId;
  final String    analyzedBy;
  final DateTime  analyzedAt;
  final double?   greenDensityGcm3;
  final double?   moisturePct;
  final double?   waterActivityAw;
  final int?      defectsPrimary;
  final int?      defectsSecondary;
  final String?   defectTypes;
  final int?      screenSize;
  final String?   notes;
}
