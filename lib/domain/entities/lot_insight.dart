class LotInsight {
  const LotInsight({
    required this.id,
    required this.lotId,
    required this.ownerId,
    required this.scaScore,
    this.fermentationH,
    this.phFinal,
    required this.insightText,
    required this.createdAt,
  });

  final String   id;
  final String   lotId;
  final String   ownerId;
  final double   scaScore;
  final double?  fermentationH;
  final double?  phFinal;
  final String   insightText;
  final DateTime createdAt;
}
