import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/drying_session.dart';
import 'package:special_coffee/domain/repositories/drying_repository.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/drying_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:drift/native.dart';
import 'package:special_coffee/core/database/app_database.dart';

// ── Fake adapter ──────────────────────────────────────────────────────────────

class _FakeAdapter extends InferenceAdapter {
  final List<Recommendation> Function(AIContext) _infer;

  _FakeAdapter([List<Recommendation> Function(AIContext)? infer])
      : _infer = infer ?? ((_) => []);

  @override Future<void> initialize() async {}
  @override bool get isReady => true;
  @override String get version => 'fake-1.0';
  @override Future<List<Recommendation>> infer(AIContext context) async =>
      _infer(context);
}

// ── In-memory DryingRepository ────────────────────────────────────────────────

class _FakeDryingRepo implements DryingRepository {
  DryingSession? _session;
  final List<DryingReadingRecord> _readings = [];

  @override
  Future<DryingSession> createSession({
    required String lotId,
    required String dryingMethod,
  }) async {
    _session = DryingSession(
      id: 'fake-session-$lotId',
      lotId: lotId,
      ownerId: 'test-user',
      dryingMethod: dryingMethod,
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    return _session!;
  }

  @override
  Future<DryingSession?> getActiveSession(String lotId) async => _session;

  @override
  Future<DryingReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int dayNumber,
    required double moisturePct,
    required double ambientTempC,
    required double ambientHumidityPct,
    double uvIndex = 0.0,
    String? aiRecommendation,
  }) async {
    final record = DryingReadingRecord(
      id: '$sessionId-d$dayNumber',
      sessionId: sessionId,
      lotId: lotId,
      ownerId: 'test-user',
      dayNumber: dayNumber,
      moisturePct: moisturePct,
      ambientTempC: ambientTempC,
      ambientHumidityPct: ambientHumidityPct,
      uvIndex: uvIndex,
      aiRecommendation: aiRecommendation,
      recordedAt: DateTime.now(),
    );
    _readings.add(record);
    return record;
  }

  @override
  Future<List<DryingReadingRecord>> getReadings(String sessionId) async =>
      _readings.where((r) => r.sessionId == sessionId).toList();

  @override
  Future<void> closeSession({
    required String sessionId,
    required double finalMoisturePct,
  }) async {
    _session = null;
  }
}

// ── Repo que falla en createSession ──────────────────────────────────────────

class _FailingSessionRepo extends _FakeDryingRepo {
  @override
  Future<DryingSession> createSession({
    required String lotId,
    required String dryingMethod,
  }) async =>
      throw Exception('disco lleno');
}

// ── Repo que falla en addReading ─────────────────────────────────────────────

class _FailingReadingRepo extends _FakeDryingRepo {
  @override
  Future<DryingReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int dayNumber,
    required double moisturePct,
    required double ambientTempC,
    required double ambientHumidityPct,
    double uvIndex = 0.0,
    String? aiRecommendation,
  }) async =>
      throw Exception('escritura fallida');
}

// ── Container factory ─────────────────────────────────────────────────────────

ProviderContainer _container({
  List<Recommendation> Function(AIContext)? infer,
  DryingRepository? repo,
}) {
  final engine   = AIEngine.withAdapter(adapter: _FakeAdapter(infer));
  final fakeRepo = repo ?? _FakeDryingRepo();
  return ProviderContainer(
    overrides: [
      aiEngineProvider.overrideWith((ref) async => engine),
      dryingLocalRepoProvider.overrideWith((ref) => fakeRepo),
      lotByIdProvider('LOT-001').overrideWith((ref) async => null),
      appDatabaseProvider.overrideWith((ref) => AppDatabase.forTesting(NativeDatabase.memory())),
    ],
  );
}

