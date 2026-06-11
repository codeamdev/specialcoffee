// Integration test — requires local backend (docker compose up -d + migración 004).
// Ejecutar: flutter test test/integration/sync_e2e_test.dart
// Los tests se saltan automáticamente si el backend no está disponible.
// No ejecutar en CI sin backend local ni contra producción.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/data/sync/sync_data_source.dart';
import 'package:special_coffee/data/sync/sync_service.dart';

class _MockDs extends Mock implements SyncDataSource {}

// ── URLs locales (siempre apunta al backend local, sin depender de DEV_MODE) ──

const _base      = 'http://127.0.0.1';
const _loginUrl  = '$_base/auth/login';
const _apiBase   = '$_base/api';

const _urlLots            = '$_apiBase/lots';
const _urlCosechaPases    = '$_apiBase/cosecha_pases';
const _urlFermSessions    = '$_apiBase/fermentation_sessions';
const _urlFermReadings    = '$_apiBase/fermentation_readings';
const _urlDrySessions     = '$_apiBase/drying_sessions';
const _urlDryReadings     = '$_apiBase/drying_readings';
const _urlWashSessions    = '$_apiBase/washing_sessions';
const _urlMillSessions    = '$_apiBase/milling_sessions';
const _urlClassifSessions = '$_apiBase/classification_sessions';

// ── IDs de test únicos por ejecución ─────────────────────────────────────────

final _ts       = DateTime.now().millisecondsSinceEpoch;
final _lotId    = 'e2e-$_ts-lot';
final _paseId   = 'e2e-$_ts-pase';
final _fsId     = 'e2e-$_ts-fs';
final _frId     = 'e2e-$_ts-fr';
final _dsId     = 'e2e-$_ts-ds';
final _drId     = 'e2e-$_ts-dr';
final _wsId     = 'e2e-$_ts-ws';
final _msId     = 'e2e-$_ts-ms';
final _csId     = 'e2e-$_ts-cs';
const _ownerId  = 'c996134d-ce77-4e76-8e31-ce413a114d02';

// ── Estado global del test ────────────────────────────────────────────────────

bool _backendUp = false;
late ApiClient _client;

// ── Helpers ───────────────────────────────────────────────────────────────────

_MockDs _emptyDs() {
  final ds = _MockDs();
  when(() => ds.getUnsyncedLots()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedCosechaPases()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedFermentationSessions()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedFermentationReadings()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedDryingSessions()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedDryingReadings()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedWashingSessions()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedMillingSessions()).thenAnswer((_) async => []);
  when(() => ds.getUnsyncedClassificationSessions()).thenAnswer((_) async => []);
  return ds;
}

Future<bool> _existsInPg(String url, String id) async {
  try {
    final r = await _client.get<dynamic>(url, params: {'id': 'eq.$id'});
    final body = r.data as List?;
    return body != null && body.isNotEmpty;
  } catch (_) {
    return false;
  }
}

Future<void> _deleteFromPg(String url, String id) async {
  try {
    await _client.delete<void>(url, params: {'id': 'eq.$id'});
  } catch (_) {}
}

SyncService _svc(_MockDs ds) => SyncService(ds, _client);

// ── Fixtures ──────────────────────────────────────────────────────────────────

DbLocalLot _lot() => DbLocalLot(
  id: _lotId, userId: _ownerId, varietyId: 'var-castillo',
  varietyName: 'Castillo', altitudeMasl: 1700, region: 'Nariño',
  processType: '', latitude: null, longitude: null, farmAreaHa: null,
  blendVarietyIds: null, plantAgeYears: null, plantType: null,
  createdAt: DateTime(2026, 6, 10), notes: null, deletedAt: null,
  syncedAt: null,
);

