import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:special_coffee/core/config/api_config.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/data/sync/sync_data_source.dart';
import 'package:special_coffee/data/sync/sync_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSyncDataSource extends Mock implements SyncDataSource {}
class MockApiClient      extends Mock implements ApiClient {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

DbFermentationReading _fermReading({String id = 'fr-1'}) => DbFermentationReading(
  id: id, sessionId: 'sess-1', lotId: 'lot-1', ownerId: 'user-1',
  readingNumber: 1, hoursElapsed: 8.0, phValue: 4.2, mucilagoTempC: 22.0,
  ambientTempC: null, mucilageState: 'liquid', aiAlertLevel: 'none',
  aiAlertRuleId: null, aiProjectedEndH: null,
  recordedAt: DateTime(2026, 6, 1, 10), updatedAt: DateTime(2026, 6, 1, 10),
  syncedAt: null,
);

DbDryingReading _dryReading({String id = 'dr-1'}) => DbDryingReading(
  id: id, sessionId: 'dry-1', lotId: 'lot-1', ownerId: 'user-1',
  moisturePct: 35.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
  uvIndex: 4.0, aiRecommendation: null,
  recordedAt: DateTime(2026, 6, 1, 11), updatedAt: DateTime(2026, 6, 1, 11),
  syncedAt: null,
);

DbLocalLot _lot({String id = 'lot-1'}) => DbLocalLot(
  id: id, userId: 'user-1', varietyId: 'var-1', varietyName: 'Caturra',
  altitudeMasl: 1500, region: 'Huila', processType: '',
  latitude: null, longitude: null, farmAreaHa: null,
  blendVarietyIds: null, plantAgeYears: null, plantType: null,
  createdAt: DateTime(2026, 6, 1), notes: null, deletedAt: null,
  syncedAt: null,
);

DbCosechaPase _cosechaPase({String id = 'cp-1'}) => DbCosechaPase(
  id: id, lotId: 'lot-1', createdBy: 'user-1',
  fechaRecoleccion: DateTime(2026, 6, 1),
  horaInicio: null, horaFin: null,
  pesoCerezaKg: 200.0, numOperarios: null, brixPromedio: null,
  pctMadurezVisual: null, tipoProceso: 'lavado',
  pesoFlotacionKg: null, pctFlotacion: null,
  pesoPergaminoHumedoKg: null, horasHastaDespulpe: null,
  etapaActual: 'clasificacion', status: 'activo', notas: null,
  createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1),
  deletedAt: null, syncedAt: null,
);

DbFermentationSession _fermSession({String id = 'fs-1'}) => DbFermentationSession(
  id: id, lotId: 'lot-1', ownerId: 'user-1', processType: 'lavado',
  startedAt: DateTime(2026, 6, 1, 8), endedAt: null,
  actualDurationH: null, endReason: null, phInitial: null, phFinal: null,
  createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1),
  syncedAt: null, deletedAt: null,
);

DbDryingSession _drySession({String id = 'ds-1'}) => DbDryingSession(
  id: id, lotId: 'lot-1', ownerId: 'user-1', dryingMethod: 'solar',
  startedAt: DateTime(2026, 6, 2), endedAt: null,
  targetMoisturePct: 11.0, finalMoisturePct: null,
  createdAt: DateTime(2026, 6, 2), updatedAt: DateTime(2026, 6, 2),
  syncedAt: null, deletedAt: null,
);

DbWashingSession _washSession({String id = 'ws-1'}) => DbWashingSession(
  id: id, lotId: 'lot-1', ownerId: 'user-1',
  fermentationSessionId: null,
  waterTempC: 18.0, waterChanges: 3, effluentPhFinal: 5.5, durationH: 2.0,
  washedAt: DateTime(2026, 6, 1, 14),
  aiAlertLevel: 'none', aiAlertMessage: null, notes: null,
  createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1),
  syncedAt: null,
);

DbMillingSession _millSession({String id = 'ms-1'}) => DbMillingSession(
  id: id, lotId: 'lot-1', ownerId: 'user-1',
  inputKgParchment: 100.0, outputKgGreen: 80.0, yieldPct: 80.0,
  aiAlertLevel: 'none', aiAlertMessage: null, notes: null,
  createdAt: DateTime(2026, 6, 3), updatedAt: DateTime(2026, 6, 3),
  syncedAt: null,
);