Recommendation _rec(String action) => Recommendation(
  ruleId: 'D1',
  action: action,
  alertLevel: AlertLevel.warning,
  confidence: 0.85,
  explanation: 'Test',
  suggestedActions: const [],
  parameters: const {},
  generatedAt: DateTime.now(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const lotId = 'LOT-001';

  // ── Estado inicial ────────────────────────────────────────────────────────

  group('DryingNotifier — estado inicial', () {
    test('lotId correcto, sin lecturas, sin error', () {
      final container = _container();
      addTearDown(container.dispose);

      final state = container.read(dryingProvider(lotId));
      expect(state.lotId, lotId);
      expect(state.hasReadings, isFalse);
      expect(state.recommendations, isEmpty);
      expect(state.isAnalyzing, isFalse);
      expect(state.error, isNull);
    });
  });

  // ── addReading — happy path ───────────────────────────────────────────────

  group('DryingNotifier.addReading — happy path', () {
    test('la lectura se añade al estado', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct:      35.0,
            ambientTempC:     28.0,
            ambientHumidityPct: 65.0,
          );

      expect(container.read(dryingProvider(lotId)).readings.length, 1);
    });

    test('múltiples lecturas se acumulan', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = container.read(dryingProvider(lotId).notifier);
      await notifier.addReading(moisturePct: 42.0, ambientTempC: 28.0, ambientHumidityPct: 65.0);
      await notifier.addReading(moisturePct: 35.0, ambientTempC: 29.0, ambientHumidityPct: 60.0);
      await notifier.addReading(moisturePct: 25.0, ambientTempC: 30.0, ambientHumidityPct: 55.0);

      expect(container.read(dryingProvider(lotId)).readings.length, 3);
    });

    test('isAnalyzing vuelve a false tras completar', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 30.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
          );

      expect(container.read(dryingProvider(lotId)).isAnalyzing, isFalse);
    });

    test('recomendaciones se populan desde el motor de IA', () async {
      final container = _container(
        infer: (_) => [_rec('REDUCE_SUN_EXPOSURE')],
      );
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 30.0, ambientTempC: 36.0, ambientHumidityPct: 65.0,
          );

      final state = container.read(dryingProvider(lotId));
      expect(state.recommendations, hasLength(1));
      expect(state.recommendations.first.action, 'REDUCE_SUN_EXPOSURE');
    });

    test('sesión se crea al registrar la primera lectura', () async {
      final container = _container();
      addTearDown(container.dispose);

      expect(container.read(dryingProvider(lotId)).sessionId, isNull);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 30.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
          );

      expect(container.read(dryingProvider(lotId)).sessionId, isNotNull);
    });

    test('isAtTarget true cuando humedad está entre 10.5 y 12.0', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 11.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
          );

      expect(container.read(dryingProvider(lotId)).isAtTarget, isTrue);
    });

    test('isOverDried true cuando humedad cae bajo 10.0', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 9.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
          );

      expect(container.read(dryingProvider(lotId)).isOverDried, isTrue);
    });
  });

  // ── Error de persistencia ─────────────────────────────────────────────────

  group('DryingNotifier — error de persistencia', () {
    test('createSession falla → state.error no es null, lectura en memoria', () async {
      final container = _container(repo: _FailingSessionRepo());
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 30.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
          );

      final state = container.read(dryingProvider(lotId));
      expect(state.error, isNotNull);
      // La lectura sigue existiendo en memoria
      expect(state.readings.length, 1);
    });

    test('addReading persist falla → state.error no es null', () async {
      final container = _container(repo: _FailingReadingRepo());
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 30.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
          );

      final state = container.read(dryingProvider(lotId));
      expect(state.error, isNotNull);
    });
  });

  // ── Error de IA ───────────────────────────────────────────────────────────

  group('DryingNotifier — error de IA', () {
    test('AI falla → state.error no es null, isAnalyzing false', () async {
      final container = _container(
        infer: (_) => throw Exception('Gemini timeout'),
      );
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 30.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
          );

      final state = container.read(dryingProvider(lotId));
      expect(state.error, isNotNull);
      expect(state.isAnalyzing, isFalse);
    });
  });

  // ── changeDryingMethod ────────────────────────────────────────────────────

  group('DryingNotifier.changeDryingMethod', () {
    test('cambia el método antes de la primera lectura', () {
      final container = _container();
      addTearDown(container.dispose);

      container.read(dryingProvider(lotId).notifier).changeDryingMethod('patio');

      expect(container.read(dryingProvider(lotId)).dryingMethod, 'patio');
    });

    test('bloqueado tras primera lectura — no-op', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(dryingProvider(lotId).notifier).addReading(
            moisturePct: 30.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
          );
      container.read(dryingProvider(lotId).notifier).changeDryingMethod('patio');

      expect(
        container.read(dryingProvider(lotId)).dryingMethod,
        'camas_africanas',
      );
    });
  });

  // ── reset ─────────────────────────────────────────────────────────────────

  group('DryingNotifier.reset', () {
    test('limpia lecturas y recomendaciones, conserva lotId y método', () async {
      final container = _container(
        infer: (_) => [_rec('REDUCE_SUN_EXPOSURE')],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dryingProvider(lotId).notifier);
      await notifier.addReading(
        moisturePct: 30.0, ambientTempC: 28.0, ambientHumidityPct: 65.0,
      );
      notifier.reset();

      final state = container.read(dryingProvider(lotId));
      expect(state.readings, isEmpty);
      expect(state.recommendations, isEmpty);
      expect(state.lotId, lotId);
    });
  });
}
