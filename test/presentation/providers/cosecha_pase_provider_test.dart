import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/cosecha_pase.dart';
import 'package:special_coffee/domain/repositories/cosecha_pase_repository.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/cosecha_pase_provider.dart';
import 'package:drift/native.dart';
import 'package:special_coffee/core/database/app_database.dart';

// ── Fake repo ─────────────────────────────────────────────────────────────────

class _FakeRepo implements CosechaPaseRepository {
  final _store = <String, CosechaPase>{};

  CosechaPase _make({
    String id = 'p1',
    String lotId = 'lot-1',
    String tipoProceso = 'lavado',
    String etapaActual = 'clasificacion',
  }) =>
      CosechaPase(
        id:               id,
        lotId:            lotId,
        createdBy:        'u1',
        fechaRecoleccion: DateTime(2026, 1, 10),
        pesoCerezaKg:     200,
        tipoProceso:      tipoProceso,
        etapaActual:      etapaActual,
        status:           'activo',
        createdAt:        DateTime(2026, 1, 10),
        updatedAt:        DateTime(2026, 1, 10),
      );

  @override
  Future<CosechaPase> create({
    required String lotId,
    required String createdBy,
    required DateTime fechaRecoleccion,
    required double pesoCerezaKg,
    required String tipoProceso,
    DateTime? horaInicio,
    DateTime? horaFin,
    int? numOperarios,
    double? brixPromedio,
    double? pctMadurezVisual,
    String? notas,
  }) async {
    final p = _make(lotId: lotId, tipoProceso: tipoProceso);
    _store[p.id] = p;
    return p;
  }

  @override
  Future<List<CosechaPase>> getPasesByLot(String lotId) async =>
      _store.values.where((p) => p.lotId == lotId).toList();

  @override
  Future<CosechaPase?> getById(String id) async => _store[id];

  @override
  Future<List<CosechaPase>> getActivePases(String userId) async =>
      _store.values.where((p) => p.status == 'activo').toList();

  @override
  Future<void> updateClasificacion(String paseId,
      {required double pesoFlotacionKg, double? pctFlotacion}) async {}

  @override
  Future<void> updateDespulpado(String paseId,
      {required double pesoPergaminoHumedoKg,
      double? horasHastaDespulpe}) async {}

  @override
  Future<void> advanceEtapa(String paseId, String nuevaEtapa) async {
    if (_store.containsKey(paseId)) {
      final p = _store[paseId]!;
      _store[paseId] = CosechaPase(
        id:               p.id,
        lotId:            p.lotId,
        createdBy:        p.createdBy,
        fechaRecoleccion: p.fechaRecoleccion,
        pesoCerezaKg:     p.pesoCerezaKg,
        tipoProceso:      p.tipoProceso,
        etapaActual:      nuevaEtapa,
        status:           p.status,
        createdAt:        p.createdAt,
        updatedAt:        DateTime.now(),
      );
    }
  }

  @override
  Future<void> completar(String paseId) async {
    if (_store.containsKey(paseId)) {
      final p = _store[paseId]!;
      _store[paseId] = CosechaPase(
        id:               p.id,
        lotId:            p.lotId,
        createdBy:        p.createdBy,
        fechaRecoleccion: p.fechaRecoleccion,
        pesoCerezaKg:     p.pesoCerezaKg,
        tipoProceso:      p.tipoProceso,
        etapaActual:      p.etapaActual,
        status:           'completado',
        createdAt:        p.createdAt,
        updatedAt:        DateTime.now(),
      );
    }
  }

  @override
  Future<List<CosechaPase>> getCompletedPases(String userId) async =>
      _store.values.where((p) => p.status == 'completado').toList();

  @override
  Future<void> abandonar(String paseId) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _container(_FakeRepo repo) => ProviderContainer(
      overrides: [
        cosechaPaseLocalRepoProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue('u1'),
        appDatabaseProvider.overrideWith((ref) => AppDatabase.forTesting(NativeDatabase.memory())),
      ],
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CosechaPaseNotifier', () {
    test('crear() devuelve un pase y lo añade al store', () async {
      final repo      = _FakeRepo();
      final container = _container(repo);
      addTearDown(container.dispose);

      final pase = await container
          .read(cosechaPaseProvider.notifier)
          .crear(
            lotId:            'lot-1',
            fechaRecoleccion: DateTime(2026, 1, 10),
            pesoCerezaKg:     200,
            tipoProceso:      'lavado',
          );

      expect(pase.lotId,      'lot-1');
      expect(pase.tipoProceso, 'lavado');
      expect(pase.etapaActual, 'clasificacion');
    });

    test('avanzarEtapa() actualiza la etapa del pase', () async {
      final repo      = _FakeRepo();
      final container = _container(repo);
      addTearDown(container.dispose);

      final pase = await container
          .read(cosechaPaseProvider.notifier)
          .crear(
            lotId:            'lot-2',
            fechaRecoleccion: DateTime(2026, 1, 11),
            pesoCerezaKg:     150,
            tipoProceso:      'lavado',
          );

      await container
          .read(cosechaPaseProvider.notifier)
          .avanzarEtapa(pase, 'fermentacion');

      final updated = await repo.getById(pase.id);
      expect(updated?.etapaActual, 'fermentacion');
    });

    test('completar() marca el pase como completado', () async {
      final repo      = _FakeRepo();
      final container = _container(repo);
      addTearDown(container.dispose);

      final pase = await container
          .read(cosechaPaseProvider.notifier)
          .crear(
            lotId:            'lot-3',
            fechaRecoleccion: DateTime(2026, 1, 12),
            pesoCerezaKg:     300,
            tipoProceso:      'natural',
          );

      await container
          .read(cosechaPaseProvider.notifier)
          .completar(pase);

      final updated = await repo.getById(pase.id);
      expect(updated?.status, 'completado');
    });
  });

  group('CosechaPase entity helpers', () {
    final _t = DateTime(2026, 1, 10);

    test('stages lavado tiene fermentacion y lavado', () {
      final pase = CosechaPase(
        id:               'p1',
        lotId:            'l1',
        createdBy:        'u1',
        fechaRecoleccion: _t,
        pesoCerezaKg:     100,
        tipoProceso:      'lavado',
        etapaActual:      'clasificacion',
        status:           'activo',
        createdAt:        _t,
        updatedAt:        _t,
      );
      expect(pase.stages, contains('fermentacion'));
      expect(pase.stages, contains('lavado'));
    });

    test('stages natural NO tiene fermentacion ni lavado', () {
      final pase = CosechaPase(
        id:               'p2',
        lotId:            'l1',
        createdBy:        'u1',
        fechaRecoleccion: _t,
        pesoCerezaKg:     100,
        tipoProceso:      'natural',
        etapaActual:      'clasificacion',
        status:           'activo',
        createdAt:        _t,
        updatedAt:        _t,
      );
      expect(pase.stages, isNot(contains('fermentacion')));
      expect(pase.stages, isNot(contains('lavado')));
    });

    test('fermentacionIntervalH correcto por tipo', () {
      double interval(String tipo) => CosechaPase(
            id:               'x',
            lotId:            'l',
            createdBy:        'u',
            fechaRecoleccion: _t,
            pesoCerezaKg:     1,
            tipoProceso:      tipo,
            etapaActual:      'fermentacion',
            status:           'activo',
            createdAt:        _t,
            updatedAt:        _t,
          ).fermentacionIntervalH;

      expect(interval('lavado'),             4.0);
      expect(interval('natural'),           24.0);
      expect(interval('honey_yellow'),      12.0);
      expect(interval('anaerobic_lactic'),   4.0);
    });
  });
}
