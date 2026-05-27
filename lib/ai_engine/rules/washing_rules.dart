import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class WashingRules {
  static List<AIRule> get all => const [

    // ── TEMPERATURA DEL AGUA ──────────────────────────────────────────────────
    // D-13: umbrales estimados — calibrar con Cenicafé.

    AIRule(
      id: 'WASH-TEMP-HIGH-001',
      module: 'washing',
      name: 'Agua de lavado demasiado caliente (> 30 °C)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['washing', 'temperature', 'warning'],
      conditions: [
        RuleCondition(
          variable: 'washing_water_temp_c',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.washingWaterTempCMax,
        ),
      ],
      outcome: RuleOutcome(
        action: 'REDUCE_WASH_WATER_TEMP',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.82,
        explanationByRole: {
          'farmer':    '⚠️ El agua está muy caliente ({washing_water_temp_c} °C). Use agua más fresca para no dañar el grano.',
          'processor': '⚠️ Temperatura de lavado {washing_water_temp_c} °C supera el máximo recomendado (${CoffeeThresholds.washingWaterTempCMax} °C). Riesgo de desnaturalización superficial del grano.',
          'barista':   '⚠️ Agua de lavado a {washing_water_temp_c} °C — sobre el umbral (${CoffeeThresholds.washingWaterTempCMax} °C). Puede afectar la estructura celular y la solubilidad de compuestos en taza.',
        },
        suggestedActions: [
          'Mezclar con agua más fría hasta bajar de ${CoffeeThresholds.washingWaterTempCMax} °C',
          'Usar agua de tanque nocturno (más fría)',
        ],
        parameters: {'max_temp_c': CoffeeThresholds.washingWaterTempCMax},
      ),
    ),

    AIRule(
      id: 'WASH-TEMP-LOW-001',
      module: 'washing',
      name: 'Agua de lavado demasiado fría (< 15 °C)',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['washing', 'temperature', 'info'],
      // between 0.1–14.9 evita falso positivo con el valor por defecto 0.0
      conditions: [
        RuleCondition(
          variable: 'washing_water_temp_c',
          operator: ConditionOperator.between,
          threshold: 0.1,
          thresholdMax: CoffeeThresholds.washingWaterTempCMin - 0.1,
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARM_WASH_WATER',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.72,
        explanationByRole: {
          'farmer':    'ℹ️ El agua está fría ({washing_water_temp_c} °C). Lavado más lento y menos eficiente.',
          'processor': 'ℹ️ Agua de lavado {washing_water_temp_c} °C — por debajo del rango óptimo (${CoffeeThresholds.washingWaterTempCMin}–${CoffeeThresholds.washingWaterTempCMax} °C). Puede requerir más cambios de agua.',
          'barista':   'ℹ️ Lavado a baja temperatura ({washing_water_temp_c} °C): menor remoción de mucílago residual puede intensificar notas fermentadas leves.',
        },
        suggestedActions: [
          'Calentar el agua si es posible (agua tibia, no caliente)',
          'Aumentar el número de cambios de agua para compensar',
        ],
        parameters: {'min_temp_c': CoffeeThresholds.washingWaterTempCMin},
      ),
    ),

    // ── CAMBIOS DE AGUA ───────────────────────────────────────────────────────

    AIRule(
      id: 'WASH-INSUFFICIENT-CHANGES-001',
      module: 'washing',
      name: 'Cambios de agua insuficientes (< 2)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['washing', 'water_changes', 'warning'],
      // between 1.0–1.9 detecta exactamente waterChanges == 1; evita 0 (no registrado)
      conditions: [
        RuleCondition(
          variable: 'washing_water_changes',
          operator: ConditionOperator.between,
          threshold: 1.0,
          thresholdMax: 1.9,
        ),
      ],
      outcome: RuleOutcome(
        action: 'ADD_WATER_CHANGE',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.85,
        explanationByRole: {
          'farmer':    '⚠️ Solo {washing_water_changes} cambio de agua. Se recomiendan al menos ${CoffeeThresholds.washingMinWaterChanges} para un lavado completo.',
          'processor': '⚠️ {washing_water_changes} cambio de agua — insuficiente (mínimo ${CoffeeThresholds.washingMinWaterChanges}). Mucílago residual puede promover fermentación secundaria no controlada.',
          'barista':   '⚠️ Lavado incompleto ({washing_water_changes} cambio): posible mucílago residual. En taza: riesgo de notas fermentadas no deseadas o astringencia.',
        },
        suggestedActions: [
          'Realizar al menos un cambio de agua adicional',
          'Verificar que el agua del último enjuague salga sin espuma',
        ],
        parameters: {'min_changes': CoffeeThresholds.washingMinWaterChanges},
      ),
    ),

    // ── pH DEL EFLUENTE ───────────────────────────────────────────────────────

    AIRule(
      id: 'WASH-EFFLUENT-PH-HIGH-001',
      module: 'washing',
      name: 'pH de efluente alto — fermentación posiblemente incompleta',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['washing', 'effluent_ph', 'warning'],
      // gt 5.5 — el valor por defecto 0.0 no dispara esta condición
      conditions: [
        RuleCondition(
          variable: 'washing_effluent_ph',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.washingEffluentPhWarn,
        ),
      ],
      outcome: RuleOutcome(
        action: 'CHECK_FERMENTATION_COMPLETION',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.78,
        explanationByRole: {
          'farmer':    '⚠️ El agua de enjuague tiene pH alto ({washing_effluent_ph}). Puede que el café no haya fermentado suficiente.',
          'processor': '⚠️ pH efluente {washing_effluent_ph} > ${CoffeeThresholds.washingEffluentPhWarn} — mucílago posiblemente sin degradar completamente. Considere extender fermentación o aumentar cambios de agua.',
          'barista':   '⚠️ Efluente pH {washing_effluent_ph}: fermentación incompleta puede dejar pectinas residuales — notas menos limpias y complejidad aromática reducida.',
        },
        suggestedActions: [
          'Verificar si la fermentación llegó al pH objetivo (< 4.5 para lavado)',
          'Aumentar cambios de agua y evaluar si el mucílago se desprendió completamente',
        ],
        parameters: {'effluent_ph_warn': CoffeeThresholds.washingEffluentPhWarn},
      ),
    ),
  ];
}
