import 'package:special_coffee/core/config/api_config.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/domain/repositories/lot_repository.dart';

/// PostgREST returns snake_case column names. _fromRow maps them manually
/// instead of relying on Lot.fromJson which expects camelCase keys.
class PostgRESTLotRepository implements LotRepository {
  final ApiClient _client;

  PostgRESTLotRepository(this._client);

  @override
  Future<List<Lot>> getLots(String userId) async {
    final response = await _client.get<List<dynamic>>(
      ApiConfig.lots,
      params: {
        'owner_id': 'eq.$userId',
        'order':    'created_at.desc',
        'select':   '*',
      },
    );
    final data = response.data ?? [];
    return data.cast<Map<String, dynamic>>().map(_fromRow).toList();
  }

  @override
  Future<Lot> saveLot(Lot lot) async {
    await _client.post<dynamic>(ApiConfig.lots, data: _toPayload(lot));
    return lot;
  }

  @override
  Future<void> deleteLot(String lotId) async {
    await _client.delete(ApiConfig.lots, params: {'id': 'eq.$lotId'});
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  static Lot _fromRow(Map<String, dynamic> r) => Lot(
    id:                 r['id']                                    as String,
    userId:             r['owner_id']                              as String,
    varietyId:          (r['variety_id']          as String?)    ?? 'unknown',
    varietyName:        (r['variety_name']         as String?)    ?? 'Desconocida',
    altitudeMasl:       (r['altitude_masl']        as num?)?.toInt()    ?? 0,
    region:             (r['region']               as String?)    ?? '',
    processType:        (r['process_type']         as String?)    ?? 'lavado',
    ambientTempC:       (r['ambient_temp_c']       as num?)?.toDouble() ?? 18.0,
    ambientHumidityPct: (r['ambient_humidity_pct'] as num?)?.toDouble() ?? 70.0,
    rainProbabilityPct: (r['rain_probability_pct'] as num?)?.toDouble() ?? 0.0,
    status:             (r['status']               as String?)    ?? 'pending',
    notes:              r['notes']                                as String?,
    createdAt:          r['created_at'] != null
        ? DateTime.parse(r['created_at'] as String).toLocal()
        : DateTime.now(),
  );

  static Map<String, dynamic> _toPayload(Lot lot) => {
    'id':                   lot.id,
    'owner_id':             lot.userId,
    'variety_id':           lot.varietyId,
    'variety_name':         lot.varietyName,
    'altitude_masl':        lot.altitudeMasl,
    'region':               lot.region,
    'process_type':         lot.processType,
    'ambient_temp_c':       lot.ambientTempC,
    'ambient_humidity_pct': lot.ambientHumidityPct,
    'rain_probability_pct': lot.rainProbabilityPct,
    'status':               lot.status,
    'notes':                lot.notes,
    'created_at':           lot.createdAt.toUtc().toIso8601String(),
    'updated_at':           DateTime.now().toUtc().toIso8601String(),
  };
}
