import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class HarvestRules {
  static List<AIRule> get all => [
    // ── BRIX CRÍTICO — bloquear cosecha ──────────────────────────────────────
    const AIRule(
      id: 'HARV-BRIX-CRITICAL-001',
      module: 'harvest',
      name: 'Brix crítico — cosecha bloqueada',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['brix', 'harvest', 'critical'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.lt, threshold: CoffeeThresholds.brixCriticalMax),
      ],
      outcome: RuleOutcome(
        action: 'BLOCK_HARVEST',
        alertLevel: AlertLevel.critical,
        confidenceBase: 0.97,
        explanationByRole: {
          'farmer': '🚫 NO coseche. Brix {brix_level}° es demasiado bajo — el café estará amargo y sin dulzura.',
          'processor': '🚫 Brix {brix_level}° — crítico. Cosecha bloqueada: azúcares insuficientes para fermentación viable.',
          'barista': '🚫 Brix {brix_level}° — subdesarrollo severo. Taza sin dulzura, alta astringencia garantizada.',
        },
        suggestedActions: [
          'No cosechar bajo ninguna circunstancia',
          'Esperar mínimo 7–10 días y retomar medición',
          'Revisar nutrición del suelo si el Brix no sube en 2 semanas',
        ],
        parameters: {'wait_days_min': 7},
      ),
    ),

    // ── BRIX BAJO — advertencia fuerte ───────────────────────────────────────
    const AIRule(
      id: 'HARV-BRIX-LOW-001',
      module: 'harvest',
      name: 'Brix bajo — madurez incompleta',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['brix', 'harvest', 'warning'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.between, threshold: CoffeeThresholds.brixLowMin, thresholdMax: CoffeeThresholds.brixLowMax),
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

    // ── COSECHA ÓPTIMA ────────────────────────────────────────────────────────
    const AIRule(
      id: 'HARV-BRIX-OPTIMAL-001',
      module: 'harvest',
      name: 'Brix en rango óptimo para cosecha',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['brix', 'harvest', 'go'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.between, threshold: CoffeeThresholds.brixOptimalMin, thresholdMax: CoffeeThresholds.brixOptimalMax),
        RuleCondition(variable: 'cherry_color_pct', operator: ConditionOperator.gte, threshold: CoffeeThresholds.cherryColorOptimalMin),
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

    // ── SOBRE-MADUREZ ─────────────────────────────────────────────────────────
    const AIRule(
      id: 'HARV-BRIX-HIGH-001',
      module: 'harvest',
      name: 'Brix alto — riesgo de sobre-madurez',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['brix', 'harvest', 'overripe'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.gt, threshold: CoffeeThresholds.brixOptimalMax),
      ],
      outcome: RuleOutcome(
        action: 'HARVEST_URGENT_OVERRIPE',
        alertLevel: AlertLevel.high,
        confidenceBase: 0.87,
        explanationByRole: {
          'farmer': '⚠️ Coseche hoy. Brix {brix_level}° indica sobre-madurez — las cerezas pueden fermentar en el árbol.',
          'processor': '⚠️ Brix {brix_level}° supera 24°. Sobre-madurez activa: cosechar de inmediato.',
          'barista': '⚠️ Brix {brix_level}° — sobre-madurez. Riesgo de fermentación indeseada y defectos en taza.',
        },
        suggestedActions: [
          'Cosechar de inmediato para evitar fermentación no controlada',
          'Procesar en las próximas 6 horas post-cosecha',
          'Descartar cerezas blandas o con manchas',
        ],
        parameters: {'urgency_hours': 6},
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
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.between, threshold: CoffeeThresholds.brixOptimalMin, thresholdMax: CoffeeThresholds.brixOptimalMax),
        RuleCondition(variable: 'rain_probability_pct', operator: ConditionOperator.gte, threshold: CoffeeThresholds.rainUrgencyPct),
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

    // ── EXCESO DE VERDE — advertencia ────────────────────────────────────────
    const AIRule(
      id: 'HARV-GREEN-WARN-001',
      module: 'harvest',
      name: 'Exceso leve de cerezas verdes (>5 %)',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['ripeness', 'harvest', 'warning'],
      conditions: [
        RuleCondition(variable: 'cherry_color_pct', operator: ConditionOperator.between, threshold: CoffeeThresholds.cherryColorGreenWarnMin, thresholdMax: CoffeeThresholds.cherryColorGreenWarnMax),
      ],
      outcome: RuleOutcome(
        action: 'REDUCE_GREEN_HARVEST',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.82,
        explanationByRole: {
          'farmer': '⚠️ Hay más del 5% de cerezas verdes. Instruya a los recolectores para ser más selectivos.',
          'processor': '⚠️ Verde > 5% ({cherry_color_pct}% maduras). Puede afectar la homogeneidad del lote.',
          'barista': '⚠️ Verde > 5% — riesgo de heterogeneidad en taza. Ajustar temperatura de extracción.',
        },
        suggestedActions: [
          'Instruir recolectores: solo cerezas rojas o amarillas',
          'Separar sub-lote de verdes si supera 3 kg',
        ],
        parameters: {'green_threshold_pct': 5},
      ),
    ),

    // ── EXCESO DE VERDE — alta ────────────────────────────────────────────────
    const AIRule(
      id: 'HARV-GREEN-HIGH-001',
      module: 'harvest',
      name: 'Exceso severo de cerezas verdes (>10 %)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['ripeness', 'harvest', 'high'],
      conditions: [
        RuleCondition(variable: 'cherry_color_pct', operator: ConditionOperator.lt, threshold: CoffeeThresholds.cherryColorGreenCriticalMax),
      ],
      outcome: RuleOutcome(
        action: 'STOP_GREEN_HARVEST',
        alertLevel: AlertLevel.high,
        confidenceBase: 0.90,
        explanationByRole: {
          'farmer': '🔴 Más del 10% son verdes ({cherry_color_pct}% maduras). Suspenda el pase y re-instruya al equipo.',
          'processor': '🔴 Verde > 10% — lote fuera de estándar de especialidad. Separar o reclasificar cerezas.',
          'barista': '🔴 Verde > 10% compromete calidad en taza. Lote no recomendado para perfil de especialidad.',
        },
        suggestedActions: [
          'Suspender recolección y re-clasificar cerezas manualmente',
          'Separar verdes del lote principal',
          'Reclasificar lote si verde supera 15%',
        ],
        parameters: {'green_threshold_pct': 10},
      ),
    ),
  ];
}
