import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/milling_session.dart';
import 'package:special_coffee/domain/repositories/milling_repository.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/providers/milling_provider.dart';
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

// ── In-memory MillingRepository ───────────────────────────────────────────────

class _FakeRepo implements MillingRepository {
  MillingSession? _stored;

  @override
  Future<MillingSession?> getByLotId(String lotId) async => _stored;

  @override
  Future<MillingSession> save(MillingSession session) async {
    final saved = MillingSession(
      id:               session.id.isEmpty ? 'fake-mill-id' : session.id,
      lotId:            session.lotId,
      ownerId:          session.ownerId,
      inputKgParchment: session.inputKgParchment,
      outputKgGreen:    session.outputKgGreen,
      yieldPct:         session.yieldPct,
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
  MillingRepository? repo,
}) {
  final engine   = AIEngine.withAdapter(adapter: _FakeAdapter(infer));
  final fakeRepo = repo ?? _FakeRepo();
  return ProviderContainer(
    overrides: [
      aiEngineProvider.overrideWith((ref) async => engine),
      millingLocalRepoProvider.overrideWith((ref) => fakeRepo),
      lotByIdProvider('LOT-001').overrideWith((ref) async => null),
      appDatabaseProvider.overrideWith((ref) => AppDatabase.forTesting(NativeDatabase.memory())),
    ],
  );
}

Recommendation _rec(String action, {AlertLevel level = AlertLevel.warning}) =>
    Recommendation(
      ruleId:           'M1',
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

  group('MillingNotifier — initial state', () {
    test('lotId is set, session is null, isComplete is false', () {
      final container = _container();
      addTearDown(container.dispose);

      final state = container.read(millingProvider(lotId));
      expect(state.lotId, lotId);
      expect(state.session, isNull);
      expect(state.isComplete, isFalse);
      expect(state.recommendations, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });

  // ── register — happy path ─────────────────────────────────────────────────

  group('MillingNotifier.register — happy path', () {
    test('session saved, isComplete becomes true', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 100.0,
            outputKgGreen:    19.5,
          );

      final state = container.read(millingProvider(lotId));
      expect(state.session, isNotNull);
      expect(state.isComplete, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('yieldPct is calculated from input/output', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 100.0,
            outputKgGreen:    20.0,
          );

      final session = container.read(millingProvider(lotId)).session!;
      expect(session.yieldPct, closeTo(20.0, 0.01));
    });

    test('persists expected field values', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 80.0,
            outputKgGreen:    15.0,
            notes:            'Lote prueba',
          );

      final session = container.read(millingProvider(lotId)).session!;
      expect(session.inputKgParchment, 80.0);
      expect(session.outputKgGreen,    15.0);
      expect(session.notes,            'Lote prueba');
      expect(session.lotId,            lotId);
    });

    test('recommendations populated from AI engine', () async {
      final container = _container(
        infer: (_) => [_rec('CHECK_MILLING_PROCESS', level: AlertLevel.critical)],
      );
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 100.0,
            outputKgGreen:    12.0,
          );

      final state = container.read(millingProvider(lotId));
      expect(state.recommendations, hasLength(1));
      expect(state.recommendations.first.action, 'CHECK_MILLING_PROCESS');
    });

    test('isLoading returns to false after register completes', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 100.0,
            outputKgGreen:    19.5,
          );

      expect(container.read(millingProvider(lotId)).isLoading, isFalse);
    });

    test('aiAlertLevel stored from first recommendation', () async {
      final container = _container(
        infer: (_) => [_rec('CHECK_MILLING_PROCESS', level: AlertLevel.critical)],
      );
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 100.0,
            outputKgGreen:    12.0,
          );

      final session = container.read(millingProvider(lotId)).session!;
      expect(session.aiAlertLevel, 'critical');
    });

    test('aiAlertLevel = "none" when no recommendations', () async {
      final container = _container(infer: (_) => []);
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 100.0,
            outputKgGreen:    19.5,
          );

      final session = container.read(millingProvider(lotId)).session!;
      expect(session.aiAlertLevel,   'none');
      expect(session.aiAlertMessage, isNull);
    });

    test('millingYieldPct injected into AIContext', () async {
      AIContext? capturedCtx;
      final container = _container(
        infer: (ctx) {
          capturedCtx = ctx;
          return [];
        },
      );
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 100.0,
            outputKgGreen:    20.0,
          );

      expect(capturedCtx?.millingYieldPct, closeTo(20.0, 0.01));
    });
  });

  // ── register — error path ─────────────────────────────────────────────────

  group('MillingNotifier.register — error handling', () {
    test('error set and isLoading false when repo.save throws', () async {
      final throwingRepo = _ThrowingRepo();
      final container    = _container(repo: throwingRepo);
      addTearDown(container.dispose);

      await container.read(millingProvider(lotId).notifier).register(
            inputKgParchment: 100.0,
            outputKgGreen:    19.5,
          );

      final state = container.read(millingProvider(lotId));
      expect(state.error,     isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.session,   isNull);
    });
  });
}

// ── Helper repo that always throws ───────────────────────────────────────────

class _ThrowingRepo implements MillingRepository {
  @override Future<MillingSession?> getByLotId(String lotId) async => null;
  @override Future<MillingSession> save(MillingSession session) =>
      Future.error(Exception('disk full'));
}
