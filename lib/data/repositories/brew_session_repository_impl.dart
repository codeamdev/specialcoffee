import 'package:special_coffee/core/config/api_config.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/domain/entities/brew_session.dart';
import 'package:special_coffee/domain/repositories/brew_session_repository.dart';

class PostgRESTBrewSessionRepository implements BrewSessionRepository {
  final ApiClient _client;

  PostgRESTBrewSessionRepository(this._client);

  @override
  Future<BrewSession> create({
    required String userId,
    required String method,
    String? lotId,
    required bool   aiRecipeGenerated,
    double? aiDoseG,
    double? aiWaterG,
    double? aiRatio,
    double? aiWaterTempC,
    double? aiGrindSetting,
    double? aiBloomG,
    int?    aiBloomSeconds,
    int?    aiTotalTimeTargetS,
    double? aiTdsTargetMin,
    double? aiTdsTargetMax,
    double? aiYieldTargetMin,
    double? aiYieldTargetMax,
    String? aiRecipeVersion,
    Map<String, dynamic>? aiRecipeBasedOn,
  }) async {
    // Obtener session_number del usuario para este método
    final countResponse = await _client.get<List<dynamic>>(
      ApiConfig.brewSessions,
      params: {
        'user_id': 'eq.$userId',
        'method':  'eq.$method',
        'select':  'id',
      },
    );
    final sessionNumber = ((countResponse.data ?? []).length) + 1;

    final payload = <String, dynamic>{
      'user_id':              userId,
      'method':               method,
      'session_number':       sessionNumber,
      'ai_recipe_generated':  aiRecipeGenerated,
      if (lotId            != null) 'lot_id':               lotId,
      if (aiDoseG          != null) 'ai_dose_g':            aiDoseG,
      if (aiWaterG         != null) 'ai_water_g':           aiWaterG,
      if (aiRatio          != null) 'ai_ratio':             aiRatio,
      if (aiWaterTempC     != null) 'ai_water_temp_c':      aiWaterTempC,
      if (aiGrindSetting   != null) 'ai_grind_setting':     aiGrindSetting,
      if (aiBloomG         != null) 'ai_bloom_g':           aiBloomG,
      if (aiBloomSeconds   != null) 'ai_bloom_seconds':     aiBloomSeconds,
      if (aiTotalTimeTargetS != null) 'ai_total_time_target_s': aiTotalTimeTargetS,
      if (aiTdsTargetMin   != null) 'ai_tds_target_min':    aiTdsTargetMin,
      if (aiTdsTargetMax   != null) 'ai_tds_target_max':    aiTdsTargetMax,
      if (aiYieldTargetMin != null) 'ai_yield_target_min':  aiYieldTargetMin,
      if (aiYieldTargetMax != null) 'ai_yield_target_max':  aiYieldTargetMax,
      if (aiRecipeVersion  != null) 'ai_recipe_version':    aiRecipeVersion,
      if (aiRecipeBasedOn  != null) 'ai_recipe_based_on':   aiRecipeBasedOn,
    };

    final response = await _client.post<List<dynamic>>(
      ApiConfig.brewSessions,
      data: payload,
    );

    final list = response.data;
    if (list != null && list.isNotEmpty) {
      return BrewSession.fromJson(list.first as Map<String, dynamic>);
    }
    throw Exception('No se pudo crear la sesión de preparación');
  }

  @override
  Future<BrewSession> updateResult({
    required String sessionId,
    required double tdsPct,
    required double extractionYieldPct,
    required bool   tdsInTarget,
    String? aiSessionQuality,
    Map<String, dynamic>? aiDiagnosis,
  }) async {
    final response = await _client.patch<List<dynamic>>(
      ApiConfig.brewSessions,
      data: {
        'tds_pct':              tdsPct,
        'extraction_yield_pct': extractionYieldPct,
        'tds_in_target':        tdsInTarget,
        if (aiSessionQuality != null) 'ai_session_quality': aiSessionQuality,
        if (aiDiagnosis      != null) 'ai_diagnosis':       aiDiagnosis,
      },
    );

    final list = response.data;
    if (list != null && list.isNotEmpty) {
      return BrewSession.fromJson(list.first as Map<String, dynamic>);
    }
    throw Exception('No se pudo actualizar la sesión');
  }

  @override
  Future<List<BrewSession>> getUserSessions({
    required String userId,
    String? method,
    int limit = 20,
  }) async {
    final response = await _client.get<List<dynamic>>(
      ApiConfig.brewSessions,
      params: {
        'user_id': 'eq.$userId',
        if (method != null) 'method': 'eq.$method',
        'order':   'created_at.desc',
        'limit':   '$limit',
      },
    );

    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(BrewSession.fromJson)
        .toList();
  }
}
