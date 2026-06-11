import 'package:special_coffee/core/config/api_config.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/domain/entities/fermentation_session.dart';
import 'package:special_coffee/domain/repositories/fermentation_repository.dart';

class PostgRESTFermentationRepository implements FermentationRepository {
  final ApiClient _client;
  final String    _ownerId;

  PostgRESTFermentationRepository(this._client, this._ownerId);

  @override
  Future<FermentationSession> createSession({
    required String lotId,
    required String processType,
  }) async {
    final response = await _client.post<List<dynamic>>(
      ApiConfig.fermentationSessions,
      data: {
        'lot_id':       lotId,
        'owner_id':     _ownerId,
        'process_type': processType,
        'started_at':   DateTime.now().toUtc().toIso8601String(),
      },
    );

    final list = response.data;
    if (list != null && list.isNotEmpty) {
      return FermentationSession.fromJson(list.first as Map<String, dynamic>);
    }
    throw Exception('No se pudo crear la sesión de fermentación');
  }

  @override
  Future<FermentationSession?> getActiveSession(String lotId) async {
    final response = await _client.get<List<dynamic>>(
      ApiConfig.fermentationSessions,
      params: {
        'lot_id':    'eq.$lotId',
        'ended_at':  'is.null',
        'order':     'created_at.desc',
        'limit':     '1',
      },
    );

    final list = response.data ?? [];
    if (list.isEmpty) return null;
    return FermentationSession.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Future<FermentationReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int    readingNumber,
    required double hoursElapsed,
    required double phValue,
    required double mucilagoTempC,
    String  mucilageState  = 'liquid',
    double? ambientTempC,
    String  aiAlertLevel   = 'none',
    String? aiAlertRuleId,
    double? aiProjectedEndH,
  }) async {
    final response = await _client.post<List<dynamic>>(
      ApiConfig.fermentationReadings,
      data: {
        'session_id':         sessionId,
        'lot_id':             lotId,
        'owner_id':           _ownerId,
        'reading_number':     readingNumber,
        'hours_elapsed':      hoursElapsed,
        'ph_value':           phValue,
        'mucilago_temp_c':    mucilagoTempC,
        'mucilage_state':     mucilageState,
        if (ambientTempC != null) 'ambient_temp_c': ambientTempC,
        'ai_evaluated':       true,
        'ai_alert_level':     aiAlertLevel,
        if (aiAlertRuleId   != null) 'ai_alert_rule_id':  aiAlertRuleId,
        if (aiProjectedEndH != null) 'ai_projected_end_h': aiProjectedEndH,
        'recorded_at':        DateTime.now().toUtc().toIso8601String(),
      },
    );

    final list = response.data;
    if (list != null && list.isNotEmpty) {
      return FermentationReadingRecord.fromJson(
          list.first as Map<String, dynamic>);
    }
    throw Exception('No se pudo guardar la lectura');
  }

  @override
  Future<List<FermentationReadingRecord>> getReadings(String sessionId) async {
    final response = await _client.get<List<dynamic>>(
      ApiConfig.fermentationReadings,
      params: {
        'session_id': 'eq.$sessionId',
        'order':      'hours_elapsed.asc',
      },
    );

    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(FermentationReadingRecord.fromJson)
        .toList();
  }

  @override
  Future<void> closeSession({
    required String sessionId,
    required String endReason,
    required double actualDurationH,
    required double phFinal,
  }) async {
    await _client.patch(
      ApiConfig.fermentationSessions,
      data: {
        'ended_at':          DateTime.now().toUtc().toIso8601String(),
        'end_reason':        endReason,
        'actual_duration_h': actualDurationH,
        'ph_final':          phFinal,
      },
    );
  }

  @override
  Future<double> getAvgCompletedDurationH() async => 0.0;

  @override
  Future<double> getLastCompletedDurationH() async => 0.0;
}
