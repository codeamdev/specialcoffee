import 'package:flutter/foundation.dart';
import 'package:special_coffee/core/config/api_config.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/data/sync/sync_data_source.dart';

// PostgREST: UPSERT silencioso si el registro ya existe (mismo id).
const _prefer = {'Prefer': 'resolution=ignore-duplicates,return=minimal'};

/// Sincroniza datos locales (synced_at = NULL) con PostgREST en background.
/// Nunca bloquea el flujo del usuario — siempre se llama sin await.
/// Si el backend no está disponible: deja synced_at = NULL para el siguiente intento.
class SyncService {
  SyncService(this._dataSource, this._client);

  final SyncDataSource _dataSource;
  final ApiClient      _client;

  Future<void> syncPendingReadings() async {
    if (ApiConfig.devBypass) return;
    await Future.wait([
      _syncFermentationReadings(),
      _syncDryingReadings(),
      _syncLots(),
      _syncCosechaPases(),
      _syncFermentationSessions(),
      _syncDryingSessions(),
      _syncWashingSessions(),
      _syncMillingSessions(),
      _syncClassificationSessions(),
    ]);
  }

  // ── Readings (pre-existentes) ─────────────────────────────────────────────

  Future<void> _syncFermentationReadings() async {
    try {
      final pending = await _dataSource.getUnsyncedFermentationReadings();
      for (final r in pending) {
        try {
          await _client.post<void>(
            ApiConfig.fermentationReadings,
            headers: _prefer,
            data: {
              'id':                 r.id,
              'session_id':         r.sessionId,
              'lot_id':             r.lotId,
              'owner_id':           r.ownerId,
              'reading_number':     r.readingNumber,
              'hours_elapsed':      r.hoursElapsed,
              'ph_value':           r.phValue,
              'mucilago_temp_c':    r.mucilagoTempC,
              if (r.ambientTempC != null) 'ambient_temp_c': r.ambientTempC,
              'mucilage_state':     r.mucilageState,
              'ai_evaluated':       true,
              'ai_alert_level':     r.aiAlertLevel,
              if (r.aiAlertRuleId   != null) 'ai_alert_rule_id':   r.aiAlertRuleId,
              if (r.aiProjectedEndH != null) 'ai_projected_end_h': r.aiProjectedEndH,
              'recorded_at': r.recordedAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markFermentationSynced(r.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] fermentation reading ${r.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncFermentationReadings: $e\n$st');
    }
  }

  Future<void> _syncDryingReadings() async {
    try {
      final pending = await _dataSource.getUnsyncedDryingReadings();
      for (final r in pending) {
        try {
          await _client.post<void>(
            ApiConfig.dryingReadings,
            headers: _prefer,
            data: {
              'id':                   r.id,
              'session_id':           r.sessionId,
              'lot_id':               r.lotId,
              'owner_id':             r.ownerId,
              'moisture_pct':         r.moisturePct,
              'ambient_temp_c':       r.ambientTempC,
              'ambient_humidity_pct': r.ambientHumidityPct,
              'uv_index':             r.uvIndex,
              if (r.aiRecommendation != null) 'ai_recommendation': r.aiRecommendation,
              'recorded_at': r.recordedAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markDryingSynced(r.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] drying reading ${r.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncDryingReadings: $e\n$st');
    }
  }

  // ── Lots ──────────────────────────────────────────────────────────────────

  Future<void> _syncLots() async {
    try {
      final pending = await _dataSource.getUnsyncedLots();
      for (final lot in pending) {
        try {
          await _client.post<void>(
            ApiConfig.lots,
            headers: _prefer,
            data: {
              'id':            lot.id,
              'owner_id':      lot.userId,
              'variety_id':    lot.varietyId,
              'variety_name':  lot.varietyName,
              'altitude_masl': lot.altitudeMasl,
              'region':        lot.region,
              if (lot.notes != null) 'notes': lot.notes,
              // 'status' omitted → PG default 'pending' (CHECK constraint rejects 'activo')
              // 'process_type' omitted → PG default 'lavado' (CHECK constraint rejects '')
              'created_at':    lot.createdAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markLotSynced(lot.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] lot ${lot.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncLots: $e\n$st');
    }
  }

  // ── Cosecha pases ─────────────────────────────────────────────────────────

  Future<void> _syncCosechaPases() async {
    try {
      final pending = await _dataSource.getUnsyncedCosechaPases();
      for (final p in pending) {
        try {
          await _client.post<void>(
            ApiConfig.cosechaPases,
            headers: _prefer,
            data: {
              'id':              p.id,
              'lot_id':          p.lotId,
              'owner_id':        p.createdBy,
              'fecha_recoleccion': p.fechaRecoleccion.toUtc().toIso8601String(),
              if (p.horaInicio != null) 'hora_inicio': p.horaInicio!.toUtc().toIso8601String(),
              if (p.horaFin    != null) 'hora_fin':    p.horaFin!.toUtc().toIso8601String(),
              'peso_cereza_kg':  p.pesoCerezaKg,
              if (p.numOperarios    != null) 'num_operarios':     p.numOperarios,
              if (p.brixPromedio    != null) 'brix_promedio':     p.brixPromedio,
              if (p.pctMadurezVisual != null) 'pct_madurez_visual': p.pctMadurezVisual,
              'tipo_proceso':    p.tipoProceso,
              if (p.pesoFlotacionKg        != null) 'peso_flotacion_kg':          p.pesoFlotacionKg,
              if (p.pctFlotacion           != null) 'pct_flotacion':              p.pctFlotacion,
              if (p.pesoPergaminoHumedoKg  != null) 'peso_pergamino_humedo_kg':   p.pesoPergaminoHumedoKg,
              if (p.horasHastaDespulpe     != null) 'horas_hasta_despulpe':       p.horasHastaDespulpe,
              'etapa_actual':    p.etapaActual,
              'status':          p.status,
              if (p.notas != null) 'notas': p.notas,
              'created_at':      p.createdAt.toUtc().toIso8601String(),
              'updated_at':      p.updatedAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markCosechaPaseSynced(p.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] cosecha_pase ${p.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncCosechaPases: $e\n$st');
    }
  }

  // ── Fermentation sessions ─────────────────────────────────────────────────

  Future<void> _syncFermentationSessions() async {
    try {
      final pending = await _dataSource.getUnsyncedFermentationSessions();
      for (final s in pending) {
        try {
          await _client.post<void>(
            ApiConfig.fermentationSessions,
            headers: _prefer,
            data: {
              'id':           s.id,
              'lot_id':       s.lotId,
              'owner_id':     s.ownerId,
              'process_type': s.processType,
              'started_at':   s.startedAt.toUtc().toIso8601String(),
              if (s.endedAt          != null) 'ended_at':          s.endedAt!.toUtc().toIso8601String(),
              if (s.actualDurationH  != null) 'actual_duration_h': s.actualDurationH,
              if (s.endReason        != null) 'end_reason':        s.endReason,
              if (s.phInitial        != null) 'ph_initial':        s.phInitial,
              if (s.phFinal          != null) 'ph_final':          s.phFinal,
              'created_at':   s.createdAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markFermentationSessionSynced(s.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] fermentation_session ${s.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncFermentationSessions: $e\n$st');
    }
  }

  // ── Drying sessions ───────────────────────────────────────────────────────

  Future<void> _syncDryingSessions() async {
    try {
      final pending = await _dataSource.getUnsyncedDryingSessions();
      for (final s in pending) {
        try {
          await _client.post<void>(
            ApiConfig.dryingSessions,
            headers: _prefer,
            data: {
              'id':       s.id,
              'lot_id':   s.lotId,
              'owner_id': s.ownerId,
              'method':   s.dryingMethod,
              'started_at': s.startedAt.toUtc().toIso8601String(),
              if (s.endedAt           != null) 'ended_at':           s.endedAt!.toUtc().toIso8601String(),
              if (s.finalMoisturePct  != null) 'humidity_final_pct': s.finalMoisturePct,
              'created_at': s.createdAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markDryingSessionSynced(s.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] drying_session ${s.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncDryingSessions: $e\n$st');
    }
  }

  // ── Washing sessions ──────────────────────────────────────────────────────

  Future<void> _syncWashingSessions() async {
    try {
      final pending = await _dataSource.getUnsyncedWashingSessions();
      for (final s in pending) {
        try {
          await _client.post<void>(
            ApiConfig.washingSessions,
            headers: _prefer,
            data: {
              'id':                         s.id,
              'lot_id':                     s.lotId,
              'owner_id':                   s.ownerId,
              if (s.fermentationSessionId != null) 'fermentation_session_id': s.fermentationSessionId,
              'water_temp_c':               s.waterTempC,
              'water_changes':              s.waterChanges,
              'effluent_ph_final':          s.effluentPhFinal,
              'duration_h':                 s.durationH,
              'washed_at':                  s.washedAt.toUtc().toIso8601String(),
              'ai_alert_level':             s.aiAlertLevel,
              if (s.aiAlertMessage != null) 'ai_alert_message': s.aiAlertMessage,
              if (s.notes          != null) 'notes':            s.notes,
              'created_at':                 s.createdAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markWashingSessionSynced(s.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] washing_session ${s.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncWashingSessions: $e\n$st');
    }
  }

  // ── Milling sessions ──────────────────────────────────────────────────────

  Future<void> _syncMillingSessions() async {
    try {
      final pending = await _dataSource.getUnsyncedMillingSessions();
      for (final s in pending) {
        try {
          await _client.post<void>(
            ApiConfig.millingSessions,
            headers: _prefer,
            data: {
              'id':                  s.id,
              'lot_id':              s.lotId,
              'owner_id':            s.ownerId,
              'input_kg_parchment':  s.inputKgParchment,
              'output_kg_green':     s.outputKgGreen,
              'yield_pct':           s.yieldPct,
              'ai_alert_level':      s.aiAlertLevel,
              if (s.aiAlertMessage != null) 'ai_alert_message': s.aiAlertMessage,
              if (s.notes          != null) 'notes':            s.notes,
              'created_at':          s.createdAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markMillingSessionSynced(s.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] milling_session ${s.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncMillingSessions: $e\n$st');
    }
  }

  // ── Classification sessions ───────────────────────────────────────────────

  Future<void> _syncClassificationSessions() async {
    try {
      final pending = await _dataSource.getUnsyncedClassificationSessions();
      for (final s in pending) {
        try {
          await _client.post<void>(
            ApiConfig.classificationSessions,
            headers: _prefer,
            data: {
              'id':                    s.id,
              'lot_id':                s.lotId,
              'owner_id':              s.ownerId,
              if (s.harvestSessionId != null) 'harvest_session_id': s.harvestSessionId,
              'kg_entrada':            s.kgEntrada,
              if (s.brixCereza       != null) 'brix_cereza':        s.brixCereza,
              'kg_flotantes':          s.kgFlotantes,
              'kg_descarte_manual':    s.kgDescarteManual,
              'ai_alert_level':        s.aiAlertLevel,
              if (s.aiAlertMessage   != null) 'ai_alert_message':   s.aiAlertMessage,
              if (s.notes            != null) 'notes':              s.notes,
              'classified_at':         s.classifiedAt.toUtc().toIso8601String(),
              'created_at':            s.createdAt.toUtc().toIso8601String(),
            },
          );
          await _dataSource.markClassificationSessionSynced(s.id);
        } catch (e, st) {
          if (kDebugMode) debugPrint('[Sync] classification_session ${s.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Sync] _syncClassificationSessions: $e\n$st');
    }
  }
}
