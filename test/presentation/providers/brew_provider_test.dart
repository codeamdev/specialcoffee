import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/brew_provider.dart';

import '../../helpers/test_context.dart';

// ── Fake InferenceAdapter ────────────────────────────────────────────────────

class _FakeAdapter extends InferenceAdapter {
  final List<Recommendation> Function(AIContext) _infer;

  _FakeAdapter(this._infer);

  @override
  Future<void> initialize() async {}

  @override
  bool get isReady => true;

  @override
  String get version => 'fake-1.0';

  @override
  Future<List<Recommendation>> infer(AIContext context) async => _infer(context);
}

Recommendation _rec({
  String ruleId = 'R001',
  String action = 'TEST_ACTION',
  AlertLevel alertLevel = AlertLevel.info,
  double confidence = 0.80,
}) =>
    Recommendation(
      ruleId: ruleId,
      action: action,
      alertLevel: alertLevel,
      confidence: confidence,
      explanation: 'Test explanation',
      suggestedActions: const [],
      parameters: const {},
      generatedAt: DateTime.now(),
    );

ProviderContainer _container(List<Recommendation> Function(AIContext) infer) {
  final engine = AIEngine.withAdapter(adapter: _FakeAdapter(infer));
  return ProviderContainer(
    overrides: [
      aiEngineProvider.overrideWith((ref) async => engine),
    ],
  );
}

void main() {
  // ── generateRecipe ─────────────────────────────────────────────────────────

  group('BrewNotifier.generateRecipe', () {
    test('sets recipe and recipeRecs in state', () async {
      final container = _container((_) => [_rec(action: 'SUGGEST_WATER_TEMP')]);
      addTearDown(container.dispose);

      final notifier = container.read(brewProvider.notifier);
      await notifier.generateRecipe(ctx(
        module: 'brewing',
        brewMethod: 'v60',
      ));

      final state = container.read(brewProvider);
      expect(state.hasRecipe, isTrue);
      expect(state.recipe!.method, 'v60');
      expect(state.isGenerating, isFalse);
    });

    test('stores AIContext in state for later diagnosis', () async {
      final container = _container((_) => []);
      addTearDown(container.dispose);

      final context = ctx(module: 'brewing', brewMethod: 'chemex');
      await container.read(brewProvider.notifier).generateRecipe(context);

      expect(container.read(brewProvider).context, isNotNull);
    });

    test('DIAGNOSE and CONFIRM actions are excluded from recipeRecs', () async {
      final container = _container((_) => [
        _rec(action: 'DIAGNOSE_UNDER_EXTRACTED'),
        _rec(action: 'CONFIRM_RECIPE'),
        _rec(action: 'SUGGEST_WATER_TEMP'),
      ]);
      addTearDown(container.dispose);

      await container.read(brewProvider.notifier).generateRecipe(
        ctx(module: 'brewing', brewMethod: 'v60'),
      );

      final state = container.read(brewProvider);
      expect(state.recipeRecs.any((r) => r.action.startsWith('DIAGNOSE')), isFalse);
      expect(state.recipeRecs.any((r) => r.action.startsWith('CONFIRM')), isFalse);
      expect(state.recipeRecs.any((r) => r.action == 'SUGGEST_WATER_TEMP'), isTrue);
    });

    test('error during generation resets state', () async {
      final engine = AIEngine.withAdapter(adapter: _FakeAdapter((_) => throw Exception('fail')));
      final container = ProviderContainer(
        overrides: [aiEngineProvider.overrideWith((ref) async => engine)],
      );
      addTearDown(container.dispose);

      await container.read(brewProvider.notifier).generateRecipe(
        ctx(module: 'brewing', brewMethod: 'v60'),
      );

      final state = container.read(brewProvider);
      expect(state.hasRecipe, isFalse);
      expect(state.isGenerating, isFalse);
    });

    test('isGenerating is true while generating, false after', () async {
      final states = <bool>[];
      final container = _container((_) => []);
      addTearDown(container.dispose);

      container.listen(
        brewProvider.select((s) => s.isGenerating),
        (bool? _, bool next) => states.add(next),
        fireImmediately: true,
      );

      await container.read(brewProvider.notifier).generateRecipe(
        ctx(module: 'brewing', brewMethod: 'v60'),
      );

      expect(states, contains(true));
      expect(states.last, isFalse);
    });
  });

  // ── diagnose ───────────────────────────────────────────────────────────────

  group('BrewNotifier.diagnose', () {
    Future<ProviderContainer> containerAfterGenerate({
      List<Recommendation> Function(AIContext)? infer,
    }) async {
      final container = _container(infer ?? (_) => []);
      await container.read(brewProvider.notifier).generateRecipe(
        ctx(module: 'brewing', brewMethod: 'v60'),
      );
      return container;
    }

    test('diagnose injects TDS and yield into context, calls recommend', () async {
      AIContext? capturedContext;
      final container = _container((c) {
        capturedContext = c;
        return [_rec(action: 'DIAGNOSE_UNDER_EXTRACTED')];
      });
      addTearDown(container.dispose);

      await container.read(brewProvider.notifier).generateRecipe(
        ctx(module: 'brewing', brewMethod: 'v60'),
      );

      await container.read(brewProvider.notifier).diagnose(
        tds: 1.25,
        yield_: 20.0,
      );

      expect(capturedContext?.measuredTdsPct, 1.25);
      expect(capturedContext?.measuredYieldPct, 20.0);
    });

    test('diagnose populates diagnosisRecs', () async {
      bool diagnosed = false;
      final container = _container((c) {
        if (diagnosed) return [_rec(action: 'DIAGNOSE_UNDER_EXTRACTED')];
        return [];
      });
      addTearDown(container.dispose);

      await container.read(brewProvider.notifier).generateRecipe(
        ctx(module: 'brewing', brewMethod: 'v60'),
      );

      diagnosed = true;
      await container.read(brewProvider.notifier).diagnose(
        tds: 1.10,
        yield_: 17.0,
      );

      final state = container.read(brewProvider);
      expect(state.hasDiagnosis, isTrue);
      expect(state.isDiagnosing, isFalse);
    });

    test('diagnose without prior generateRecipe → no-op', () async {
      final container = _container((_) => []);
      addTearDown(container.dispose);

      await container.read(brewProvider.notifier).diagnose(
        tds: 1.25,
        yield_: 20.0,
      );

      // State should remain empty (context == null)
      expect(container.read(brewProvider).hasDiagnosis, isFalse);
    });

    test('diagnose preserves recipe and recipeRecs from generate step', () async {
      final container = await containerAfterGenerate();
      addTearDown(container.dispose);

      final recipeBefore = container.read(brewProvider).recipe;

      await container.read(brewProvider.notifier).diagnose(
        tds: 1.30,
        yield_: 20.5,
      );

      expect(container.read(brewProvider).recipe, recipeBefore);
    });
  });

  // ── reset ──────────────────────────────────────────────────────────────────

  group('BrewNotifier.reset', () {
    test('reset clears all state', () async {
      final container = _container((_) => [_rec()]);
      addTearDown(container.dispose);

      await container.read(brewProvider.notifier).generateRecipe(
        ctx(module: 'brewing', brewMethod: 'v60'),
      );

      container.read(brewProvider.notifier).reset();
      final state = container.read(brewProvider);

      expect(state.hasRecipe, isFalse);
      expect(state.recipeRecs, isEmpty);
      expect(state.context, isNull);
      expect(state.hasDiagnosis, isFalse);
    });
  });
}
