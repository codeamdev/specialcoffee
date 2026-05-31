import 'package:special_coffee/ai_engine/models/ai_rule.dart';

/// Limpia el conjunto de reglas disparadas eliminando contradicciones
/// y reglas supersedidas antes de construir las recomendaciones finales.
class ConflictResolver {
  List<AIRule> resolve(List<AIRule> firedRules) {
    if (firedRules.length <= 1) return firedRules;

    var rules = List<AIRule>.from(firedRules);

    // 1. Eliminar reglas explícitamente supersedidas
    final supersededIds = rules
        .where((r) => r.supersedes != null)
        .map((r) => r.supersedes!)
        .toSet();
    rules = rules.where((r) => !supersededIds.contains(r.id)).toList();

    // 2. Para el mismo action: priorizar alertLevel; desempatar por confidenceBase.
    // critical(4) > high(3) > warning(2) > info(1) > none(0) — orden del enum.
    final Map<String, AIRule> byAction = {};
    for (final rule in rules) {
      final existing = byAction[rule.outcome.action];
      if (existing == null || _beats(rule, existing)) {
        byAction[rule.outcome.action] = rule;
      }
    }

    return byAction.values.toList();
  }

  // Devuelve true si `challenger` debe reemplazar a `incumbent` para el mismo action.
  static bool _beats(AIRule challenger, AIRule incumbent) {
    final cp = _alertPriority(challenger);
    final ip = _alertPriority(incumbent);
    if (cp != ip) return cp > ip;
    return challenger.outcome.confidenceBase > incumbent.outcome.confidenceBase;
  }

  static int _alertPriority(AIRule rule) => rule.outcome.alertLevel.index;
}
