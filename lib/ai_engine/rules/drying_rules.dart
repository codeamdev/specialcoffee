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
      name: 'Temperatura ambiente crítica — riesgo de agrietamiento (patio/camas)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['drying', 'temperature', 'warning'],
      conditions: [
        RuleCondition(
          variable: 'ambient_temp_c',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.dryingHeatStressTempC,
        ),
        // Excluye secado mecánico — su umbral de temperatura es distinto (ver DRY-MECH-TEMP-*)
        RuleCondition(
          variable: 'drying_method',
          operator: ConditionOperator.neq,
          threshold: 'mecanico',
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

    // ── SECADO MECÁNICO — TEMPERATURA ────────────────────────────────────────
    // Fuente: Manual del Cafetero FNC/Cenicafé 9ª ed. — cap. Secado Mecánico.
    // DRY-MECH-TEMP-CRIT-001 supersede al warning cuando T > 45°C.

    AIRule(
      id: 'DRY-MECH-TEMP-WARN-001',
      module: 'drying',
      name: 'Temperatura secador mecánico alta — riesgo de grano cristalizado',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['drying', 'mecanico', 'temperature', 'warning'],
      conditions: [
        RuleCondition(variable: 'drying_method', operator: ConditionOperator.eq, threshold: 'mecanico'),
        RuleCondition(
          variable: 'ambient_temp_c',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.dryingMechWarnTempC,
        ),
      ],
      outcome: RuleOutcome(
        action: 'REDUCE_DRYER_TEMPERATURE',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.85,
        explanationByRole: {
          'farmer':    '⚠️ El secador está a {ambient_temp_c} °C. Baje la temperatura — más de 40 °C empieza a dañar el grano.',
          'processor': '⚠️ Temperatura del aire secante {ambient_temp_c} °C > 40 °C: inicio de gradiente de humedad severo. Reducir a 35–40 °C para preservar estructura del endospermo.',
          'barista':   '⚠️ Secado mecánico a {ambient_temp_c} °C: temperatura alta puede generar micro-fisuras internas → pérdida de densidad y extracción desigual en taza.',
        },
        suggestedActions: [
          'Reducir la temperatura del aire secante a 35–40 °C',
          'Aumentar la ventilación para disipar el calor',
          'Medir la temperatura en el interior de la masa de grano, no solo en el aire de entrada',
        ],
        parameters: {'warn_temp_c': CoffeeThresholds.dryingMechWarnTempC},
      ),
    ),

    AIRule(
      id: 'DRY-MECH-TEMP-CRIT-001',
      module: 'drying',
      name: 'Temperatura secador mecánico crítica — grano cristalizado inminente',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['drying', 'mecanico', 'temperature', 'critical'],
      supersedes: 'DRY-MECH-TEMP-WARN-001',
      conditions: [
        RuleCondition(variable: 'drying_method', operator: ConditionOperator.eq, threshold: 'mecanico'),
        RuleCondition(
          variable: 'ambient_temp_c',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.dryingMechCritTempC,
        ),
      ],
      outcome: RuleOutcome(
        action: 'STOP_DRYER_OVERHEAT',
        alertLevel: AlertLevel.high,
        confidenceBase: 0.92,
        explanationByRole: {
          'farmer':    '🔴 ¡El secador está demasiado caliente! ({ambient_temp_c} °C). Apáguelo o baje la llama — puede perder todo el lote.',
          'processor': '🔴 Temperatura del aire {ambient_temp_c} °C supera el máximo de 45 °C (Cenicafé). Riesgo inmediato de "grano cristalizado": fisuras internas, pérdida de peso por fragmentación y bajo rendimiento en trilla. Detener el secador.',
          'barista':   '🔴 {ambient_temp_c} °C en secador mecánico: las fisuras internas por calor excesivo causan extracción caótica — puntas quemadas, amargor y pérdida total de complejidad aromática.',
        },
        suggestedActions: [
          'Detener el secador inmediatamente',
          'Abrir compuertas de ventilación para enfriar la masa de grano',
          'No superar 45 °C en ningún momento (Cenicafé)',
          'Operar en rango 35–40 °C para preservar calidad SCA',
        ],
        parameters: {'crit_temp_c': CoffeeThresholds.dryingMechCritTempC},
      ),
    ),

    // ── SECADO MECÁNICO — PROGRESO LENTO ─────────────────────────────────────
    // D-15: umbral de 5 días estimado — un secador bien calibrado alcanza < 30%
    // en 3–4 días. Más de 5 días en > 30% indica temperatura baja o sobrecarga.

    AIRule(
      id: 'DRY-MECH-SLOW-001',
      module: 'drying',
      name: 'Secado mecánico lento — posible temperatura baja o sobrecarga',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['drying', 'mecanico', 'warning', 'progress'],
      conditions: [
        RuleCondition(variable: 'drying_method', operator: ConditionOperator.eq, threshold: 'mecanico'),
        RuleCondition(variable: 'drying_day_number', operator: ConditionOperator.gte, threshold: CoffeeThresholds.dryingMechSlowDay),
        RuleCondition(variable: 'current_humidity_pct', operator: ConditionOperator.gt, threshold: 30.0),
      ],
      outcome: RuleOutcome(
        action: 'OPTIMIZE_MECHANICAL_DRYER',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.79,
        explanationByRole: {
          'farmer':    '⚠️ Día {drying_day_number} en secador y el café está en {current_humidity_pct}%. Revise si el secador está muy lleno o si la temperatura es muy baja.',
          'processor': '⚠️ Día {drying_day_number} en secado mecánico: {current_humidity_pct}% humedad — por debajo de la curva esperada para mecánico (< 30% a partir del día 4). Revisar caudal de aire, temperatura y carga del tambor.',
          'barista':   '⚠️ Secado mecánico lento en día {drying_day_number}: mayor tiempo de exposición al calor puede oxidar compuestos aromáticos frágiles del grano verde.',
        },
        suggestedActions: [
          'Verificar que la temperatura del aire esté entre 35 y 40 °C',
          'Reducir la carga del secador al 70–80% de su capacidad',
          'Revisar el caudal de aire (m³/h) — flujo insuficiente frena el secado',
          'Considerar pre-escurrido del grano si llega con > 55% de humedad',
        ],
        parameters: {'mech_slow_day': CoffeeThresholds.dryingMechSlowDay},
      ),
    ),

    // ── CAMAS AFRICANAS — PROGRESO LENTO ─────────────────────────────────────
    // D-15: camas africanas bien gestionadas en Colombia: < 15% a los 18 días.
    // Más tiempo indica problema de densidad, cobertura nocturna o HR elevada.

    AIRule(
      id: 'DRY-CAMAS-SLOW-001',
      module: 'drying',
      name: 'Camas africanas: secado lento — revisar densidad y cobertura',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['drying', 'camas_africanas', 'warning', 'progress'],
      conditions: [
        RuleCondition(variable: 'drying_method', operator: ConditionOperator.eq, threshold: 'camas_africanas'),
        RuleCondition(variable: 'drying_day_number', operator: ConditionOperator.gte, threshold: CoffeeThresholds.dryingCamasSlowDay),
        RuleCondition(variable: 'current_humidity_pct', operator: ConditionOperator.gt, threshold: 15.0),
      ],
      outcome: RuleOutcome(
        action: 'REVIEW_RAISED_BED_CONDITIONS',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.77,
        explanationByRole: {
          'farmer':    '⚠️ Día {drying_day_number} en cama africana y el café tiene {current_humidity_pct}%. Revise que la capa no esté muy gruesa y que tape bien de noche.',
          'processor': '⚠️ Día {drying_day_number} en camas africanas: {current_humidity_pct}% — para condiciones colombianas estándar se espera < 15% antes del día 18. Revisar densidad de la capa (máx. 3–5 cm), cobertura nocturna y frecuencia de volteos.',
          'barista':   '⚠️ Secado lento en camas africanas (día {drying_day_number}, {current_humidity_pct}%): mayor exposición temporal puede favorecer conversiones enzimáticas no deseadas y cambio en el perfil de acidez del lote.',
        },
        suggestedActions: [
          'Reducir la capa a máximo 3–4 cm de espesor',
          'Aumentar volteos a cada 1–2 horas en horario de mayor temperatura',
          'Verificar que la malla de las camas no esté obstruida',
          'Cubrir completamente durante la noche para evitar reabsorción de humedad',
        ],
        parameters: {'camas_slow_day': CoffeeThresholds.dryingCamasSlowDay},
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
