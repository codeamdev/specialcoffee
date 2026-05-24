import 'package:special_coffee/ai_engine/adapters/gemini_inference_adapter.dart';
import 'package:special_coffee/ai_engine/adapters/inference_adapter.dart';
import 'package:special_coffee/ai_engine/adapters/rule_based_adapter.dart';
import 'package:special_coffee/ai_engine/core/alert_engine.dart';
import 'package:special_coffee/ai_engine/core/brew_recipe_generator.dart';
import 'package:special_coffee/ai_engine/core/conflict_resolver.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/evaluators/condition_evaluator.dart';
import 'package:special_coffee/ai_engine/evaluators/confidence_adjuster.dart';
import 'package:special_coffee/ai_engine/evaluators/explanation_builder.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/models/alert.dart';
import 'package:special_coffee/ai_engine/models/brew_recipe.dart';

export 'models/ai_context.dart';
export 'models/ai_rule.dart';
export 'models/brew_recipe.dart';
export 'models/alert.dart';
export 'adapters/inference_adapter.dart';
export 'adapters/gemini_inference_adapter.dart' show GeminiStatus;

/// Fachada principal del motor de IA.
/// Los Riverpod providers y los use cases solo hablan con esta clase.
///
/// Uso:
/// ```dart
/// final engine = AIEngine.create(rulesBox: Hive.box('ai_rules'));
/// await engine.initialize();
///
/// final recommendations = engine.recommend(context);
/// final recipe = engine.generateRecipe(context);
/// final alerts = engine.checkFermentationReading(ph: 3.4, ...);
/// ```
class AIEngine {
  final InferenceAdapter _adapter;
  final AlertEngine _alertEngine;
  final BrewRecipeGenerator _recipeGenerator;

  AIEngine._({
    required InferenceAdapter adapter,
    required AlertEngine alertEngine,
    required BrewRecipeGenerator recipeGenerator,
  })  : _adapter = adapter,
        _alertEngine = alertEngine,
        _recipeGenerator = recipeGenerator;

  /// Factory por defecto — usa solo el Rule Engine (on-device, offline).
  factory AIEngine.create() {
    final ruleEngine = RuleEngine(
      evaluator: ConditionEvaluator(),
      explanationBuilder: ExplanationBuilder(),
      conflictResolver: ConflictResolver(),
      confidenceAdjuster: ConfidenceAdjuster(),
    );
    return AIEngine._(
      adapter: RuleBasedInferenceAdapter(engine: ruleEngine),
      alertEngine: AlertEngine(),
      recipeGenerator: BrewRecipeGenerator(),
    );
  }

  /// Factory con Gemini — usa Gemini como motor principal con Rule Engine como fallback.
  factory AIEngine.withGemini({required String geminiApiKey}) {
    final ruleEngine = RuleEngine(
      evaluator: ConditionEvaluator(),
      explanationBuilder: ExplanationBuilder(),
      conflictResolver: ConflictResolver(),
      confidenceAdjuster: ConfidenceAdjuster(),
    );
    final ruleFallback = RuleBasedInferenceAdapter(engine: ruleEngine);
    return AIEngine._(
      adapter: GeminiInferenceAdapter(
        apiKey: geminiApiKey,
        ruleFallback: ruleFallback,
      ),
      alertEngine: AlertEngine(),
      recipeGenerator: BrewRecipeGenerator(),
    );
  }

  /// Constructor para testing — inyecta un adaptador personalizado.
  factory AIEngine.withAdapter({
    required InferenceAdapter adapter,
    AlertEngine? alertEngine,
    BrewRecipeGenerator? recipeGenerator,
  }) =>
      AIEngine._(
        adapter: adapter,
        alertEngine: alertEngine ?? AlertEngine(),
        recipeGenerator: recipeGenerator ?? BrewRecipeGenerator(),
      );

  Future<void> initialize() => _adapter.initialize();

  bool get isReady => _adapter.isReady;
  String get version => _adapter.version;

  /// Estado actual de la conexión con Gemini.
  /// Siempre [GeminiStatus.active] cuando se usa solo el Rule Engine.
  GeminiStatus get geminiStatus {
    final a = _adapter;
    return a is GeminiInferenceAdapter ? a.status : GeminiStatus.active;
  }

  // ── API principal ─────────────────────────────────────────────────────────

  /// Evalúa el contexto completo y retorna recomendaciones ordenadas por urgencia.
  Future<List<Recommendation>> recommend(AIContext context) => _adapter.infer(context);

  /// Retorna solo la recomendación más urgente (o null si no hay ninguna).
  Future<Recommendation?> topRecommendation(AIContext context) async {
    final results = await recommend(context);
    return results.isEmpty ? null : results.first;
  }

  /// Evalúa una nueva lectura de fermentación sin reconstruir el contexto completo.
  /// Retorna alertas activas inmediatamente (<1ms).
  List<Alert> checkFermentationReading({
    required double ph,
    required double mucilagoTemp,
    required String processType,
    required String lotId,
  }) =>
      _alertEngine.evaluateFermentationReading(
        ph: ph,
        mucilagoTemp: mucilagoTemp,
        processType: processType,
        lotId: lotId,
      );

  /// Proyecta cuántas horas faltan para completar la fermentación.
  double? projectFermentationEnd({
    required List<FermentationReading> readings,
    required String processType,
  }) {
    final targetPh = switch (processType) {
      'lavado'           => 4.0,
      'natural'          => 3.8,
      'anaerobic_lactic' => 3.5,
      _                  => 4.0,
    };
    return _alertEngine.projectFermentationEndHours(
      readings: readings,
      targetPhMin: targetPh,
    );
  }

  /// Genera una receta de preparación personalizada algorítmicamente.
  BrewRecipe generateRecipe(AIContext context) => _recipeGenerator.generate(context);
}
