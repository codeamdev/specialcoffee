class LotCertification {
  const LotCertification({
    required this.id,
    required this.lotId,
    required this.type,
    this.issuingBody,
    this.validFrom,
    this.validUntil,
    this.certificateUrl,
  });

  final String    id;
  final String    lotId;
  // 'organico'|'fairtrade'|'rainforest'|'cup_of_excellence'|'otros'
  final String    type;
  final String?   issuingBody;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String?   certificateUrl;

  bool get isActive {
    if (validUntil == null) return true;
    return validUntil!.isAfter(DateTime.now());
  }
}
