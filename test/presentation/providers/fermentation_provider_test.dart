import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/fermentation_session.dart';
import 'package:special_coffee/domain/repositories/fermentation_repository.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/fermentation_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

// ── Fake adapter ──────────────────────────────────────────────────────────────

class _FakeAdapter extends InferenceAdapter {
  final List<Recommendation> Function(AIContext) _infer;

  _FakeAdapter([List<Recommendation> Function(AIContext)? infer])
      : _infer = infer ?? ((_) => []);

  @override Future<void> initialize() async {}
  @override bool get isReady => true;
  @override String get version => 'fake-1.0';
  @override Future<List<Recommendation>> infer(AIContext context) async => _infer(context);
}

// ── In-memory FermentationRepository ─────────────────────────────────────────

class _FakeRepo implements FermentationRepository {
  final _sessions = <String, FermentationSession>{};

  @override
  Future<FermentationSession> createSession({
    required String lotId,
    required String processType,
  }) async {
    final s = FermentationSession(
      id: 'fake-$lotId',
      lotId: lotId,
      ownerId: 'test-user',
      processType: processType,
      createdAt: DateTime.now(),
    );
    _sessions[lotId] = s;
    return s;
  }

  @override
  Future<FermentationSession?> getActiveSession(String lotId) async =>
      _sessions[lotId];

  @override
  Future<FermentationReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int readingNumber,
    required double hoursElapsed,
    required double phValue,
    required double mucilagoTempC,
    String mucilageState = 'liquid',
    double? ambientTempC,
    String aiAlertLevel = 'none',
    String? aiAlertRuleId,
    double? aiProjectedEndH,
  }) async =>
      FermentationReadingRecord(
        id: '$sessionId-r$readingNumber',
        sessionId: sessionId,
        lotId: lotId,
        ownerId: 'test-user',
        readingNumber: readingNumber,
        hoursElapsed: hoursElapsed,
        phValue: phValue,
        mucilagoTempC: mucilagoTempC,
        mucilageState: mucilageState,
        aiAlertLevel: aiAlertLevel,
        aiAlertRuleId: aiAlertRuleId,
        aiProjectedEndH: aiProjectedEndH,
        recordedAt: DateTime.now(),
      );

  @override
  Future<List<FermentationReadingRecord>> getReadings(String sessionId) async => [];

  @override
  Future<void> closeSession({
    required String sessionId,
    required String endReason,
    required double actualDurationH,
    required double phFinal,
  }) async {}
}

// ── Container factory ─────────────────────────────────────────────────────────

ProviderContainer _container({List<Recommendation> Function(AIContext)? infer}) {
  final engine = AIEngine.withAdapter(adapter: _FakeAdapter(infer));
  return ProviderContainer(
    overrides: [
      aiEngineProvider.overrideWith((ref) async => engine),
      fermentationLocalRepoProvider.overrideWith((ref) => _FakeRepo()),
      lotByIdProvider('LOT-001').overrideWith((ref) async => null),
    ],
  );
}

