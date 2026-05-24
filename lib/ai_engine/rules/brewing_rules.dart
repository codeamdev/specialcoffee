import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class BrewingRules {
  static List<AIRule> get all => [..._recipeRules, ..._diagnosisRules];

  // ── AJUSTES DE RECETA ─────────────────────────────────────────────────────
  static const List<AIRule> _recipeRules = [
    AIRule(
      id: 'BREW-TEMP-ALTITUDE-001',
      module: 'brewing',
      name: 'Ajuste de temperatura por altitud',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['temperature', 'altitude', 'recipe'],
      conditions: [
        RuleCondition(variable: 'altitude_masl', operator: ConditionOperator.gte, threshold: 2200),
      ],
      outcome: RuleOutcome(
        action: 'ADJUST_BREW_TEMP_DOWN',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.95,
        explanationByRole: {
          'farmer': 'El agua hierve más frío en lugares altos.',
          'processor': 'A {altitude_masl} msnm el punto de ebullición es ~{boiling_point}°C. Ajustar temperatura base.',
          'barista': 'A {altitude_masl} msnm: ebullición a {boiling_point}°C. Temperatura objetivo ajustada -2°C respecto al estándar.',
        },
        parameters: {'temp_adjustment_c': -2.0, 'reason': 'altitude_boiling_point_reduction'},
      ),
    ),

    AIRule(
      id: 'BREW-BLOOM-FRESH-ROAST-001',
      module: 'brewing',
      name: 'Bloom extendido para café recién tostado',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['bloom', 'roast', 'recipe'],
      conditions: [
        RuleCondition(variable: 'roast_days', operator: ConditionOperator.lte, threshold: 14),
        RuleCondition(variable: 'brew_method', operator: ConditionOperator.inList, threshold: ['v60', 'chemex', 'aeropress']),
      ],
      outcome: RuleOutcome(
        action: 'EXTEND_BLOOM',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.88,
        explanationByRole: {
          'farmer': 'El café es recién tostado — necesita más tiempo al inicio para desgasificar.',
          'processor': 'Café con {roast_days} días de tueste: alto CO₂ residual. Bloom extendido evita extracción irregular.',
          'barista': '{roast_days} días de tueste: degassing activo. Bloom total {bloom_seconds}s con 3× la dosis de agua.',
        },
        parameters: {'bloom_extension_seconds': 15, 'bloom_water_ratio': 3.0},
      ),
    ),

    AIRule(
      id: 'BREW-RATIO-SWEETNESS-PROFILE-001',
      module: 'brewing',
      name: 'Ratio más concentrado para perfiles con preferencia de dulzor',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['ratio', 'profile', 'sweetness'],
      conditions: [
        RuleCondition(variable: 'user_sweetness_weight', operator: ConditionOperator.gte, threshold: 0.7),
        RuleCondition(variable: 'brew_method', operator: ConditionOperator.inList, threshold: ['v60', 'chemex', 'aeropress']),
      ],
      outcome: RuleOutcome(
        action: 'ADJUST_RATIO_CONCENTRATED',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.79,
        explanationByRole: {
          'farmer': 'Le gusta el café con más cuerpo y dulzor.',
          'processor': 'Perfil usuario: dulzor {user_sweetness_weight}. Ratio 1:15 favorece extractables de azúcar.',
          'barista': 'Tu preferencia de dulzor ({user_sweetness_weight}) sugiere ratio 1:15–1:15.5 vs el estándar 1:16.',
        },
        parameters: {'ratio_adjustment': 0.5, 'direction': 'more_concentrated'},
      ),
    ),

    AIRule(
      id: 'BREW-ESPRESSO-LIGHT-ROAST-001',
      module: 'brewing',
      name: 'Temperatura alta para espresso con tueste claro',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['temperature', 'espresso', 'light_roast'],
      conditions: [
        RuleCondition(variable: 'brew_method', operator: ConditionOperator.eq, threshold: 'espresso'),
        RuleCondition(variable: 'roast_level', operator: ConditionOperator.eq, threshold: 'light'),
      ],
      outcome: RuleOutcome(
        action: 'ADJUST_ESPRESSO_TEMP_UP',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.86,
        explanationByRole: {
          'farmer': 'Para espresso con café suave necesita más temperatura.',
          'processor': 'Tueste claro en espresso: temperatura 93–94°C para compensar menor desarrollo del grano.',
          'barista': 'Tueste claro en espresso: +1°C sobre base (93°C). Compensa menor caramelización y favorece extracción de ácidos suaves.',
        },
        parameters: {'temp_adjustment_c': 1.0, 'base_temp_c': 93.0},
      ),
    ),
  ];

  // ── DIAGNÓSTICO POST-EXTRACCIÓN ───────────────────────────────────────────
  static const List<AIRule> _diagnosisRules = [
    AIRule(
      id: 'BREW-DIAG-OVER-EXTRACTED-001',
      module: 'brewing',
      name: 'Sobreextracción detectada por TDS alto',
      priority: 2,
      logic: RuleLogic.or,
      tags: ['tds', 'extraction', 'diagnosis'],
      conditions: [
        RuleCondition(variable: 'measured_tds_pct', operator: ConditionOperator.gt, threshold: 1.55),
        RuleCondition(variable: 'measured_yield_pct', operator: ConditionOperator.gt, threshold: 23.0),
      ],
      outcome: RuleOutcome(
        action: 'DIAGNOSE_OVER_EXTRACTION',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.90,
        explanationByRole: {
          'farmer': 'El café salió muy cargado. Para la próxima, usa menos tiempo o molienda más gruesa.',
          'processor': 'TDS {measured_tds_pct}% / Rendimiento {measured_yield_pct}%: sobreextracción. Ajustar molienda (+1–2 clicks) o reducir tiempo.',
          'barista': 'TDS {measured_tds_pct}% supera objetivo ({user_preferred_tds_max}%). Sobreextracción: amargor, aspereza tardía. Ajuste principal: molienda más gruesa.',
        },
        suggestedActions: [
          'Molienda más gruesa: +1.5 clicks (mayor impacto)',
          'Reducir temperatura 1°C (impacto medio)',
          'Acelerar el vertido 10–15 segundos (menor impacto)',
        ],
        parameters: {
          'primary_adjustment': 'grind_coarser',
          'grind_adjustment_clicks': 1.5,
          'diagnosis': 'over_extraction',
        },
      ),
    ),

    AIRule(
      id: 'BREW-DIAG-UNDER-EXTRACTED-001',
      module: 'brewing',
      name: 'Subextracción detectada por TDS bajo',
      priority: 2,
      logic: RuleLogic.or,
      tags: ['tds', 'extraction', 'diagnosis'],
      conditions: [
        RuleCondition(variable: 'measured_tds_pct', operator: ConditionOperator.lt, threshold: 1.15),
        RuleCondition(variable: 'measured_yield_pct', operator: ConditionOperator.lt, threshold: 17.0),
      ],
      outcome: RuleOutcome(
        action: 'DIAGNOSE_UNDER_EXTRACTION',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.90,
        explanationByRole: {
          'farmer': 'El café salió aguado. Para la próxima, muele más fino o deja más tiempo.',
          'processor': 'TDS {measured_tds_pct}% / Rendimiento {measured_yield_pct}%: subextracción. Ajustar molienda (-1–2 clicks) o aumentar tiempo.',
          'barista': 'TDS {measured_tds_pct}% bajo objetivo ({user_preferred_tds_min}%). Subextracción: acidez aguda, dulzor bajo, cuerpo ligero.',
        },
        suggestedActions: [
          'Molienda más fina: -1.5 clicks (mayor impacto)',
          'Aumentar temperatura 1°C',
          'Ralentizar el vertido 10–15 segundos',
        ],
        parameters: {
          'primary_adjustment': 'grind_finer',
          'grind_adjustment_clicks': -1.5,
          'diagnosis': 'under_extraction',
        },
      ),
    ),

    AIRule(
      id: 'BREW-DIAG-OPTIMAL-001',
      module: 'brewing',
      name: 'Extracción en rango óptimo personal',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['tds', 'extraction', 'optimal'],
      conditions: [
        RuleCondition(variable: 'measured_tds_pct', operator: ConditionOperator.between, threshold: 1.15, thresholdMax: 1.45),
        RuleCondition(variable: 'measured_yield_pct', operator: ConditionOperator.between, threshold: 18.0, thresholdMax: 22.0),
      ],
      outcome: RuleOutcome(
        action: 'CONFIRM_OPTIMAL_EXTRACTION',
        alertLevel: AlertLevel.none,
        confidenceBase: 0.94,
        explanationByRole: {
          'farmer': '✅ La extracción salió perfecta. Guarde estos parámetros.',
          'processor': '✅ TDS {measured_tds_pct}%, Rendimiento {measured_yield_pct}% — dentro del rango SCA ideal.',
          'barista': '✅ TDS {measured_tds_pct}% y rendimiento {measured_yield_pct}% — extracción óptima. Guardar como receta referencia.',
        },
        suggestedActions: ['Guardar como receta base para este café'],
        parameters: {'session_quality': 'optimal'},
      ),
    ),
  ];
}
