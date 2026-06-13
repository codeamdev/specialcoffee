class WaterProfile {
  const WaterProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    this.hardnessPpm = 0.0,
    this.phLevel = 7.0,
    this.tdsPpm = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String   id;
  final String   ownerId;
  final String   name;
  final double   hardnessPpm;
  final double   phLevel;
  final double   tdsPpm;
  final String?  notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // SCA Water Quality Handbook 2018 thresholds
  bool get isTdsOk      => tdsPpm >= 75 && tdsPpm <= 250;
  bool get isPhOk       => phLevel >= 6.5 && phLevel <= 7.5;
  bool get isHardnessOk => hardnessPpm >= 50 && hardnessPpm <= 175;
  bool get isScaCompliant => isTdsOk && isPhOk && isHardnessOk;
}
