import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/cosecha_pase.dart';
import 'package:special_coffee/domain/repositories/cosecha_pase_repository.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/cosecha_pase_provider.dart';
import 'package:special_coffee/presentation/providers/settings_provider.dart';
import 'package:special_coffee/presentation/screens/pase/pase_create_screen.dart';
import 'package:special_coffee/presentation/screens/pase/pase_detail_screen.dart';

// ── Fake repo ─────────────────────────────────────────────────────────────────

final _t = DateTime(2026, 1, 10);

class _FakeRepo implements CosechaPaseRepository {
  final CosechaPase? fixed;
  _FakeRepo({this.fixed});

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
  }) async =>
      _pase();

  @override
  Future<List<CosechaPase>> getPasesByLot(String lotId) async =>
      fixed != null ? [fixed!] : [];

  @override
  Future<CosechaPase?> getById(String id) async => fixed;

  @override
  Future<List<CosechaPase>> getActivePases(String userId) async =>
      fixed != null ? [fixed!] : [];

  @override
  Future<void> updateClasificacion(String paseId,
      {required double pesoFlotacionKg, double? pctFlotacion}) async {}

  @override
  Future<void> updateDespulpado(String paseId,
      {required double pesoPergaminoHumedoKg,
      double? horasHastaDespulpe}) async {}

  @override
  Future<void> advanceEtapa(String paseId, String nuevaEtapa) async {}

  @override
  Future<void> completar(String paseId) async {}

  @override
  Future<List<CosechaPase>> getCompletedPases(String userId) async => [];

  @override
  Future<void> abandonar(String paseId) async {}

  CosechaPase _pase() => CosechaPase(
        id:               'p1',
        lotId:            'lot-1',
        createdBy:        'u1',
        fechaRecoleccion: _t,
        pesoCerezaKg:     200,
        tipoProceso:      'lavado',
        etapaActual:      'clasificacion',
        status:           'activo',
        createdAt:        _t,
        updatedAt:        _t,
      );
}

// ── Builders ──────────────────────────────────────────────────────────────────

Widget _buildCreate(String lotId, {_FakeRepo? repo}) => ProviderScope(
      overrides: [
        cosechaPaseLocalRepoProvider.overrideWithValue(repo ?? _FakeRepo()),
        currentUserIdProvider.overrideWithValue('u1'),
        learningModeProvider.overrideWithValue(false),
      ],
      child: MaterialApp(home: PaseCreateScreen(lotId: lotId)),
    );

Widget _buildDetail(String paseId, {_FakeRepo? repo}) => ProviderScope(
      overrides: [
        cosechaPaseLocalRepoProvider.overrideWithValue(repo ?? _FakeRepo()),
        currentUserIdProvider.overrideWithValue('u1'),
        paseByIdProvider(paseId).overrideWith(
          (_) async => repo?.fixed ?? _FakeRepo(fixed: null).fixed,
        ),
      ],
      child: MaterialApp(home: PaseDetailScreen(paseId: paseId)),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaseCreateScreen', () {
    testWidgets('muestra título "Nuevo pase de cosecha"', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildCreate('lot-1'));
        await tester.pumpAndSettle();
      });
      expect(find.text('Nuevo pase de cosecha'), findsOneWidget);
    });

    testWidgets('muestra campo peso cereza', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildCreate('lot-1'));
        await tester.pumpAndSettle();
      });
      expect(find.text('Peso cereza (kg)'), findsOneWidget);
    });

    testWidgets('muestra selector de tipo de proceso con opción Lavado',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildCreate('lot-1'));
        await tester.pumpAndSettle();
      });
      expect(find.text('Lavado'), findsOneWidget);
    });
  });

  group('PaseDetailScreen', () {
    final pase = CosechaPase(
      id:               'p1',
      lotId:            'lot-1',
      createdBy:        'u1',
      fechaRecoleccion: _t,
      pesoCerezaKg:     200,
      tipoProceso:      'lavado',
      etapaActual:      'clasificacion',
      status:           'activo',
      createdAt:        _t,
      updatedAt:        _t,
    );

    testWidgets('muestra título "Pase de cosecha"', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          _buildDetail('p1', repo: _FakeRepo(fixed: pase)),
        );
        await tester.pumpAndSettle();
      });
      expect(find.text('Pase de cosecha'), findsOneWidget);
    });

    testWidgets('muestra tipo de proceso del pase', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          _buildDetail('p1', repo: _FakeRepo(fixed: pase)),
        );
        await tester.pumpAndSettle();
      });
      expect(find.text('Lavado'), findsWidgets);
    });

    testWidgets('muestra "Pase no encontrado" cuando pase es null',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cosechaPaseLocalRepoProvider
                  .overrideWithValue(_FakeRepo()),
              currentUserIdProvider.overrideWithValue('u1'),
              paseByIdProvider('missing').overrideWith((_) async => null),
            ],
            child: const MaterialApp(
                home: PaseDetailScreen(paseId: 'missing')),
          ),
        );
        await tester.pumpAndSettle();
      });
      expect(find.text('Pase no encontrado'), findsOneWidget);
    });
  });
}
