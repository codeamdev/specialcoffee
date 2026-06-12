class CoffeeReference {
  const CoffeeReference({
    required this.id,
    required this.ownerId,
    required this.name,
    this.origin,
    this.farmer,
    this.processType,
    required this.roastLevel,
    this.roastDate,
    this.packagedDate,
    this.grindNotes,
    this.tasteNotes,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  final String    id;
  final String    ownerId;
  final String    name;
  final String?   origin;
  final String?   farmer;
  final String?   processType;
  final String    roastLevel;
  final DateTime? roastDate;
  final DateTime? packagedDate;
  final String?   grindNotes;
  final String?   tasteNotes;
  final String    status;
  final DateTime  createdAt;
  final DateTime  updatedAt;

  // Calculated — not stored; uses packagedDate as fallback for beans without explicit roast date
  int? get daysSinceRoast {
    final base = roastDate ?? packagedDate;
    if (base == null) return null;
    return DateTime.now().difference(base).inDays;
  }
}
