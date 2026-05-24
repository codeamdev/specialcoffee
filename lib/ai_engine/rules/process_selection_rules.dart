import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class ProcessSelectionRules {
  static List<AIRule> get all => [
    // ── LAVADO ─────────────────────────────────────────────────────────────────
    const AIRule(
      id: 'PROC-LAVADO-HIGH-ALT-001',
      module: 'process_selection',
      name: 'Lavado para altitudes medias-altas con temperatura fresca',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['process', 'lavado', 'altitude'],
      conditions: [
        RuleCondition(variable: 'altitude_masl', operator: ConditionOperator.between, threshold: 1400, thresholdMax: 2200),
        RuleCondition(variable: 'ambient_temp_c', operator: ConditionOperator.between, threshold: 15.0, thresholdMax: 24.0),
        RuleCondition(variable: 'variety_sensitivity', operator: ConditionOperator.inList, threshold: ['low', 'medium', 'high']),
      ],
      outcome: RuleOutcome(
        action: 'SELECT_PROCESS_LAVADO',
        alertLevel: AlertLevel.none,
        confidenceBase: 0.88,
        explanationByRole: {
          'farmer': 'Para su variedad y altura, el proceso lavado da café limpio y con buena acidez.',
          'processor': 'Altitud {altitude_masl} msnm + {ambient_temp_c}°C: condiciones óptimas para lavado. Fermentación estimada 20–28h.',
          'barista': 'Proceso lavado recomendado. Perfil esperado: acidez brillante, dulzor medio, alta limpieza en taza.',
        },
        suggestedActions: ['Iniciar proceso lavado', 'Preparar tanque de fermentación'],
        parameters: {
          'estimated_fermentation_min_h': 20,
          'estimated_fermentation_max_h': 28,
          'expected_sca_range': [82, 87],
          'flavor_profile': ['acidez_citrica', 'dulzor_panela', 'cuerpo_medio'],
        },
      ),
    ),

    // ── ANAERÓBICO ────────────────────────────────────────────────────────────
    const AIRule(
      id: 'PROC-ANAEROBIC-GEISHA-001',
      module: 'process_selection',
      name: 'Anaeróbico para variedades de alta complejidad en alturas > 1800',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['process', 'anaerobic', 'specialty'],
      conditions: [
        RuleCondition(variable: 'altitude_masl', operator: ConditionOperator.gte, threshold: 1800),
        RuleCondition(variable: 'ambient_temp_c', operator: ConditionOperator.lte, threshold: 21.0),
        RuleCondition(variable: 'variety_sensitivity', operator: ConditionOperator.inList, threshold: ['high', 'very_high']),
        RuleCondition(variable: 'variety_sca_potential', operator: ConditionOperator.gte, threshold: 86.0),
      ],
      outcome: RuleOutcome(
        action: 'SELECT_PROCESS_ANAEROBIC',
        alertLevel: AlertLevel.none,
        confidenceBase: 0.84,
        explanationByRole: {
          'farmer': 'Con su café y la temperatura fresca, el proceso anaeróbico puede dar un café muy especial y con mejor precio.',
          'processor': 'Variedad de alta complejidad ({variety_id}) a {altitude_masl} msnm y {ambient_temp_c}°C: anaeróbico láctico recomendado. Fermentación 48–72h en tanque sellado.',
          'barista': 'Anaeróbico recomendado. Perfil esperado: frutas tropicales, complejidad aromática alta, acidez láctico-suave. SCA potencial: {variety_sca_potential} pts.',
        },
        suggestedActions: [
          'Usar tanque sellado con válvula de CO₂',
          'Fermentación 48–72h según pH',
          'Monitorear cada 6 horas (proceso más lento)',
        ],
        parameters: {
          'estimated_fermentation_min_h': 48,
          'estimated_fermentation_max_h': 72,
          'tank_type': 'sealed_anaerobic',
          'monitoring_freq_h': 6,
          'expected_sca_range': [86, 92],
          'flavor_profile': ['tropical', 'lactico', 'floral', 'vino'],
        },
      ),
    ),

    // ── NATURAL ───────────────────────────────────────────────────────────────
    const AIRule(
      id: 'PROC-NATURAL-DRY-CONDITIONS-001',
      module: 'process_selection',
      name: 'Natural para condiciones secas y alturas medias',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['process', 'natural', 'weather'],
      conditions: [
        RuleCondition(variable: 'ambient_humidity_pct', operator: ConditionOperator.lte, threshold: 70.0),
        RuleCondition(variable: 'rain_probability_pct', operator: ConditionOperator.lte, threshold: 20.0),
        RuleCondition(variable: 'altitude_masl', operator: ConditionOperator.between, threshold: 1200, thresholdMax: 1800),
      ],
      outcome: RuleOutcome(
        action: 'SELECT_PROCESS_NATURAL',
        alertLevel: AlertLevel.none,
        confidenceBase: 0.78,
        explanationByRole: {
          'farmer': 'Las condiciones climáticas favorecen el proceso natural. El café en cereza se seca directamente — da sabores más dulces y con cuerpo.',
          'processor': 'Humedad {ambient_humidity_pct}%, sin lluvia prevista. Natural viable. Requiere secado 21–30 días con volteos frecuentes.',
          'barista': 'Natural recomendado. Perfil: frutas rojas maduras, dulzor alto, cuerpo denso. Mayor variabilidad entre lotes.',
        },
        suggestedActions: [
          'Extender cerezas en camas africanas o patio elevado',
          'Voltear mínimo 4 veces al día los primeros 10 días',
          'Cubrir en las noches si humedad relativa > 80%',
        ],
        parameters: {
          'estimated_drying_min_days': 21,
          'estimated_drying_max_days': 30,
          'expected_sca_range': [80, 85],
          'flavor_profile': ['frutas_rojas', 'chocolate', 'cuerpo_alto'],
        },
      ),
    ),
  ];
}
