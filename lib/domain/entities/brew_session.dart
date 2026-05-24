// Entidad de dominio para sesiones de preparación (barista).

class BrewSession {
  final String  id;
  final String  userId;
  final String? lotId;
  final String  method;
  final int     sessionNumber;
  final bool    aiRecipeGenerated;
  // Receta IA
  final double? aiDoseG;
  final double? aiWaterG;
  final double? aiRatio;
  final double? aiWaterTempC;
  final double? aiGrindSetting;
  final double? aiBloomG;
  final int?    aiBloomSeconds;
  final int?    aiTotalTimeTargetS;
  final double? aiTdsTargetMin;
  final double? aiTdsTargetMax;
  final double? aiYieldTargetMin;
  final double? aiYieldTargetMax;
  final String? aiRecipeVersion;
  // Resultado
  final double? tdsPct;
  final double? extractionYieldPct;
  final bool?   tdsInTarget;
  // Diagnóstico IA
  final String? aiSessionQuality;
  final DateTime createdAt;

  const BrewSession({
    required this.id,
    required this.userId,
    this.lotId,
    required this.method,
    required this.sessionNumber,
    this.aiRecipeGenerated = false,
    this.aiDoseG,
    this.aiWaterG,
    this.aiRatio,
    this.aiWaterTempC,
    this.aiGrindSetting,
    this.aiBloomG,
    this.aiBloomSeconds,
    this.aiTotalTimeTargetS,
    this.aiTdsTargetMin,
    this.aiTdsTargetMax,
    this.aiYieldTargetMin,
    this.aiYieldTargetMax,
    this.aiRecipeVersion,
    this.tdsPct,
    this.extractionYieldPct,
    this.tdsInTarget,
    this.aiSessionQuality,
    required this.createdAt,
  });

  factory BrewSession.fromJson(Map<String, dynamic> json) => BrewSession(
        id:                 json['id']              as String,
        userId:             json['user_id']          as String,
        lotId:              json['lot_id']            as String?,
        method:             json['method']            as String,
        sessionNumber:      json['session_number']    as int,
        aiRecipeGenerated:  (json['ai_recipe_generated'] as bool?) ?? false,
        aiDoseG:            (json['ai_dose_g']        as num?)?.toDouble(),
        aiWaterG:           (json['ai_water_g']       as num?)?.toDouble(),
        aiRatio:            (json['ai_ratio']         as num?)?.toDouble(),
        aiWaterTempC:       (json['ai_water_temp_c']  as num?)?.toDouble(),
        aiGrindSetting:     (json['ai_grind_setting'] as num?)?.toDouble(),
        aiBloomG:           (json['ai_bloom_g']       as num?)?.toDouble(),
        aiBloomSeconds:     json['ai_bloom_seconds']   as int?,
        aiTotalTimeTargetS: json['ai_total_time_target_s'] as int?,
        aiTdsTargetMin:     (json['ai_tds_target_min'] as num?)?.toDouble(),
        aiTdsTargetMax:     (json['ai_tds_target_max'] as num?)?.toDouble(),
        aiYieldTargetMin:   (json['ai_yield_target_min'] as num?)?.toDouble(),
        aiYieldTargetMax:   (json['ai_yield_target_max'] as num?)?.toDouble(),
        aiRecipeVersion:    json['ai_recipe_version']  as String?,
        tdsPct:             (json['tds_pct']           as num?)?.toDouble(),
        extractionYieldPct: (json['extraction_yield_pct'] as num?)?.toDouble(),
        tdsInTarget:        json['tds_in_target']      as bool?,
        aiSessionQuality:   json['ai_session_quality'] as String?,
        createdAt:          DateTime.parse(json['created_at'] as String),
      );
}
