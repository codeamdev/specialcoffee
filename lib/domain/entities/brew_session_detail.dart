class BrewSessionDetail {
  const BrewSessionDetail({
    required this.id,
    required this.brewingSessionId,
    this.coffeeReferenceId,
    this.waterProfileId,
    this.actualRatioUsed,
    this.extractionYieldPct,
    this.measuredTdsPct,
    this.notes,
    required this.createdAt,
  });

  final String   id;
  final String   brewingSessionId;
  final String?  coffeeReferenceId;
  final String?  waterProfileId;
  final double?  actualRatioUsed;
  final double?  extractionYieldPct;
  final double?  measuredTdsPct;
  final String?  notes;
  final DateTime createdAt;
}
