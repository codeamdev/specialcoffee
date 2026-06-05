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
}
