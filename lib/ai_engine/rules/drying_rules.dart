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
  ];
}
