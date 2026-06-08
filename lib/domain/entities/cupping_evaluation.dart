class CuppingEvaluation {
  const CuppingEvaluation({
    required this.id,
    required this.lotId,
    required this.cupperId,
    required this.cuppedAt,
    this.roastProfileId,
    this.fragranceAroma,
    this.flavor,
    this.aftertaste,
    this.acidity,
    this.acidityIntensity,
    this.body,
    this.bodyTexture,
    this.balance,
    this.uniformity,
    this.cleanCup,
    this.sweetness,
    this.overall,
    this.defectsTaint = 0,
    this.defectsFault = 0,
    this.totalScore,
    this.flavorDescriptors,
    this.notes,
  });

  final String    id;
  final String    lotId;
  final String    cupperId;
  final DateTime  cuppedAt;
  final String?   roastProfileId;
  final double?   fragranceAroma;
  final double?   flavor;
  final double?   aftertaste;
  final double?   acidity;
  final double?   acidityIntensity;
  final double?   body;
  final double?   bodyTexture;
  final double?   balance;
  final double?   uniformity;
  final double?   cleanCup;
  final double?   sweetness;
  final double?   overall;
  final int       defectsTaint;
  final int       defectsFault;
  final double?   totalScore;
  final String?   flavorDescriptors;
  final String?   notes;
}