DbCosechaPase _pase() => DbCosechaPase(
  id: _paseId, lotId: _lotId, createdBy: _ownerId,
  fechaRecoleccion: DateTime(2026, 6, 10),
  horaInicio: null, horaFin: null,
  pesoCerezaKg: 150.0, numOperarios: 3, brixPromedio: 22.5,
  pctMadurezVisual: 90.0, tipoProceso: 'lavado',
  pesoFlotacionKg: null, pctFlotacion: null,
  pesoPergaminoHumedoKg: null, horasHastaDespulpe: null,
  etapaActual: 'clasificacion', status: 'activo', notas: null,
  createdAt: DateTime(2026, 6, 10), updatedAt: DateTime(2026, 6, 10),
  deletedAt: null, syncedAt: null,
);

DbFermentationSession _fermSession() => DbFermentationSession(
  id: _fsId, lotId: _lotId, ownerId: _ownerId, processType: 'lavado',
  startedAt: DateTime(2026, 6, 10, 8), endedAt: null,
  actualDurationH: null, endReason: null, phInitial: 5.8, phFinal: null,
  createdAt: DateTime(2026, 6, 10), updatedAt: DateTime(2026, 6, 10),
  syncedAt: null, deletedAt: null,
);

DbFermentationReading _fermReading() => DbFermentationReading(
  id: _frId, sessionId: _fsId, lotId: _lotId, ownerId: _ownerId,
  readingNumber: 1, hoursElapsed: 8.0, phValue: 4.5, mucilagoTempC: 22.0,
  ambientTempC: null, mucilageState: 'liquid', aiAlertLevel: 'none',
  aiAlertRuleId: null, aiProjectedEndH: null,
  recordedAt: DateTime(2026, 6, 10, 16),
  updatedAt: DateTime(2026, 6, 10, 16), syncedAt: null,
);

DbDryingSession _drySession() => DbDryingSession(
  id: _dsId, lotId: _lotId, ownerId: _ownerId, dryingMethod: 'solar',
  startedAt: DateTime(2026, 6, 11), endedAt: null,
  targetMoisturePct: 11.0, finalMoisturePct: null,
  createdAt: DateTime(2026, 6, 11), updatedAt: DateTime(2026, 6, 11),
  syncedAt: null, deletedAt: null,
);

DbDryingReading _dryReading() => DbDryingReading(
  id: _drId, sessionId: _dsId, lotId: _lotId, ownerId: _ownerId,
  moisturePct: 35.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
  uvIndex: 4.0, aiRecommendation: null,
  recordedAt: DateTime(2026, 6, 11, 10),
  updatedAt: DateTime(2026, 6, 11, 10), syncedAt: null,
);

DbWashingSession _washSession() => DbWashingSession(
  id: _wsId, lotId: _lotId, ownerId: _ownerId,
  fermentationSessionId: _fsId,
  waterTempC: 18.0, waterChanges: 3, effluentPhFinal: 5.2, durationH: 2.0,
  washedAt: DateTime(2026, 6, 11, 14),
  aiAlertLevel: 'none', aiAlertMessage: null, notes: null,
  createdAt: DateTime(2026, 6, 11), updatedAt: DateTime(2026, 6, 11),
  syncedAt: null,
);

DbMillingSession _millSession() => DbMillingSession(
  id: _msId, lotId: _lotId, ownerId: _ownerId,
  inputKgParchment: 100.0, outputKgGreen: 80.0, yieldPct: 80.0,
  aiAlertLevel: 'none', aiAlertMessage: null, notes: null,
  createdAt: DateTime(2026, 6, 12), updatedAt: DateTime(2026, 6, 12),
  syncedAt: null,
);

DbClassificationSession _classifSession() => DbClassificationSession(
  id: _csId, lotId: _lotId, ownerId: _ownerId, harvestSessionId: null,
  kgEntrada: 200.0, brixCereza: null, kgFlotantes: 5.0, kgDescarteManual: 2.0,
  aiAlertLevel: 'none', aiAlertMessage: null, notes: null,
  classifiedAt: DateTime(2026, 6, 10, 9),
  createdAt: DateTime(2026, 6, 10), updatedAt: DateTime(2026, 6, 10),
  syncedAt: null,
);

