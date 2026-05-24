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

    // 2. Para el mismo action, conservar solo la regla con mayor confidenceBase
    final Map<String, AIRule> byAction = {};
    for (final rule in rules) {
      final existing = byAction[rule.outcome.action];
      if (existing == null ||
          rule.outcome.confidenceBase > existing.outcome.confidenceBase) {
        byAction[rule.outcome.action] = rule;
      }
    }

    return byAction.values.toList();
  }
}