DbClassificationSession _classifSession({String id = 'cs-1'}) => DbClassificationSession(
  id: id, lotId: 'lot-1', ownerId: 'user-1', harvestSessionId: null,
  kgEntrada: 200.0, brixCereza: null,
  kgFlotantes: 5.0, kgDescarteManual: 2.0,
  aiAlertLevel: 'none', aiAlertMessage: null, notes: null,
  classifiedAt: DateTime(2026, 6, 1, 9),
  createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1),
  syncedAt: null,
);

Response<void> _ok() => Response<void>(
  requestOptions: RequestOptions(path: ''), statusCode: 201,
);

// ── Helper: stub vacío para todas las entidades ────────────────────────────────

void _stubAllEmpty(MockSyncDataSource ds) {
  when(() => ds.getUnsyncedFermentationReadings()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedDryingReadings()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedLots()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedCosechaPases()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedFermentationSessions()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedDryingSessions()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedWashingSessions()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedMillingSessions()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedClassificationSessions()).thenAnswer((_) async => []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSyncDataSource ds;
  late MockApiClient      client;
  late SyncService        svc;

  setUp(() {
    ds     = MockSyncDataSource();
    client = MockApiClient();
    svc    = SyncService(ds, client);
    registerFallbackValue(<String, dynamic>{});
  });

  // ── sin datos pendientes ──────────────────────────────────────────────────

  group('sin datos pendientes', () {
    test('no hace ninguna llamada HTTP cuando todo está vacío', () async {
      _stubAllEmpty(ds);

      await svc.syncPendingReadings();

      verifyNever(() => client.post<void>(
        any(), data: any(named: 'data'), headers: any(named: 'headers'),
      ));
    });
  });

  // ── Fermentation readings (pre-existentes) ────────────────────────────────

  group('fermentation readings', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markFermentationSynced llamado', () async {
      final r = _fermReading();
      when(() => ds.getUnsyncedFermentationReadings()).thenAnswer((_) async => [r]);
      when(() => client.post<void>(ApiConfig.fermentationReadings,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markFermentationSynced(r.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markFermentationSynced(r.id)).called(1);
    });

    test('POST falla → markSynced no se llama, no lanza', () async {
      when(() => ds.getUnsyncedFermentationReadings())
          .thenAnswer((_) async => [_fermReading()]);
      when(() => client.post<void>(ApiConfig.fermentationReadings,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('network error'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markFermentationSynced(any()));
    });

    test('payload contiene campos requeridos', () async {
      final r = _fermReading(id: 'fr-abc');
      when(() => ds.getUnsyncedFermentationReadings()).thenAnswer((_) async => [r]);
      when(() => client.post<void>(ApiConfig.fermentationReadings,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markFermentationSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      final captured = verify(() => client.post<void>(
        ApiConfig.fermentationReadings,
        data: captureAny(named: 'data'),
        headers: any(named: 'headers'),
      )).captured;
      final p = captured.first as Map<String, dynamic>;
      expect(p['id'],           'fr-abc');
      expect(p['ph_value'],     4.2);
      expect(p['ai_evaluated'], true);
    });

    test('fallo en lectura 1 no impide lectura 2', () async {
      when(() => ds.getUnsyncedFermentationReadings())
          .thenAnswer((_) async => [_fermReading(id: 'fr-fail'), _fermReading(id: 'fr-ok')]);
      var call = 0;
      when(() => client.post<void>(ApiConfig.fermentationReadings,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async { call++; if (call == 1) throw Exception('t'); return _ok(); });
      when(() => ds.markFermentationSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markFermentationSynced('fr-ok')).called(1);
      verifyNever(() => ds.markFermentationSynced('fr-fail'));
    });
  });

  // ── Drying readings ───────────────────────────────────────────────────────

  group('drying readings', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markDryingSynced llamado', () async {
      final r = _dryReading();
      when(() => ds.getUnsyncedDryingReadings()).thenAnswer((_) async => [r]);
      when(() => client.post<void>(ApiConfig.dryingReadings,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markDryingSynced(r.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markDryingSynced(r.id)).called(1);
    });

    test('POST falla → no lanza, markSynced no se llama', () async {
      when(() => ds.getUnsyncedDryingReadings())
          .thenAnswer((_) async => [_dryReading()]);
      when(() => client.post<void>(ApiConfig.dryingReadings,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('timeout'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markDryingSynced(any()));
    });
  });

  // ── Lots ──────────────────────────────────────────────────────────────────

  group('lots', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markLotSynced llamado', () async {
      final l = _lot();
      when(() => ds.getUnsyncedLots()).thenAnswer((_) async => [l]);
      when(() => client.post<void>(ApiConfig.lots,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markLotSynced(l.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markLotSynced(l.id)).called(1);
    });

    test('payload mapea user_id → owner_id y envía status=activo', () async {
      final l = _lot(id: 'lot-abc');
      when(() => ds.getUnsyncedLots()).thenAnswer((_) async => [l]);
      when(() => client.post<void>(ApiConfig.lots,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markLotSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      final captured = verify(() => client.post<void>(
        ApiConfig.lots,
        data: captureAny(named: 'data'),
        headers: any(named: 'headers'),
      )).captured;
      final p = captured.first as Map<String, dynamic>;
      expect(p['id'],        'lot-abc');
      expect(p['owner_id'],  'user-1');
      expect(p['status'],    'activo');
      expect(p['variety_name'], 'Caturra');
    });

    test('POST falla → markLotSynced no se llama, no lanza', () async {
      when(() => ds.getUnsyncedLots()).thenAnswer((_) async => [_lot()]);
      when(() => client.post<void>(ApiConfig.lots,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('network'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markLotSynced(any()));
    });
  });

  // ── Cosecha pases ─────────────────────────────────────────────────────────

  group('cosecha pases', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markCosechaPaseSynced llamado', () async {
      final p = _cosechaPase();
      when(() => ds.getUnsyncedCosechaPases()).thenAnswer((_) async => [p]);
      when(() => client.post<void>(ApiConfig.cosechaPases,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markCosechaPaseSynced(p.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markCosechaPaseSynced(p.id)).called(1);
    });

    test('payload incluye tipo_proceso y etapa_actual', () async {
      final p = _cosechaPase(id: 'cp-xyz');
      when(() => ds.getUnsyncedCosechaPases()).thenAnswer((_) async => [p]);
      when(() => client.post<void>(ApiConfig.cosechaPases,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markCosechaPaseSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      final captured = verify(() => client.post<void>(
        ApiConfig.cosechaPases,
        data: captureAny(named: 'data'),
        headers: any(named: 'headers'),
      )).captured;
      final payload = captured.first as Map<String, dynamic>;
      expect(payload['id'],           'cp-xyz');
      expect(payload['tipo_proceso'], 'lavado');
      expect(payload['etapa_actual'], 'clasificacion');
      expect(payload['owner_id'],     'user-1');
    });

    test('POST falla → no lanza', () async {
      when(() => ds.getUnsyncedCosechaPases()).thenAnswer((_) async => [_cosechaPase()]);
      when(() => client.post<void>(ApiConfig.cosechaPases,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('timeout'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markCosechaPaseSynced(any()));
    });
  });

  // ── Fermentation sessions ─────────────────────────────────────────────────

  group('fermentation sessions', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markFermentationSessionSynced llamado', () async {
      final s = _fermSession();
      when(() => ds.getUnsyncedFermentationSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.fermentationSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markFermentationSessionSynced(s.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markFermentationSessionSynced(s.id)).called(1);
    });

    test('payload contiene process_type y owner_id', () async {
      final s = _fermSession(id: 'fs-xyz');
      when(() => ds.getUnsyncedFermentationSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.fermentationSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markFermentationSessionSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      final captured = verify(() => client.post<void>(
        ApiConfig.fermentationSessions,
        data: captureAny(named: 'data'),
        headers: any(named: 'headers'),
      )).captured;
      final p = captured.first as Map<String, dynamic>;
      expect(p['id'],           'fs-xyz');
      expect(p['process_type'], 'lavado');
      expect(p['owner_id'],     'user-1');
    });

    test('POST falla → no lanza', () async {
      when(() => ds.getUnsyncedFermentationSessions())
          .thenAnswer((_) async => [_fermSession()]);
      when(() => client.post<void>(ApiConfig.fermentationSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('net'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markFermentationSessionSynced(any()));
    });
  });

  // ── Drying sessions ───────────────────────────────────────────────────────

  group('drying sessions', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markDryingSessionSynced llamado', () async {
      final s = _drySession();
      when(() => ds.getUnsyncedDryingSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.dryingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markDryingSessionSynced(s.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markDryingSessionSynced(s.id)).called(1);
    });

    test('payload mapea drying_method → method', () async {
      final s = _drySession(id: 'ds-xyz');
      when(() => ds.getUnsyncedDryingSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.dryingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markDryingSessionSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      final captured = verify(() => client.post<void>(
        ApiConfig.dryingSessions,
        data: captureAny(named: 'data'),
        headers: any(named: 'headers'),
      )).captured;
      final p = captured.first as Map<String, dynamic>;
      expect(p['method'], 'solar');
      expect(p.containsKey('drying_method'), isFalse);
    });

    test('POST falla → no lanza', () async {
      when(() => ds.getUnsyncedDryingSessions()).thenAnswer((_) async => [_drySession()]);
      when(() => client.post<void>(ApiConfig.dryingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('net'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markDryingSessionSynced(any()));
    });
  });

  // ── Washing sessions ──────────────────────────────────────────────────────

  group('washing sessions', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markWashingSessionSynced llamado', () async {
      final s = _washSession();
      when(() => ds.getUnsyncedWashingSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.washingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markWashingSessionSynced(s.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markWashingSessionSynced(s.id)).called(1);
    });

    test('payload incluye water_temp_c y effluent_ph_final', () async {
      final s = _washSession(id: 'ws-xyz');
      when(() => ds.getUnsyncedWashingSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.washingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markWashingSessionSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      final captured = verify(() => client.post<void>(
        ApiConfig.washingSessions,
        data: captureAny(named: 'data'),
        headers: any(named: 'headers'),
      )).captured;
      final p = captured.first as Map<String, dynamic>;
      expect(p['water_temp_c'],     18.0);
      expect(p['effluent_ph_final'], 5.5);
    });

    test('POST falla → no lanza', () async {
      when(() => ds.getUnsyncedWashingSessions()).thenAnswer((_) async => [_washSession()]);
      when(() => client.post<void>(ApiConfig.washingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('net'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markWashingSessionSynced(any()));
    });
  });

  // ── Milling sessions ──────────────────────────────────────────────────────

  group('milling sessions', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markMillingSessionSynced llamado', () async {
      final s = _millSession();
      when(() => ds.getUnsyncedMillingSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.millingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markMillingSessionSynced(s.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markMillingSessionSynced(s.id)).called(1);
    });

    test('payload incluye yield_pct', () async {
      final s = _millSession(id: 'ms-xyz');
      when(() => ds.getUnsyncedMillingSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.millingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markMillingSessionSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      final captured = verify(() => client.post<void>(
        ApiConfig.millingSessions,
        data: captureAny(named: 'data'),
        headers: any(named: 'headers'),
      )).captured;
      final p = captured.first as Map<String, dynamic>;
      expect(p['yield_pct'], 80.0);
      expect(p['input_kg_parchment'], 100.0);
    });

    test('POST falla → no lanza', () async {
      when(() => ds.getUnsyncedMillingSessions()).thenAnswer((_) async => [_millSession()]);
      when(() => client.post<void>(ApiConfig.millingSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('net'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markMillingSessionSynced(any()));
    });
  });

  // ── Classification sessions ───────────────────────────────────────────────

  group('classification sessions', () {
    setUp(() => _stubAllEmpty(ds));

    test('POST exitoso → markClassificationSessionSynced llamado', () async {
      final s = _classifSession();
      when(() => ds.getUnsyncedClassificationSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.classificationSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markClassificationSessionSynced(s.id)).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      verify(() => ds.markClassificationSessionSynced(s.id)).called(1);
    });

    test('payload incluye kg_entrada y kg_flotantes', () async {
      final s = _classifSession(id: 'cs-xyz');
      when(() => ds.getUnsyncedClassificationSessions()).thenAnswer((_) async => [s]);
      when(() => client.post<void>(ApiConfig.classificationSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenAnswer((_) async => _ok());
      when(() => ds.markClassificationSessionSynced(any())).thenAnswer((_) async {});

      await svc.syncPendingReadings();

      final captured = verify(() => client.post<void>(
        ApiConfig.classificationSessions,
        data: captureAny(named: 'data'),
        headers: any(named: 'headers'),
      )).captured;
      final p = captured.first as Map<String, dynamic>;
      expect(p['kg_entrada'],   200.0);
      expect(p['kg_flotantes'], 5.0);
    });

    test('POST falla → no lanza', () async {
      when(() => ds.getUnsyncedClassificationSessions())
          .thenAnswer((_) async => [_classifSession()]);
      when(() => client.post<void>(ApiConfig.classificationSessions,
            data: any(named: 'data'), headers: any(named: 'headers')))
          .thenThrow(Exception('net'));

      await expectLater(svc.syncPendingReadings(), completes);
      verifyNever(() => ds.markClassificationSessionSynced(any()));
    });
  });
}
