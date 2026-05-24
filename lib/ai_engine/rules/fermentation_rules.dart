import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class FermentationRules {
  static List<AIRule> get all => [..._alertRules, ..._guidanceRules, ..._projectionRules];

  // ── ALERTAS (prioridad 1–2) ───────────────────────────────────────────────
  static const List<AIRule> _alertRules = [
    AIRule(
      id: 'FERM-PH-CRITICAL-LAVADO-001',
      module: 'fermentation',
      name: 'pH crítico en fermentación lavado',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['ph', 'critical', 'lavado'],
      conditions: [
        RuleCondition(variable: 'current_ph', operator: ConditionOperator.lt, threshold: 3.5),
        RuleCondition(variable: 'process_type', operator: ConditionOperator.eq, threshold: 'lavado'),
        RuleCondition(variable: 'fermentation_status', operator: ConditionOperator.eq, threshold: 'active'),
      ],
      outcome: RuleOutcome(
        action: 'STOP_FERMENTATION_IMMEDIATELY',
        alertLevel: AlertLevel.critical,
        confidenceBase: 0.97,
        explanationByRole: {
          'farmer': '🔴 DETENGA LA FERMENTACIÓN AHORA. El café tiene demasiada acidez y va a quedar con sabor a vinagre. Llévelo al canal de lavado con agua limpia.',
          'processor': '🔴 CRÍTICO: pH {current_ph} en lavado. Sobrefermentación activa. Defecto acético inminente. Acción en < 1 hora.',
          'barista': '🔴 pH {current_ph} — actividad bacteriana acética activa. Lote en riesgo de defecto vinagre irreversible.',
        },
        suggestedActions: [
          'Detener fermentación inmediatamente',
          'Drenar el tanque y lavar el café con agua limpia',
          'Extender en camas de secado lo antes posible',
          'Registrar el incidente para el reporte del lote',
        ],
        parameters: {
          'urgency_hours': 1,
          'requires_confirmation_to_dismiss': true,
          'vibration_pattern': 'critical',
        },
      ),
    ),

    AIRule(
      id: 'FERM-TEMP-CRITICAL-001',
      module: 'fermentation',
      name: 'Temperatura de mucílago crítica',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['temperature', 'critical', 'fermentation'],
      conditions: [
        RuleCondition(variable: 'mucilago_temp_c', operator: ConditionOperator.gt, threshold: 30.0),
        RuleCondition(variable: 'fermentation_status', operator: ConditionOperator.eq, threshold: 'active'),
      ],
      outcome: RuleOutcome(
        action: 'COOL_TANK_URGENTLY',
        alertLevel: AlertLevel.critical,
        confidenceBase: 0.96,
        explanationByRole: {
          'farmer': '🔴 El tanque está muy caliente ({mucilago_temp_c}°C). Enfríelo ahora antes de que el café se dañe.',
          'processor': '🔴 Mucílago a {mucilago_temp_c}°C. Proliferación bacteriana acelerada. Intervenir en < 2h.',
          'barista': '🔴 Temperatura crítica: {mucilago_temp_c}°C. El estrés térmico puede producir defectos de fermento y reducir puntaje SCA 4–8 pts.',
        },
        suggestedActions: [
          'Aplicar agua fría en el exterior del tanque',
          'Cubrir el tanque con yute húmedo para aislamiento',
          'Mover el tanque a sombra si es posible',
          'Tomar lectura de temperatura en 30 minutos',
        ],
        parameters: {'urgency_hours': 2, 'recheck_minutes': 30},
      ),
    ),

    AIRule(
      id: 'FERM-PH-HIGH-LAVADO-001',
      module: 'fermentation',
      name: 'pH en zona de alerta alta en lavado',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['ph', 'warning', 'lavado'],
      conditions: [
        RuleCondition(variable: 'current_ph', operator: ConditionOperator.between, threshold: 3.5, thresholdMax: 4.0),
        RuleCondition(variable: 'process_type', operator: ConditionOperator.eq, threshold: 'lavado'),
        RuleCondition(variable: 'fermentation_status', operator: ConditionOperator.eq, threshold: 'active'),
      ],
      outcome: RuleOutcome(
        action: 'MONITOR_CLOSELY',
        alertLevel: AlertLevel.high,
        confidenceBase: 0.91,
        explanationByRole: {
          'farmer': '⚠️ El café está llegando a su punto. Revise cada hora y esté listo para pararlo.',
          'processor': '⚠️ pH {current_ph} en zona límite. Punto de detención (4.0–4.5) próximo. Monitoreo cada hora.',
          'barista': '⚠️ pH {current_ph} — zona de transición. Detener en 4.0–4.2 para perfil limpio; extender a 3.8–4.0 para mayor complejidad.',
        },
        suggestedActions: [
          'Registrar próxima lectura en 1 hora',
          'Preparar el canal de lavado con agua limpia',
        ],
        parameters: {'next_reading_hours': 1},
      ),
    ),

    AIRule(
      id: 'FERM-TEMP-HIGH-001',
      module: 'fermentation',
      name: 'Temperatura de mucílago elevada',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['temperature', 'warning', 'fermentation'],
      conditions: [
        RuleCondition(variable: 'mucilago_temp_c', operator: ConditionOperator.between, threshold: 27.0, thresholdMax: 30.0),
        RuleCondition(variable: 'fermentation_status', operator: ConditionOperator.eq, threshold: 'active'),
      ],
      outcome: RuleOutcome(
        action: 'REDUCE_TEMPERATURE',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.87,
        explanationByRole: {
          'farmer': '⚠️ El mucílago está un poco caliente ({mucilago_temp_c}°C). Si sube 3°C más, el café se puede dañar.',
          'processor': '⚠️ Mucílago {mucilago_temp_c}°C — por encima del rango ideal (18–25°C). Aplicar medidas preventivas.',
          'barista': '⚠️ Estrés térmico moderado. Si persiste puede acortar el perfil aromático y aumentar amargor.',
        },
        suggestedActions: [
          'Cubrir el tanque con yute húmedo',
          'Verificar si hay exposición solar directa',
          'Tomar lectura de temperatura en 2 horas',
        ],
        parameters: {'recheck_hours': 2},
      ),
    ),
  ];

  // ── ORIENTACIÓN (prioridad 3) ─────────────────────────────────────────────
  static const List<AIRule> _guidanceRules = [
    AIRule(
      id: 'FERM-MUCILAGE-DRY-LAVADO-001',
      module: 'fermentation',
      name: 'Señal de finalización por estado de mucílago',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['mucilage', 'endpoint', 'lavado'],
      conditions: [
        RuleCondition(variable: 'mucilage_state', operator: ConditionOperator.eq, threshold: 'dry'),
        RuleCondition(variable: 'current_ph', operator: ConditionOperator.between, threshold: 3.8, thresholdMax: 4.8),
        RuleCondition(variable: 'process_type', operator: ConditionOperator.eq, threshold: 'lavado'),
      ],
      outcome: RuleOutcome(
        action: 'STOP_FERMENTATION_OPTIMAL',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.89,
        explanationByRole: {
          'farmer': '✅ El mucílago está seco al tacto y el pH está bien. Es el momento de lavar el café.',
          'processor': '✅ Endpoint de fermentación: mucílago seco + pH {current_ph}. Iniciar lavado ahora.',
          'barista': '✅ Señal de finalización ideal: mucílago seco + pH {current_ph} (dentro de rango). Calidad preservada.',
        },
        suggestedActions: [
          'Drenar el tanque e iniciar lavado con agua limpia',
          'Lavar 2–3 veces hasta que el agua salga clara',
          'Registrar duración total de la fermentación',
        ],
        parameters: {'wash_repetitions': 3},
      ),
    ),
  ];

  // ── PROYECCIONES (prioridad 4) ────────────────────────────────────────────
  static const List<AIRule> _projectionRules = [
    AIRule(
      id: 'FERM-PROJ-SLOW-001',
      module: 'fermentation',
      name: 'Fermentación lenta — proyección extendida',
      priority: 4,
      logic: RuleLogic.and,
      tags: ['projection', 'slow', 'fermentation'],
      conditions: [
        RuleCondition(variable: 'fermentation_hours_elapsed', operator: ConditionOperator.gt, threshold: 24.0),
        RuleCondition(variable: 'current_ph', operator: ConditionOperator.gt, threshold: 5.0),
        RuleCondition(variable: 'ambient_temp_c', operator: ConditionOperator.lt, threshold: 18.0),
      ],
      outcome: RuleOutcome(
        action: 'NOTIFY_SLOW_FERMENTATION',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.80,
        explanationByRole: {
          'farmer': 'La fermentación va despacio por el frío ({ambient_temp_c}°C). Es normal — puede tardar hasta 36 horas más.',
          'processor': 'Fermentación lenta: {fermentation_hours_elapsed}h transcurridas, pH aún en {current_ph}. Temperatura {ambient_temp_c}°C está retrasando el proceso. Proyección: 12–18h adicionales.',
          'barista': 'Fermentación lenta por temperatura baja ({ambient_temp_c}°C). Esto puede resultar en perfiles más complejos y acidez más estructurada.',
        },
        suggestedActions: [
          'Continuar el proceso — es normal en condiciones de frío',
          'Si no tiene tanque techado, considerar cubrir para retener calor',
          'Próxima lectura en 4 horas',
        ],
        parameters: {'additional_hours_estimate': 15, 'next_reading_hours': 4},
      ),
    ),
  ];
}
