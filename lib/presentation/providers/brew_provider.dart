import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/models/brew_recipe.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';

part 'brew_provider.g.dart';

// ── State ─────────────────────────────────────────────────────────────────

class BrewState {
  final BrewRecipe? recipe;
  final List<Recommendation> recipeRecs;
  final AIContext? context;
  final List<Recommendation> diagnosisRecs;
  final bool isGenerating;
  final bool isDiagnosing;

  const BrewState({
    this.recipe,
    this.recipeRecs = const [],
    this.context,
    this.diagnosisRecs = const [],
    this.isGenerating = false,
    this.isDiagnosing = false,
  });

  bool get hasRecipe => recipe != null;
  bool get hasDiagnosis => diagnosisRecs.isNotEmpty;
}

// ── Notifier ──────────────────────────────────────────────────────────────

@riverpod
class BrewNotifier extends _$BrewNotifier {
  @override
  BrewState build() => const BrewState();

  /// Generates a recipe (BrewRecipeGenerator) and recipe-level recommendations
  /// (RuleEngine) from the same AIContext in one call.
  Future<void> generateRecipe(AIContext context) async {
    state = const BrewState(isGenerating: true);
    try {
      final engine = await ref.read(aiEngineProvider.future);
      final recipe  = engine.generateRecipe(context);
      final allRecs = await engine.recommend(context);
      ref.invalidate(geminiStatusProvider);
      // Exclude diagnosis rules — they need real TDS/yield measurements to be
      // meaningful. Without them, DIAG-UNDER fires as a false positive because
      // measuredTdsPct defaults to 0.0 < 1.15.
      final recipeRecs = allRecs
          .where((r) =>
              !r.action.startsWith('DIAGNOSE') &&
              !r.action.startsWith('CONFIRM'))
          .toList();
      state = BrewState(recipe: recipe, recipeRecs: recipeRecs, context: context);
    } catch (_) {
      state = const BrewState();
    }
  }

  /// Runs post-extraction diagnosis by injecting TDS / yield into the stored
  /// AIContext and re-running the RuleEngine.
  Future<void> diagnose({required double tds, required double yield_}) async {
    if (state.context == null) return;

    state = BrewState(
      recipe: state.recipe,
      recipeRecs: state.recipeRecs,
      context: state.context,
      isDiagnosing: true,
    );

    try {
      final diagContext = state.context!.copyWith(
        measuredTdsPct: tds,
        measuredYieldPct: yield_,
      );
      final engine = await ref.read(aiEngineProvider.future);
      final recs   = await engine.recommend(diagContext);
      ref.invalidate(geminiStatusProvider);
      state = BrewState(
        recipe: state.recipe,
        recipeRecs: state.recipeRecs,
        context: state.context,
        diagnosisRecs: recs,
      );
    } catch (_) {
      state = BrewState(
        recipe: state.recipe,
        recipeRecs: state.recipeRecs,
        context: state.context,
      );
    }
  }

  void reset() => state = const BrewState();
}
