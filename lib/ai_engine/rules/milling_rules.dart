import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class MillingRules {
  static List<AIRule> get all => const [

    // ── RENDIMIENTO BAJO ──────────────────────────────────────────────────────
    // D-2: umbral 18% basado en estándar SCA 18–22% — calibrar con Cenicafé.

    AIRule(
      id: 'MILL-YIELD-LOW-001',
      module: 'milling',
      name: 'Rendimiento de trilla por debajo del estándar SCA (< 18%)',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['milling', 'yield', 'critical'],
      // between 0.1–17.99: evita falso positivo con valor por defecto 0.0
      conditions: [
        RuleCondition(
          variable: 'milling_yield_pct',
          operator: ConditionOperator.between,
          threshold: 0.1,
          thresholdMax: CoffeeThresholds.millingYieldCriticalLow - 0.01,
        ),
      ],
      outcome: RuleOutcome(
        action: 'CHECK_MILLING_PROCESS',
        alertLevel: AlertLevel.critical,
        confidenceBase: 0.88,
        explanationByRole: {
          'farmer':    '🔴 Rendimiento de trilla muy bajo ({milling_yield_pct}%). Para café de especialidad se esperan entre ${CoffeeThresholds.millingYieldCriticalLow}% y ${CoffeeThresholds.millingYieldHighInfo}%. Verifique la calibración de la trilladora.',
          'processor': '🔴 Rendimiento {milling_yield_pct}% — por debajo del mínimo SCA (${CoffeeThresholds.millingYieldCriticalLow}%). Posibles causas: humedad de pergamino > 12%, calibración incorrecta de cilindros, o exceso de presión. Evaluar pérdidas de almendra.',
          'barista':   '🔴 Rendimiento de trilla {milling_yield_pct}%: merma excesiva implica pérdida de trazabilidad y posible daño físico al grano que afecta la extracción.',
        },
        suggestedActions: [
          'Verificar humedad del pergamino (óptimo 11–12%)',
          'Revisar calibración de la trilladora (separación de cilindros)',
          'Pesar nuevamente pergamino y almendra para confirmar el dato',
        ],
        parameters: {
          'min_yield_pct': CoffeeThresholds.millingYieldCriticalLow,
          'max_yield_pct': CoffeeThresholds.millingYieldHighInfo,
        },
      ),
    ),

    // ── RENDIMIENTO ALTO ──────────────────────────────────────────────────────

    AIRule(
      id: 'MILL-YIELD-HIGH-001',
      module: 'milling',
      name: 'Rendimiento de trilla por encima del rango esperado (> 22%)',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['milling', 'yield', 'info'],
      conditions: [
        RuleCondition(
          variable: 'milling_yield_pct',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.millingYieldHighInfo,
        ),
      ],
      outcome: RuleOutcome(
        action: 'VERIFY_MILLING_WEIGHT',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.72,
        explanationByRole: {
          'farmer':    'ℹ️ Rendimiento de trilla alto ({milling_yield_pct}%). Si los datos son correctos, excelente. Si hay duda, verifique el pesaje.',
          'processor': 'ℹ️ Rendimiento {milling_yield_pct}% supera el rango esperado (${CoffeeThresholds.millingYieldCriticalLow}–${CoffeeThresholds.millingYieldHighInfo}%). Confirme que los pesos de pergamino y almendra estén correctos y que no haya contaminación con material extraño.',
          'barista':   'ℹ️ Rendimiento inusualmente alto ({milling_yield_pct}%): verifique que el lote no tenga mezcla de otro material.',
        },
        suggestedActions: [
          'Confirmar pesos de entrada y salida con báscula calibrada',
          'Revisar si hay mezcla de material de otro lote',
        ],
        parameters: {
          'max_yield_pct': CoffeeThresholds.millingYieldHighInfo,
        },
      ),
    ),
  ];
}
