import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class DepulpingRules {
  static List<AIRule> get all => [
    // ── RETRASO DESPULPADO — warning ──────────────────────────────────────────
    // warning 6h: escalón preventivo (sin respaldo documental propio — D-7).
    const AIRule(
      id: 'DEPU-RETRASO-WARN-001',
      module: 'depulping',
      name: 'Retraso al despulpado — advertencia (> 6 h)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['depulping', 'timing', 'warning'],
      conditions: [
        RuleCondition(
          variable: 'hours_from_depulping_reference',
          operator: ConditionOperator.gte,
          threshold: CoffeeThresholds.depulpingWarnH,
        ),
      ],
      outcome: RuleOutcome(
        action: 'DEPULP_DELAYED',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.82,
        explanationByRole: {
          'farmer':    '⚠️ Han pasado {hours_from_depulping_reference} horas desde la referencia. Despulpe pronto para evitar fermentación indeseada.',
          'processor': '⚠️ {hours_from_depulping_reference} h desde referencia — superando las 6 h preventivas. Despulpado urgente recomendado.',
          'barista':   '⚠️ Retraso de {hours_from_depulping_reference} h puede generar notas fermentadas indeseadas en taza.',
        },
        suggestedActions: [
          'Despulpar en la próxima hora',
          'Mantener cerezas a la sombra y con ventilación hasta despulpar',
        ],
        parameters: {'warn_hours': CoffeeThresholds.depulpingWarnH},
      ),
    ),

    // ── RETRASO DESPULPADO — crítico ──────────────────────────────────────────
    // critical 8h: proviene de C-1 (auditoría del proyecto). D-7 para calibración.
    const AIRule(
      id: 'DEPU-RETRASO-CRITICAL-001',
      module: 'depulping',
      name: 'Retraso al despulpado — crítico (> 8 h)',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['depulping', 'timing', 'critical'],
      conditions: [
        RuleCondition(
          variable: 'hours_from_depulping_reference',
          operator: ConditionOperator.gte,
          threshold: CoffeeThresholds.depulpingCriticalH,
        ),
      ],
      outcome: RuleOutcome(
        action: 'DEPULP_URGENT',
        alertLevel: AlertLevel.critical,
        confidenceBase: 0.90,
        explanationByRole: {
          'farmer':    '🔴 Más de 8 h sin despulpar. Las cerezas pueden estar iniciando fermentación no controlada — actúe ahora.',
          'processor': '🔴 {hours_from_depulping_reference} h desde referencia — supera el límite crítico de 8 h (C-1). Despulpar de inmediato.',
          'barista':   '🔴 Más de 8 h sin despulpar compromete el perfil del lote. Alta probabilidad de defectos fermentativos en taza.',
        },
        suggestedActions: [
          'Despulpar de inmediato sin excepción',
          'Revisar si alguna cereza ya muestra señales de fermentación (olor, textura)',
          'Documentar el retraso para correlacionar con catación final del lote',
        ],
        parameters: {'critical_hours': CoffeeThresholds.depulpingCriticalH},
      ),
    ),
  ];
}
