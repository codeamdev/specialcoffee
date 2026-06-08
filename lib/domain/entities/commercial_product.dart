class CommercialProduct {
  const CommercialProduct({
    required this.id,
    required this.roastedInventoryId,
    required this.name,
    required this.createdAt,
    this.description,
    this.formatG = 250,
    this.unitsProduced = 0,
    this.unitsAvailable = 0,
    this.costUsd,
    this.priceUsd,
    this.packagedDate,
    this.barcode,
  });

  final String    id;
  final String    roastedInventoryId;
  final String    name;
  final String?   description;
  final int       formatG;
  final int       unitsProduced;
  final int       unitsAvailable;
  final double?   costUsd;
  final double?   priceUsd;
  final DateTime? packagedDate;
  final String?   barcode;
  final DateTime  createdAt;

  double? get marginPct {
    if (costUsd == null || priceUsd == null || costUsd! <= 0) return null;
    return (priceUsd! - costUsd!) / costUsd! * 100;
  }
}
