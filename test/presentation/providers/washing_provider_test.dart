import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/washing_session.dart';
import 'package:special_coffee/domain/repositories/washing_repository.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/providers/washing_provider.dart';

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

// ── In-memory WashingRepository ───────────────────────────────────────────────

class _FakeRepo implements WashingRepository {
  WashingSession? _stored;

  @override
  Future<WashingSession?> getByLotId(String lotId) async => _stored;

  @override
  Future<WashingSession> save(WashingSession session) async {
    final saved = WashingSession(
      id:               session.id.isEmpty ? 'fake-wash-id' : session.id,
      lotId:            session.lotId,
      ownerId:          session.ownerId,
      fermentationSessionId: session.fermentationSessionId,
      waterTempC:       session.waterTempC,
      waterChanges:     session.waterChanges,
      effluentPhFinal:  session.effluentPhFinal,
      durationH:        session.durationH,
      washedAt:         session.washedAt,
      aiAlertLevel:     session.aiAlertLevel,
      aiAlertMessage:   session.aiAlertMessage,
      notes:            session.notes,
      createdAt:        session.createdAt,
    );
    _stored = saved;
    return saved;
  }
}

// ── Container factory ─────────────────────────────────────────────────────────

ProviderContainer _container({
  List<Recommendation> Function(AIContext)? infer,
  WashingRepository? repo,
}) {
  final engine   = AIEngine.withAdapter(adapter: _FakeAdapter(infer));
  final fakeRepo = repo ?? _FakeRepo();
  return ProviderContainer(
    overrides: [
      aiEngineProvider.overrideWith((ref) async => engine),
      washingLocalRepoProvider.overrideWith((ref) => fakeRepo),
      lotByIdProvider('LOT-001').overrideWith((ref) async => null),
    ],
  );
}

Recommendation _rec(String action, {AlertLevel level = AlertLevel.warning}) =>
    Recommendation(
      ruleId:           'W1',
      action:           action,
      alertLevel:       level,
      confidence:       0.90,
      explanation:      'Test recommendation',
      suggestedActions: const [],
      parameters:       const {},
      generatedAt:      DateTime.now(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const lotId = 'LOT-001';

  // ── Initial state ─────────────────────────────────────────────────────────

  group('WashingNotifier — initial state', () {
    test('lotId is set, session is null, isComplete is false', () {
      final container = _container();
      addTearDown(container.dispose);

      final state = container.read(washingProvider(lotId));
      expect(state.lotId, lotId);
      expect(state.session, isNull);
      expect(state.isComplete, isFalse);
      expect(state.recommendations, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });

  // ── register — happy path ─────────────────────────────────────────────────

  group('WashingNotifier.register — happy path', () {
    test('session saved, isComplete becomes true', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(washingProvider(lotId).notifier).register(
            waterTempC:      22.0,
            waterChanges:    3,
            effluentPhFinal: 4.5,
            durationH:       18.0,
            washedAt:        DateTime.now(),
          );

      final state = container.read(washingProvider(lotId));
      expect(state.session, isNotNull);
      expect(state.isComplete, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('session persists expected field values', () async {
      final container = _container();
      addTearDown(container.dispose);

      final washedAt = DateTime(2026, 5, 26, 10, 0);
      await container.read(washingProvider(lotId).notifier).register(
            waterTempC:      24.5,
            waterChanges:    2,
            effluentPhFinal: 4.8,
            durationH:       20.0,
            washedAt:        washedAt,
            notes:           'Lote prueba',
          );

      final session = container.read(washingProvider(lotId)).session!;
      expect(session.waterTempC,      24.5);
      expect(session.waterChanges,    2);
      expect(session.effluentPhFinal, 4.8);
      expect(session.durationH,       20.0);
      expect(session.washedAt,        washedAt);
      expect(session.notes,           'Lote prueba');
      expect(session.lotId,           lotId);
    });

    test('recommendations populated from AI engine', () async {
      final container = _container(
        infer: (_) => [_rec('REDUCE_WASH_WATER_TEMP')],
      );
      addTearDown(container.dispose);

      await container.read(washingProvider(lotId).notifier).register(
            waterTempC:      22.0,
            waterChanges:    3,
            effluentPhFinal: 4.5,
            durationH:       18.0,
            washedAt:        DateTime.now(),
          );

      final state = container.read(washingProvider(lotId));
      expect(state.recommendations, hasLength(1));
      expect(state.recommendations.first.action, 'REDUCE_WASH_WATER_TEMP');
    });

    test('isLoading returns to false after register completes', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(washingProvider(lotId).notifier).register(
            waterTempC:      22.0,
            waterChanges:    3,
            effluentPhFinal: 4.5,
            durationH:       18.0,
            washedAt:        DateTime.now(),
          );

      expect(container.read(washingProvider(lotId)).isLoading, isFalse);
    });

    test('aiAlertLevel stored from first recommendation', () async {
      final container = _container(
        infer: (_) => [_rec('REDUCE_WASH_WATER_TEMP', level: AlertLevel.warning)],
      );
      addTearDown(container.dispose);

      await container.read(washingProvider(lotId).notifier).register(
            waterTempC:      22.0,
            waterChanges:    3,
            effluentPhFinal: 4.5,
            durationH:       18.0,
            washedAt:        DateTime.now(),
          );

      final session = container.read(washingProvider(lotId)).session!;
      expect(session.aiAlertLevel, 'warning');
    });

    test('aiAlertLevel = "none" when no recommendations', () async {
      final container = _container(infer: (_) => []);
      addTearDown(container.dispose);

      await container.read(washingProvider(lotId).notifier).register(
            waterTempC:      22.0,
            waterChanges:    3,
            effluentPhFinal: 4.5,
            durationH:       18.0,
            washedAt:        DateTime.now(),
          );

      final session = container.read(washingProvider(lotId)).session!;
      expect(session.aiAlertLevel, 'none');
      expect(session.aiAlertMessage, isNull);
    });
  });

  // ── register — error path ─────────────────────────────────────────────────

  group('WashingNotifier.register — error handling', () {
    test('error set and isLoading false when repo.save throws', () async {
      final throwingRepo = _ThrowingRepo();
      final container    = _container(repo: throwingRepo);
      addTearDown(container.dispose);

      await container.read(washingProvider(lotId).notifier).register(
            waterTempC:      22.0,
            waterChanges:    3,
            effluentPhFinal: 4.5,
            durationH:       18.0,
            washedAt:        DateTime.now(),
          );

      final state = container.read(washingProvider(lotId));
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.session, isNull);
    });
  });
}

// ── Helper repo that always throws ───────────────────────────────────────────

class _ThrowingRepo implements WashingRepository {
  @override Future<WashingSession?> getByLotId(String lotId) async => null;
  @override Future<WashingSession> save(WashingSession session) =>
      Future.error(Exception('disk full'));
}
