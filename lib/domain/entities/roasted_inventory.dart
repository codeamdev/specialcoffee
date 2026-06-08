class RoastedInventory {
  const RoastedInventory({
    required this.id,
    required this.roastProfileId,
    required this.weightKg,
    required this.updatedAt,
  });

  final String    id;
  final String    roastProfileId;
  final double    weightKg;
  final DateTime  updatedAt;
}
