import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class DryingRules {
  static List<AIRule> get all => const [
    AIRule(
      id: 'DRY-TARGET-REACHED-001',
      module: 'drying',
      name: 'Humedad objetivo de secado alcanzada',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['humidity', 'endpoint', 'drying'],
      conditions: [
        RuleCondition(variable: 'current_humidity_pct', operator: ConditionOperator.between, threshold: 10.5, thresholdMax: 12.0),
      ],
      outcome: RuleOutcome(
        action: 'DRYING_COMPLETE',
        alertLevel: AlertLevel.none,
        confidenceBase: 0.95,
        explanationByRole: {
          'farmer': '✅ El café alcanzó la humedad ideal ({current_humidity_pct}%). Llévelo a la bodega en bolsa GrainPro o hermética.',
          'processor': '✅ Humedad {current_humidity_pct}% — dentro del rango SCA (10.5–12.0%). Transferir a almacenamiento. Reposo mínimo: 30 días.',
          'barista': '✅ Punto de secado ideal: {current_humidity_pct}%. Estabilización completada.',
        },
        suggestedActions: [
          'Transferir inmediatamente a bodega fresca (< 20°C)',
          'Usar empaque hermético o GrainPro',
          'Registrar el peso final (pergamino seco)',
          'Dejar reposar mínimo 30 días antes de trillar',
        ],
        parameters: {'min_rest_days': 30, 'max_storage_temp_c': 20},
      ),
    ),

    AIRule(
      id: 'DRY-OVER-DRIED-001',
      module: 'drying',
      name: 'Sobredesecado — humedad por debajo del mínimo',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['humidity', 'critical', 'drying'],
      conditions: [
        RuleCondition(variable: 'current_humidity_pct', operator: ConditionOperator.lt, threshold: 10.0),
      ],
      outcome: RuleOutcome(
        action: 'STOP_DRYING_OVERSHOOTING',
        alertLevel: AlertLevel.high,
        confidenceBase: 0.93,
        explanationByRole: {
          'farmer': '⚠️ El café está muy seco ({current_humidity_pct}%). Retírelo del sol ahora — si sigue, el grano se quiebra fácil y pierde calidad.',
          'processor': '⚠️ Humedad {current_humidity_pct}% — por debajo del mínimo (10.5%). Transferir urgente. Riesgo de grano fragmentado y pérdida de rendimiento en trilla.',
          'barista': '⚠️ Sobredesecado ({current_humidity_pct}%). En taza: riesgo de notas de madera, cuerpo reducido y pérdida de complejidad aromática.',
        },
        suggestedActions: [
          'Retirar del área de secado inmediatamente',
          'Almacenar en ambiente controlado (65–70% HR)',
          'No trillar hasta que estabilice humedad',
        ],
        parameters: {'urgency': 'immediate'},
      ),
    ),

    AIRule(
      id: 'DRY-SLOW-PROGRESS-001',
      module: 'drying',
      name: 'Progreso de secado lento — debajo de curva esperada',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['drying', 'warning', 'progress'],
      conditions: [
        RuleCondition(variable: 'drying_day_number', operator: ConditionOperator.gte, threshold: 8),
        RuleCondition(variable: 'current_humidity_pct', operator: ConditionOperator.gt, threshold: 30.0),
      ],
      outcome: RuleOutcome(
        action: 'INCREASE_DRYING_ACTIVITY',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.81,
        explanationByRole: {
          'farmer': '⚠️ En el día {drying_day_number}, su café debería estar por debajo de 30%. Aumente los volteos y la exposición al sol.',
          'processor': '⚠️ Día {drying_day_number}: {current_humidity_pct}% — por debajo de curva esperada. Revisar cobertura nocturna, frecuencia de volteos y exposición solar.',
          'barista': '⚠️ Secado retrasado en día {drying_day_number}. Humedad prolongada puede favorecer hongos y defectos.',
        },
        suggestedActions: [
          'Aumentar volteos a mínimo 5 veces por día',
          'Verificar que las camas no estén sobrecargadas',
          'Extender en capas más delgadas si es posible',
        ],
        parameters: {},
      ),
    ),

    // ── ESTRÉS TÉRMICO ────────────────────────────────────────────────────────
    // D-14: umbral 35 °C estimado — calibrar con Cenicafé (secado en cama africana).

    AIRule(
      id: 'DRY-HEAT-STRESS-001',
      module: 'drying',
      name: 'Temperatura ambiente crítica — riesgo de agrietamiento',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['drying', 'temperature', 'warning'],
      conditions: [
        RuleCondition(
          variable: 'ambient_temp_c',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.dryingHeatStressTempC,
        ),
      ],
      outcome: RuleOutcome(
        action: 'REDUCE_SUN_EXPOSURE',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.83,
        explanationByRole: {
          'farmer':    '⚠️ Hace mucho calor ({ambient_temp_c} °C). Cubra o mueva el café para que no se seque demasiado rápido y se quiebre.',
          'processor': '⚠️ Temperatura ambiente {ambient_temp_c} °C supera {drying_heat_stress_temp_c} °C. Secado excesivamente rápido → agrietamiento del grano y pérdida de rendimiento en trilla.',
          'barista':   '⚠️ Calor extremo ({ambient_temp_c} °C): secado acelerado puede generar gradientes de humedad internos → grano quebradizo y pérdida de densidad → menor rendimiento de extracción.',
        },
        suggestedActions: [
          'Cubrir las camas con malla de sombra al 30–50 % en las horas de mayor calor',
          'Aumentar los volteos para uniformizar la temperatura del lecho',
          'Trasladar el café a la sombra si supera 40 °C',
        ],
        parameters: {'heat_stress_temp_c': CoffeeThresholds.dryingHeatStressTempC},
      ),
    ),

    // ── HUMEDAD AMBIENTAL ALTA ────────────────────────────────────────────────
    // D-14: umbrales 80 % y 85 % estimados — calibrar con Cenicafé.
    // DRY-CRITICAL-AMBIENT-HUMIDITY-001 supersede este warning cuando HR > 85 %.

    AIRule(
      id: 'DRY-HIGH-AMBIENT-HUMIDITY-001',
      module: 'drying',
      name: 'Humedad relativa alta — riesgo de hongos',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['drying', 'humidity', 'mold', 'warning'],
      conditions: [
        RuleCondition(
          variable: 'ambient_humidity_pct',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.dryingHighAmbHumidityPct,
        ),
        RuleCondition(
          variable: 'current_humidity_pct',
          operator: ConditionOperator.gt,
          threshold: 12.0,
        ),
      ],
      outcome: RuleOutcome(
        action: 'MONITOR_MOLD_RISK',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.80,
        explanationByRole: {
          'farmer':    '⚠️ La humedad del ambiente está alta ({ambient_humidity_pct} %). Vigile el café para que no aparezcan hongos.',
          'processor': '⚠️ HR ambiente {ambient_humidity_pct} % > ${CoffeeThresholds.dryingHighAmbHumidityPct} %: el café ({current_humidity_pct} % humedad) está en zona de riesgo de hongos. Aumentar ventilación y volteos.',
          'barista':   '⚠️ HR {ambient_humidity_pct} %: condiciones favorables para Aspergillus y Penicillium. Granos con > 12 % humedad son vulnerables. Riesgo de defectos fúngicos en taza.',
        },
        suggestedActions: [
          'Aumentar la ventilación en el área de secado',
          'Intensificar los volteos (mínimo cada 2 h)',
          'Cubrir el café durante la noche o si hay lluvias',
        ],
        parameters: {
          'high_humidity_pct': CoffeeThresholds.dryingHighAmbHumidityPct,
        },
      ),
    ),

    AIRule(
      id: 'DRY-CRITICAL-AMBIENT-HUMIDITY-001',
      module: 'drying',
      name: 'Humedad relativa crítica — proteger café de forma urgente',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['drying', 'humidity', 'mold', 'critical'],
      supersedes: 'DRY-HIGH-AMBIENT-HUMIDITY-001',
      conditions: [
        RuleCondition(
          variable: 'ambient_humidity_pct',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.dryingCritAmbHumidityPct,
        ),
        RuleCondition(
          variable: 'drying_day_number',
          operator: ConditionOperator.gte,
          threshold: CoffeeThresholds.dryingTurningStartDay,
        ),
      ],
      outcome: RuleOutcome(
        action: 'SHELTER_COFFEE_IMMEDIATELY',
        alertLevel: AlertLevel.high,
        confidenceBase: 0.88,
        explanationByRole: {
          'farmer':    '🔴 La humedad del ambiente es muy alta ({ambient_humidity_pct} %). Lleve el café bajo techo ahora.',
          'processor': '🔴 HR ambiente {ambient_humidity_pct} % > ${CoffeeThresholds.dryingCritAmbHumidityPct} % en día {drying_day_number}: riesgo crítico de hongos. Retirar de la cama de secado inmediatamente.',
          'barista':   '🔴 HR {ambient_humidity_pct} % en día {drying_day_number}: condiciones críticas para contaminación fúngica. Almacenaje provisional en ambiente cerrado hasta que la HR baje.',
        },
        suggestedActions: [
          'Retirar el café de las camas de secado inmediatamente',
          'Almacenar temporalmente en bodega ventilada (< 70 % HR)',
          'Retomar el secado cuando la HR ambiente baje de ${CoffeeThresholds.dryingHighAmbHumidityPct} %',
        ],
        parameters: {
          'critical_humidity_pct': CoffeeThresholds.dryingCritAmbHumidityPct,
        },
      ),
    ),

    // ── VOLTEO ────────────────────────────────────────────────────────────────
    // D-14: día 3 y humedad 40 % son estimaciones — calibrar con Cenicafé.

    AIRule(
      id: 'DRY-TURNING-REMINDER-001',
      module: 'drying',
      name: 'Recordatorio de volteo — grano aún húmedo y varios días de secado',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['drying', 'turning', 'info'],
      conditions: [
        RuleCondition(
          variable: 'drying_day_number',
          operator: ConditionOperator.gte,
          threshold: CoffeeThresholds.dryingTurningStartDay,
        ),
        RuleCondition(
          variable: 'current_humidity_pct',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.dryingTurningMinGrainHum,
        ),
      ],
      outcome: RuleOutcome(
        action: 'INCREASE_TURNING_FREQUENCY',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.76,
        explanationByRole: {
          'farmer':    'ℹ️ Día {drying_day_number} de secado, humedad {current_humidity_pct} %. Voltee el café al menos 4 veces hoy para un secado uniforme.',
          'processor': 'ℹ️ Día {drying_day_number}: {current_humidity_pct} % humedad — etapa activa de pérdida de agua. Volteos frecuentes (mínimo cada 2–3 h) previenen costras superficiales y secado desigual.',
          'barista':   'ℹ️ Día {drying_day_number}, {current_humidity_pct} % humedad: capa externa puede secarse antes que el interior sin volteos frecuentes → gradiente de humedad → defectos de moteado en taza.',
        },
        suggestedActions: [
          'Voltear el café cada 2 horas durante las horas de mayor temperatura',
          'Verificar que la cama no esté compactada',
          'Registrar la humedad al finalizar el día',
        ],
        parameters: {
          'turning_start_day': CoffeeThresholds.dryingTurningStartDay,
          'turning_min_humidity': CoffeeThresholds.dryingTurningMinGrainHum,
        },
      ),
    ),
  ];
}
