class RoastProfile {
  const RoastProfile({
    required this.id,
    required this.lotId,
    required this.roastedBy,
    required this.roastedAt,
    this.greenWeightKg,
    this.roastedWeightKg,
    this.roastLossPct,
    this.chargeTempC,
    this.dropTempC,
    this.firstCrackTimeS,
    this.firstCrackTempC,
    this.developmentTimeS,
    this.totalTimeS,
    this.dtrPct,
    this.agtronWhole,
    this.agtronGround,
    this.colorLabel,
    this.roastNotes,
  });

  final String    id;
  final String    lotId;
  final String    roastedBy;
  final DateTime  roastedAt;
  final double?   greenWeightKg;
  final double?   roastedWeightKg;
  final double?   roastLossPct;
  final double?   chargeTempC;
  final double?   dropTempC;
  final int?      firstCrackTimeS;
  final double?   firstCrackTempC;
  final int?      developmentTimeS;
  final int?      totalTimeS;
  final double?   dtrPct;
  final int?      agtronWhole;
  final int?      agtronGround;
  final String?   colorLabel;
  final String?   roastNotes;
}
