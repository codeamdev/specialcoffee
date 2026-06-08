class GreenInventory {
  const GreenInventory({
    required this.id,
    required this.lotId,
    required this.weightKg,
    required this.updatedAt,
    this.sackType = '60kg',
    this.sackCount = 0,
    this.warehouseLocation,
  });

  final String    id;
  final String    lotId;
  final double    weightKg;
  final String    sackType;
  final int       sackCount;
  final String?   warehouseLocation;
  final DateTime  updatedAt;
}
