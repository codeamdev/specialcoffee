class BrewingSession {
  const BrewingSession({
    required this.id,
    required this.ownerId,
    required this.method,
    required this.doseG,
    required this.waterG,
    required this.waterTempC,
    this.actualTimeSec,
    this.tdsPct,
    this.yieldG,
    this.notes,
    required this.brewedAt,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String method;
  final double doseG;
  final double waterG;
  final double waterTempC;
  final int?    actualTimeSec;
  final double? tdsPct;
  final double? yieldG;
  final String? notes;
  final DateTime brewedAt;
  final DateTime createdAt;
}