// ── Main ──────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    try {
      final res = await Dio().post<dynamic>(
        _loginUrl,
        data: {'email': 'e2etest@specialcoffee.com', 'password': 'Test1234!'},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final token = res.data['access_token'] as String;
      _client = ApiClient.withToken(token);
      _backendUp = true;
    } catch (_) {
      _backendUp = false;
    }
  });

  tearDownAll(() async {
    if (!_backendUp) return;
    // FK-safe reverse order
    for (final entry in [
      (_urlFermReadings,    _frId),
      (_urlDryReadings,     _drId),
      (_urlWashSessions,    _wsId),
      (_urlFermSessions,    _fsId),
      (_urlDrySessions,     _dsId),
      (_urlMillSessions,    _msId),
      (_urlClassifSessions, _csId),
      (_urlCosechaPases,    _paseId),
      (_urlLots,            _lotId),
    ]) {
      await _deleteFromPg(entry.$1, entry.$2);
    }
  });

  // ── E1: Lotes ──────────────────────────────────────────────────────────────

  test('E1 — lot syncs to PostgreSQL (wave 1)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedLots()).thenAnswer((_) async => [_lot()]);
    when(() => ds.markLotSynced(_lotId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markLotSynced(_lotId)).called(1);
    expect(await _existsInPg(_urlLots, _lotId), isTrue,
        reason: 'Lote debe aparecer en lots de PostgreSQL');
  });

  // ── E2: Cosecha pases ──────────────────────────────────────────────────────

  test('E2 — cosecha pase syncs (FK → lots)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedCosechaPases()).thenAnswer((_) async => [_pase()]);
    when(() => ds.markCosechaPaseSynced(_paseId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markCosechaPaseSynced(_paseId)).called(1);
    expect(await _existsInPg(_urlCosechaPases, _paseId), isTrue);
  });

  // ── E3: Fermentation session + reading ────────────────────────────────────

  test('E3a — fermentation session syncs (FK → lots)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedFermentationSessions())
        .thenAnswer((_) async => [_fermSession()]);
    when(() => ds.markFermentationSessionSynced(_fsId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markFermentationSessionSynced(_fsId)).called(1);
    expect(await _existsInPg(_urlFermSessions, _fsId), isTrue);
  });

  test('E3b — fermentation reading syncs (FK → session + lots)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedFermentationReadings())
        .thenAnswer((_) async => [_fermReading()]);
    when(() => ds.markFermentationSynced(_frId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markFermentationSynced(_frId)).called(1);
    expect(await _existsInPg(_urlFermReadings, _frId), isTrue);
  });

  // ── E4: Drying session + reading ──────────────────────────────────────────

  test('E4a — drying session syncs (FK → lots)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedDryingSessions())
        .thenAnswer((_) async => [_drySession()]);
    when(() => ds.markDryingSessionSynced(_dsId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markDryingSessionSynced(_dsId)).called(1);
    expect(await _existsInPg(_urlDrySessions, _dsId), isTrue);
  });

  test('E4b — drying reading syncs (FK → session + lots)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedDryingReadings())
        .thenAnswer((_) async => [_dryReading()]);
    when(() => ds.markDryingSynced(_drId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markDryingSynced(_drId)).called(1);
    expect(await _existsInPg(_urlDryReadings, _drId), isTrue);
  });

  // ── E5: Washing session ───────────────────────────────────────────────────

  test('E5 — washing session syncs (FK nullable → fermentation_sessions)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedWashingSessions())
        .thenAnswer((_) async => [_washSession()]);
    when(() => ds.markWashingSessionSynced(_wsId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markWashingSessionSynced(_wsId)).called(1);
    expect(await _existsInPg(_urlWashSessions, _wsId), isTrue);
  });

  // ── E6: Milling session ────────────────────────────────────────────────────

  test('E6 — milling session syncs (FK → lots)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedMillingSessions())
        .thenAnswer((_) async => [_millSession()]);
    when(() => ds.markMillingSessionSynced(_msId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markMillingSessionSynced(_msId)).called(1);
    expect(await _existsInPg(_urlMillSessions, _msId), isTrue);
  });

  // ── E7: Classification session ─────────────────────────────────────────────

  test('E7 — classification session syncs (FK → lots)', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedClassificationSessions())
        .thenAnswer((_) async => [_classifSession()]);
    when(() => ds.markClassificationSessionSynced(_csId)).thenAnswer((_) async {});

    await _svc(ds).syncPendingReadings();

    verify(() => ds.markClassificationSessionSynced(_csId)).called(1);
    expect(await _existsInPg(_urlClassifSessions, _csId), isTrue);
  });

  // ── Error cases ────────────────────────────────────────────────────────────

  test('E-idempotency — segundo POST del mismo lot no crea duplicados', () async {
    if (!_backendUp) return;

    final ds = _emptyDs();
    when(() => ds.getUnsyncedLots()).thenAnswer((_) async => [_lot()]);
    when(() => ds.markLotSynced(_lotId)).thenAnswer((_) async {});

    // Sync dos veces — Prefer: resolution=ignore-duplicates debe evitar duplicado
    await _svc(ds).syncPendingReadings();
    await _svc(ds).syncPendingReadings();

    final res = await _client.get<dynamic>(
      _urlLots,
      params: {'id': 'eq.$_lotId', 'select': 'id'},
    );
    expect((res.data as List).length, 1,
        reason: 'Prefer: resolution=ignore-duplicates — no duplicados en PostgreSQL');
  });

  test('E-partial — pase con lot_id inexistente falla; pase válido sí sincroniza', () async {
    if (!_backendUp) return;

    final badPaseId   = 'e2e-$_ts-bad-pase';
    final goodPaseId  = 'e2e-$_ts-good-pase';

    final bad = DbCosechaPase(
      id: badPaseId, lotId: 'nonexistent-lot-xyz', createdBy: _ownerId,
      fechaRecoleccion: DateTime(2026, 6, 10),
      horaInicio: null, horaFin: null,
      pesoCerezaKg: 50.0, numOperarios: null, brixPromedio: null,
      pctMadurezVisual: null, tipoProceso: 'lavado',
      pesoFlotacionKg: null, pctFlotacion: null,
      pesoPergaminoHumedoKg: null, horasHastaDespulpe: null,
      etapaActual: 'clasificacion', status: 'activo', notas: null,
      createdAt: DateTime(2026, 6, 10), updatedAt: DateTime(2026, 6, 10),
      deletedAt: null, syncedAt: null,
    );
    final good = DbCosechaPase(
      id: goodPaseId, lotId: _lotId, createdBy: _ownerId,
      fechaRecoleccion: DateTime(2026, 6, 10),
      horaInicio: null, horaFin: null,
      pesoCerezaKg: 120.0, numOperarios: 2, brixPromedio: 21.0,
      pctMadurezVisual: null, tipoProceso: 'lavado',
      pesoFlotacionKg: null, pctFlotacion: null,
      pesoPergaminoHumedoKg: null, horasHastaDespulpe: null,
      etapaActual: 'clasificacion', status: 'activo', notas: null,
      createdAt: DateTime(2026, 6, 10), updatedAt: DateTime(2026, 6, 10),
      deletedAt: null, syncedAt: null,
    );
    final ds = _emptyDs();
    when(() => ds.getUnsyncedCosechaPases())
        .thenAnswer((_) async => [bad, good]);
    when(() => ds.markCosechaPaseSynced(goodPaseId)).thenAnswer((_) async {});

    await expectLater(_svc(ds).syncPendingReadings(), completes);

    verify(() => ds.markCosechaPaseSynced(goodPaseId)).called(1);
    verifyNever(() => ds.markCosechaPaseSynced(badPaseId));

    expect(await _existsInPg(_urlCosechaPases, goodPaseId), isTrue,
        reason: 'Pase válido debe existir en PostgreSQL');
    expect(await _existsInPg(_urlCosechaPases, badPaseId), isFalse,
        reason: 'Pase con FK inválida no debe existir en PostgreSQL');

    await _deleteFromPg(_urlCosechaPases, goodPaseId);
  });
}