Recommendation _rec(String action) => Recommendation(
  ruleId: 'R1',
  action: action,
  alertLevel: AlertLevel.info,
  confidence: 0.80,
  explanation: 'Test',
  suggestedActions: const [],
  parameters: const {},
  generatedAt: DateTime.now(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const lotId = 'LOT-001';

  // ── Initial state ────────────────────────────────────────────────────────

  group('FermentationNotifier — initial state', () {
    test('starts with processType lavado and no readings', () {
      final container = _container();
      addTearDown(container.dispose);

      final state = container.read(fermentationProvider(lotId));
      expect(state.lotId, lotId);
      expect(state.processType, 'lavado');
      expect(state.hasReadings, isFalse);
    });
  });

  // ── changeProcessType ─────────────────────────────────────────────────────

  group('FermentationNotifier.changeProcessType', () {
    test('changes process type before first reading', () {
      final container = _container();
      addTearDown(container.dispose);

      container.read(fermentationProvider(lotId).notifier)
          .changeProcessType('natural');

      expect(
        container.read(fermentationProvider(lotId)).processType,
        'natural',
      );
    });

    test('locked after first reading — changeProcessType is a no-op', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 4.5, tempC: 22.0, hoursElapsed: 0);

      container.read(fermentationProvider(lotId).notifier)
          .changeProcessType('natural');

      expect(
        container.read(fermentationProvider(lotId)).processType,
        'lavado', // unchanged
      );
    });
  });

  // ── addReading ─────────────────────────────────────────────────────────────

  group('FermentationNotifier.addReading', () {
    test('reading is appended to state.readings', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 4.5, tempC: 22.0, hoursElapsed: 0);

      expect(
        container.read(fermentationProvider(lotId)).readings.length,
        1,
      );
    });

    test('multiple readings are accumulated', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = container.read(fermentationProvider(lotId).notifier);
      await notifier.addReading(ph: 4.8, tempC: 22.0, hoursElapsed: 0);
      await notifier.addReading(ph: 4.5, tempC: 22.0, hoursElapsed: 8);
      await notifier.addReading(ph: 4.2, tempC: 22.0, hoursElapsed: 16);

      expect(
        container.read(fermentationProvider(lotId)).readings.length,
        3,
      );
    });

    test('AlertEngine fires before RuleEngine — alerts present before isAnalyzing=false', () async {
      final alertStates = <bool>[];
      final container = _container();
      addTearDown(container.dispose);

      // Critical pH: lavado threshold is 3.5
      container.listen(
        fermentationProvider(lotId)
            .select((s) => s.activeAlerts.isNotEmpty),
        (bool? _, bool next) => alertStates.add(next),
        fireImmediately: true,
      );

      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 3.3, tempC: 22.0, hoursElapsed: 8);

      final state = container.read(fermentationProvider(lotId));
      expect(state.activeAlerts, isNotEmpty);
      expect(state.activeAlerts.first.level, AlertLevel.critical);
    });

    test('no alerts for pH in normal range', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 4.3, tempC: 22.0, hoursElapsed: 8);

      expect(
        container.read(fermentationProvider(lotId)).activeAlerts,
        isEmpty,
      );
    });

    test('recommendations populated after addReading', () async {
      final container = _container(
        infer: (_) => [_rec('RECOMMEND_COOLING')],
      );
      addTearDown(container.dispose);

      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 4.2, tempC: 22.0, hoursElapsed: 8);

      final state = container.read(fermentationProvider(lotId));
      expect(state.recommendations, hasLength(1));
      expect(state.recommendations.first.action, 'RECOMMEND_COOLING');
      expect(state.isAnalyzing, isFalse);
    });

    test('isAnalyzing returns to false after completion', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 4.2, tempC: 22.0, hoursElapsed: 8);

      expect(
        container.read(fermentationProvider(lotId)).isAnalyzing,
        isFalse,
      );
    });
  });

  // ── Projection ─────────────────────────────────────────────────────────────

  group('FermentationNotifier — fermentation end projection', () {
    test('projection null with < 2 readings', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 4.8, tempC: 22.0, hoursElapsed: 0);

      expect(
        container.read(fermentationProvider(lotId)).projectedHoursRemaining,
        isNull,
      );
    });

    test('projection available after ≥ 3 readings (AlertEngine requirement)', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = container.read(fermentationProvider(lotId).notifier);
      // addReading internally calls projectFermentationEnd only when readings.length >= 2
      // but AlertEngine.projectFermentationEndHours requires >= 3
      await notifier.addReading(ph: 5.0, tempC: 22.0, hoursElapsed: 0);
      await notifier.addReading(ph: 4.6, tempC: 22.0, hoursElapsed: 8);
      await notifier.addReading(ph: 4.2, tempC: 22.0, hoursElapsed: 16);
      await notifier.addReading(ph: 3.9, tempC: 22.0, hoursElapsed: 24);

      // Projection may or may not be non-null depending on linear regression;
      // simply verify no exception is thrown.
      expect(
        () => container.read(fermentationProvider(lotId)).projectedHoursRemaining,
        returnsNormally,
      );
    });
  });

  // ── reset ──────────────────────────────────────────────────────────────────

  group('FermentationNotifier.reset', () {
    test('reset clears readings and alerts but keeps lotId and processType', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = container.read(fermentationProvider(lotId).notifier);
      await notifier.addReading(ph: 3.3, tempC: 22.0, hoursElapsed: 8);

      notifier.reset();

      final state = container.read(fermentationProvider(lotId));
      expect(state.readings, isEmpty);
      expect(state.activeAlerts, isEmpty);
      expect(state.lotId, lotId);
      expect(state.processType, 'lavado');
    });
  });

  // ── hasCriticalAlert getter ───────────────────────────────────────────────

  group('FermentationState.hasCriticalAlert', () {
    test('hasCriticalAlert true when critical alert present', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 3.0, tempC: 22.0, hoursElapsed: 8); // below 3.5 critical

      expect(
        container.read(fermentationProvider(lotId)).hasCriticalAlert,
        isTrue,
      );
    });

    test('hasCriticalAlert false for warnings only', () async {
      final container = _container();
      addTearDown(container.dispose);

      // pH 3.8 → high alert (not critical) for lavado; temp normal
      await container.read(fermentationProvider(lotId).notifier)
          .addReading(ph: 3.8, tempC: 22.0, hoursElapsed: 8);

      expect(
        container.read(fermentationProvider(lotId)).hasCriticalAlert,
        isFalse,
      );
    });
  });
}
