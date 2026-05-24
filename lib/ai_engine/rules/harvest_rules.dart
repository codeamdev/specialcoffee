import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class HarvestRules {
  static List<AIRule> get all => [
    // ── COSECHA ÓPTIMA ────────────────────────────────────────────────────────
    const AIRule(
      id: 'HARV-BRIX-OPTIMAL-001',
      module: 'harvest',
      name: 'Brix en rango óptimo para cosecha',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['brix', 'harvest', 'go'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.between, threshold: 20.0, thresholdMax: 24.0),
        RuleCondition(variable: 'cherry_color_pct', operator: ConditionOperator.gte, threshold: 75),
      ],
      outcome: RuleOutcome(
        action: 'HARVEST_NOW',
        alertLevel: AlertLevel.none,
        confidenceBase: 0.92,
        explanationByRole: {
          'farmer': '✅ Coseche ahora — sus cerezas están en el punto justo de madurez.',
          'processor': '✅ Brix {brix_level}° y {cherry_color_pct}% de color rojo. Condiciones óptimas de cosecha.',
          'barista': '✅ Brix {brix_level}° — madurez completa. Perfil azucarado esperado en taza.',
        },
        suggestedActions: [
          'Iniciar cosecha selectiva en las próximas 36 horas',
          'Separar cerezas por nivel de madurez si es posible',
        ],
        parameters: {'harvest_window_hours': 36},
      ),
    ),

    // ── COSECHA PREMATURA ─────────────────────────────────────────────────────
    const AIRule(
      id: 'HARV-BRIX-LOW-001',
      module: 'harvest',
      name: 'Brix bajo — madurez incompleta',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['brix', 'harvest', 'warning'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.between, threshold: 17.0, thresholdMax: 19.9),
      ],
      outcome: RuleOutcome(
        action: 'DELAY_HARVEST',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.88,
        explanationByRole: {
          'farmer': '⚠️ Espere 3–5 días más. Sus cerezas aún no están dulces. Cosechar ahora da café amargo.',
          'processor': '⚠️ Brix {brix_level}° — subóptimo. Posponer cosecha 3–5 días para desarrollo de azúcares.',
          'barista': '⚠️ Brix {brix_level}° — subdesarrollo de azúcares. Riesgo de astringencia y baja dulzura en taza.',
        },
        suggestedActions: [
          'Posponer cosecha mínimo 3 días',
          'Nueva lectura de Brix en 48 horas',
          'Si lluvia en pronóstico, evaluar riesgo de esperar',
        ],
        parameters: {
          'wait_days_min': 3,
          'wait_days_max': 5,
          'recheck_hours': 48,
        },
      ),
    ),

    // ── COSECHA URGENTE POR LLUVIA ────────────────────────────────────────────
    const AIRule(
      id: 'HARV-RAIN-URGENT-001',
      module: 'harvest',
      name: 'Cosecha urgente por lluvia inminente',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['harvest', 'weather', 'urgent'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.between, threshold: 19.0, thresholdMax: 24.0),
        RuleCondition(variable: 'rain_probability_pct', operator: ConditionOperator.gte, threshold: 70.0),
      ],
      outcome: RuleOutcome(
        action: 'HARVEST_URGENT',
        alertLevel: AlertLevel.high,
        confidenceBase: 0.85,
        explanationByRole: {
          'farmer': '⚠️ Coseche hoy si puede — la lluvia puede dañar las cerezas y diluir el azúcar.',
          'processor': '⚠️ Lluvia > 70% en 24h con Brix {brix_level}°. Cosecha de emergencia recomendada hoy.',
          'barista': '⚠️ Lluvia inminente con Brix en transición. Cosecha ahora preserva el desarrollo alcanzado.',
        },
        suggestedActions: [
          'Cosechar en las próximas 12 horas',
          'Priorizar parcelas de mayor altitud (más expuestas)',
        ],
        parameters: {'urgency_hours': 12},
      ),
    ),
  ];
}
