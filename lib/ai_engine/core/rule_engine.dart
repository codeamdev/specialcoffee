import 'package:special_coffee/ai_engine/core/conflict_resolver.dart';
import 'package:special_coffee/ai_engine/evaluators/condition_evaluator.dart';
import 'package:special_coffee/ai_engine/evaluators/confidence_adjuster.dart';
import 'package:special_coffee/ai_engine/evaluators/explanation_builder.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

/// Motor de reglas central.
///
/// Pipeline de 6 pasos:
///   1. Filtrar reglas por módulo activo
///   2. Evaluar condiciones de cada regla
///   3. Resolver conflictos entre reglas activadas
///   4. Ajustar confianza según calidad del contexto
///   5. Ordenar por prioridad (desc urgencia) luego confianza
///   6. Construir Recommendations con texto personalizado por rol
///
/// Garantía de rendimiento: evaluación completa < 5ms en release mode.
class RuleEngine {
  final ConditionEvaluator _evaluator;
  final ExplanationBuilder _explanationBuilder;
  final ConflictResolver _conflictResolver;
  final ConfidenceAdjuster _confidenceAdjuster;

  List<AIRule> _rules = [];
  String _rulesVersion = '';

  RuleEngine({
    ConditionEvaluator? evaluator,
    ExplanationBuilder? explanationBuilder,
    ConflictResolver? conflictResolver,
    ConfidenceAdjuster? confidenceAdjuster,
  })  : _evaluator = evaluator ?? ConditionEvaluator(),
        _explanationBuilder = explanationBuilder ?? ExplanationBuilder(),
        _conflictResolver = conflictResolver ?? ConflictResolver(),
        _confidenceAdjuster = confidenceAdjuster ?? ConfidenceAdjuster();

  String get rulesVersion => _rulesVersion;
  int get rulesCount => _rules.length;

  void loadRules(List<AIRule> rules, {String version = '1.0'}) {
    _rules = rules.where((r) => r.active).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    _rulesVersion = version;
  }

  List<Recommendation> evaluate(AIContext context) {
    assert(_rules.isNotEmpty, 'RuleEngine: loadRules() debe llamarse antes de evaluate()');

    // ── 1. Filtrar por módulo ─────────────────────────────────────────────────
    final moduleRules = _rules
        .where((r) => r.module == context.module || r.module == 'global')
        .toList();

    if (moduleRules.isEmpty) return [];

    // ── 2. Evaluar condiciones ────────────────────────────────────────────────
    final firedRules = moduleRules.where(_allConditionsMet(context)).toList();

    if (firedRules.isEmpty) return [];

    // ── 3. Resolver conflictos ────────────────────────────────────────────────
    final resolvedRules = _conflictResolver.resolve(firedRules);

    // ── 4. Ajustar confianza ──────────────────────────────────────────────────
    final scored = resolvedRules.map((rule) => (
      rule: rule,
      confidence: _confidenceAdjuster.adjust(
        baseConfidence: rule.outcome.confidenceBase,
        rule: rule,
        context: context,
      ),
    )).toList();

    // ── 5. Ordenar: prioridad (1=más urgente) → confianza (desc) ─────────────
    scored.sort((a, b) {
      final byPriority = a.rule.priority.compareTo(b.rule.priority);
      if (byPriority != 0) return byPriority;
      return b.confidence.compareTo(a.confidence);
    });

    // ── 6. Construir recomendaciones con texto personalizado ──────────────────
    return scored.map((s) => Recommendation(
      ruleId: s.rule.id,
      action: s.rule.outcome.action,
      alertLevel: s.rule.outcome.alertLevel,
      confidence: s.confidence,
      explanation: _explanationBuilder.build(
        rule: s.rule,
        context: context,
        confidence: s.confidence,
      ),
      suggestedActions: s.rule.outcome.suggestedActions,
      parameters: s.rule.outcome.parameters,
      generatedAt: DateTime.now(),
    )).toList();
  }

  bool Function(AIRule) _allConditionsMet(AIContext context) => (rule) {
    if (rule.conditions.isEmpty) return false;
    return switch (rule.logic) {
      RuleLogic.and => rule.conditions.every((c) => _evaluator.evaluate(c, context)),
      RuleLogic.or  => rule.conditions.any((c) => _evaluator.evaluate(c, context)),
    };
  };
}
