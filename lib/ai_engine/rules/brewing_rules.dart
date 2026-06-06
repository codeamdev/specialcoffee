import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class BrewingRules {
  static List<AIRule> get all => [
        ..._recipeRules,
        ..._diagnosisRules,
        ..._freshnessRules,
        ..._ratioRules,
        ..._extractionRules,
        ..._waterRules,
      ];

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
      id: 'BREW-COLDBREW-STEEP-001',
      module: 'brewing',
      name: 'Control de tiempo de maceración Cold Brew',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['cold_brew', 'steep_time', 'recipe'],
      conditions: [
        RuleCondition(variable: 'brew_method', operator: ConditionOperator.eq, threshold: 'cold_brew'),
      ],
      outcome: RuleOutcome(
        action: 'GUIDE_COLDBREW_STEEP',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.92,
        explanationByRole: {
          'farmer': 'Cold Brew necesita entre 12 y 24 horas en nevera para sacar lo mejor del café.',
          'processor': 'Maceración en frío: 16h óptimo (rango 12–24h), temperatura 4°C. TDS objetivo concentrado: 2.5–3.5%. Diluir 1:1 para servir.',
          'barista': 'Cold Brew concentrado (1:8): macerar 16h a 4°C (rango 12–24h). TDS concentrado 2.5–3.5%. No calentar — extracción lenta elimina acidez y amargor.',
        },
        parameters: {
          'steep_hours_optimal': 16,
          'steep_hours_min': 12,
          'steep_hours_max': 24,
          'temp_c': 4,
          'tds_min_pct': 2.5,
          'tds_max_pct': 3.5,
          'dilution_ratio': 1.0,
        },
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

  // ── FRESCURA DEL TUESTE ───────────────────────────────────────────────────
  // Fuente: SCA Brewing Standards 2019. roastDays 0.0 = no registrado → between
  // 0.1–X para evitar falsos positivos con el default.
  static const List<AIRule> _freshnessRules = [
    AIRule(
      id: 'BREW-FRESH-FILTER-001',
      module: 'brewing',
      name: 'Reposo insuficiente para filtro — café recién tostado',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['freshness', 'filter', 'recipe'],
      conditions: [
        RuleCondition(
          variable: 'roast_days',
          operator: ConditionOperator.between,
          threshold: 0.1,
          thresholdMax: CoffeeThresholds.roastDaysVeryFreshFilter - 0.01,
        ),
        RuleCondition(
          variable: 'brew_method',
          operator: ConditionOperator.inList,
          threshold: ['v60', 'chemex', 'aeropress', 'french_press'],
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARN_FRESH_ROAST_FILTER',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.85,
        explanationByRole: {
          'farmer': 'El café es muy nuevo. Déjelo reposar unos días para que salga mejor.',
          'processor': 'Café con {roast_days} días de tueste aún no ha desgasificado. El CO₂ residual genera extracción desigual en filtro.',
          'barista': '{roast_days} días de tueste: CO₂ activo interfiere con la extracción. Reposo recomendado ≥ ${CoffeeThresholds.roastDaysVeryFreshFilter} días para métodos de filtro.',
        },
        suggestedActions: [
          'Esperar hasta ${CoffeeThresholds.roastDaysVeryFreshFilter} días post-tueste',
          'Si debe preparar ahora: bloom prolongado (45–60s) con temperatura 2°C más alta',
        ],
        parameters: {
          'rest_days_recommended': CoffeeThresholds.roastDaysVeryFreshFilter,
          'reason': 'co2_degassing_incomplete',
        },
      ),
    ),

    AIRule(
      id: 'BREW-FRESH-ESPRESSO-001',
      module: 'brewing',
      name: 'Reposo insuficiente para espresso',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['freshness', 'espresso', 'recipe'],
      conditions: [
        RuleCondition(
          variable: 'roast_days',
          operator: ConditionOperator.between,
          threshold: 0.1,
          thresholdMax: CoffeeThresholds.roastDaysFreshEspresso - 0.01,
        ),
        RuleCondition(
          variable: 'brew_method',
          operator: ConditionOperator.eq,
          threshold: 'espresso',
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARN_FRESH_ROAST_ESPRESSO',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.82,
        explanationByRole: {
          'farmer': 'El café es muy nuevo para espresso. Mejor esperar un poco.',
          'processor': 'Espresso con {roast_days} días: degassing puede generar canales en el puck y extracción irregular.',
          'barista': '{roast_days} días — el espresso mejora con ≥ ${CoffeeThresholds.roastDaysFreshEspresso} días de reposo. Si prepara ahora: molienda ligeramente más gruesa para compensar el CO₂.',
        },
        suggestedActions: [
          'Esperar hasta ${CoffeeThresholds.roastDaysFreshEspresso} días post-tueste',
          'Si debe preparar: ajustar molienda +0.5 clicks (más gruesa)',
        ],
        parameters: {
          'rest_days_recommended': CoffeeThresholds.roastDaysFreshEspresso,
          'reason': 'espresso_co2_channeling_risk',
        },
      ),
    ),

    AIRule(
      id: 'BREW-STALE-FILTER-001',
      module: 'brewing',
      name: 'Café oxidado para filtro',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['freshness', 'filter', 'stale'],
      conditions: [
        RuleCondition(
          variable: 'roast_days',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.roastDaysStaleFilter,
        ),
        RuleCondition(
          variable: 'brew_method',
          operator: ConditionOperator.inList,
          threshold: ['v60', 'chemex', 'aeropress', 'french_press'],
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARN_STALE_FILTER',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.80,
        explanationByRole: {
          'farmer': 'El café tiene más de ${CoffeeThresholds.roastDaysStaleFilter} días — ya perdió frescura.',
          'processor': '{roast_days} días post-tueste: oxidación significativa. Los aromáticos volátiles se han degradado. El café lucirá plano.',
          'barista': '{roast_days} días: superado el umbral de oxidación para filtro (${CoffeeThresholds.roastDaysStaleFilter}d). Molienda más fina y temperatura +1°C pueden compensar parcialmente.',
        },
        suggestedActions: [
          'Usar molienda más fina para compensar menor extracción',
          'Aumentar temperatura 1–2°C',
          'Considerar reemplazar el café si disponible',
        ],
        parameters: {
          'stale_threshold_days': CoffeeThresholds.roastDaysStaleFilter,
          'reason': 'oxidation_volatile_loss',
        },
      ),
    ),

    AIRule(
      id: 'BREW-STALE-ESPRESSO-001',
      module: 'brewing',
      name: 'Café oxidado para espresso',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['freshness', 'espresso', 'stale'],
      conditions: [
        RuleCondition(
          variable: 'roast_days',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.roastDaysStaleEspresso,
        ),
        RuleCondition(
          variable: 'brew_method',
          operator: ConditionOperator.eq,
          threshold: 'espresso',
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARN_STALE_ESPRESSO',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.78,
        explanationByRole: {
          'farmer': 'El café tiene más de ${CoffeeThresholds.roastDaysStaleEspresso} días para espresso.',
          'processor': '{roast_days} días: el espresso muestra mayor oxidación que el filtro por la presión. Crema reducida y sabor plano.',
          'barista': '{roast_days} días — espresso óptimo entre ${CoffeeThresholds.roastDaysFreshEspresso}–${CoffeeThresholds.roastDaysStaleEspresso}d. Ajustar molienda más fina y temperatura +1°C.',
        },
        suggestedActions: [
          'Molienda más fina: -0.5 clicks',
          'Temperatura +1°C sobre base',
        ],
        parameters: {
          'stale_threshold_days': CoffeeThresholds.roastDaysStaleEspresso,
          'reason': 'espresso_oxidation',
        },
      ),
    ),
  ];

  // ── RATIO POR NIVEL DE TUESTE ─────────────────────────────────────────────
  // Fuente: SCA Brewing Standards 2019 + BH Education (Barista Hustle).
  // Tueste claro → mayor densidad → extracción más lenta → ratio más abierto (menos café por agua).
  // Tueste oscuro → celulosa más frágil → extracción más rápida → ratio más cerrado.
  // AUDIT: rangos de ratio son guía — calibrar con datos de sesiones reales (D-16).
  static const List<AIRule> _ratioRules = [
    AIRule(
      id: 'BREW-RATIO-LIGHT-FILTER-001',
      module: 'brewing',
      name: 'Ratio recomendado para tueste claro en filtro',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['ratio', 'light_roast', 'filter'],
      conditions: [
        RuleCondition(variable: 'roast_level', operator: ConditionOperator.eq, threshold: 'light'),
        RuleCondition(
          variable: 'brew_method',
          operator: ConditionOperator.inList,
          threshold: ['v60', 'chemex', 'aeropress', 'french_press'],
        ),
      ],
      outcome: RuleOutcome(
        action: 'ADJUST_RATIO_LIGHT_FILTER',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.82,
        explanationByRole: {
          'farmer': 'Café suave necesita un poco menos de cantidad para que no salga aguado.',
          'processor': 'Tueste claro: densidad alta. Ratio 1:15.5–1:16.5 — más abierto que el estándar 1:15 para filtros.',
          'barista': 'Tueste claro: alta densidad y solubilidad moderada. Ratio recomendado 1:15.5–1:16.5 (SCA). Temperatura 92–93°C.',
        },
        parameters: {'ratio_min': 15.5, 'ratio_max': 16.5, 'reason': 'light_roast_density'},
      ),
    ),

    AIRule(
      id: 'BREW-RATIO-LIGHT-ESPRESSO-001',
      module: 'brewing',
      name: 'Ratio recomendado para tueste claro en espresso',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['ratio', 'light_roast', 'espresso'],
      conditions: [
        RuleCondition(variable: 'roast_level', operator: ConditionOperator.eq, threshold: 'light'),
        RuleCondition(variable: 'brew_method', operator: ConditionOperator.eq, threshold: 'espresso'),
      ],
      outcome: RuleOutcome(
        action: 'ADJUST_RATIO_LIGHT_ESPRESSO',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.83,
        explanationByRole: {
          'farmer': 'Espresso con café suave: usar un poco más de café para que salga con buen cuerpo.',
          'processor': 'Tueste claro en espresso: ratio 1:2–1:2.5. Alta temperatura (93–94°C) compensa la menor solubilidad.',
          'barista': 'Tueste claro: ratio 1:2–1:2.5 (más corto que dark). Preinfusión 4–6s. Temperatura 93°C+ para compensar densidad del grano.',
        },
        parameters: {'ratio_min': 2.0, 'ratio_max': 2.5, 'reason': 'light_espresso_density'},
      ),
    ),

    AIRule(
      id: 'BREW-RATIO-DARK-FILTER-001',
      module: 'brewing',
      name: 'Ratio recomendado para tueste oscuro en filtro',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['ratio', 'dark_roast', 'filter'],
      conditions: [
        RuleCondition(variable: 'roast_level', operator: ConditionOperator.eq, threshold: 'dark'),
        RuleCondition(
          variable: 'brew_method',
          operator: ConditionOperator.inList,
          threshold: ['v60', 'chemex', 'aeropress', 'french_press'],
        ),
      ],
      outcome: RuleOutcome(
        action: 'ADJUST_RATIO_DARK_FILTER',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.80,
        explanationByRole: {
          'farmer': 'Café oscuro extrae más rápido — usar un poco menos de agua para no sacar el amargor.',
          'processor': 'Tueste oscuro: estructura celular más frágil, mayor solubilidad. Ratio 1:14–1:15 evita sobreextracción de compuestos amargos.',
          'barista': 'Tueste oscuro: ratio 1:14–1:15. Temperatura 88–90°C — más baja que claro para no acentuar el amargor. Bloom breve (20–25s).',
        },
        parameters: {'ratio_min': 14.0, 'ratio_max': 15.0, 'reason': 'dark_roast_fragile_cell'},
      ),
    ),

    AIRule(
      id: 'BREW-RATIO-DARK-ESPRESSO-001',
      module: 'brewing',
      name: 'Ratio recomendado para tueste oscuro en espresso',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['ratio', 'dark_roast', 'espresso'],
      conditions: [
        RuleCondition(variable: 'roast_level', operator: ConditionOperator.eq, threshold: 'dark'),
        RuleCondition(variable: 'brew_method', operator: ConditionOperator.eq, threshold: 'espresso'),
      ],
      outcome: RuleOutcome(
        action: 'ADJUST_RATIO_DARK_ESPRESSO',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.81,
        explanationByRole: {
          'farmer': 'Espresso oscuro: usar un poco menos de agua para que no amargue.',
          'processor': 'Tueste oscuro en espresso: ratio 1:2.5–1:3. Temperatura más baja (90–91°C) para reducir extracción de amargos.',
          'barista': 'Tueste oscuro: ratio 1:2.5–1:3 (lungo-style si necesario). Temperatura 90–91°C. Molienda 0.5 clicks más gruesa que referencia.',
        },
        parameters: {'ratio_min': 2.5, 'ratio_max': 3.0, 'reason': 'dark_espresso_bitterness_control'},
      ),
    ),
  ];

  // ── EXTRACCIÓN MEJORADA (supersede versiones info) ────────────────────────
  // Estas reglas tienen alertLevel: warning y superseden las versiones info de
  // BREW-DIAG-UNDER/OVER-EXTRACTED-001. El ConflictResolver elimina las reglas
  // supersedidas (paso 1) antes de resolver por action (paso 2).
  // Usan between 0.1–X en lugar de lt/gt para evitar falsos positivos con TDS=0.0 default.
  static const List<AIRule> _extractionRules = [
    AIRule(
      id: 'BREW-SUB-EXT-001',
      module: 'brewing',
      name: 'Subextracción confirmada — advertencia de calidad',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['tds', 'extraction', 'diagnosis'],
      supersedes: 'BREW-DIAG-UNDER-EXTRACTED-001',
      conditions: [
        RuleCondition(
          variable: 'measured_tds_pct',
          operator: ConditionOperator.between,
          threshold: 0.1,
          thresholdMax: 1.14,
        ),
      ],
      outcome: RuleOutcome(
        action: 'DIAGNOSE_UNDER_EXTRACTION',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.92,
        explanationByRole: {
          'farmer': 'El café salió muy aguado. La próxima, muele más fino o deja más tiempo.',
          'processor': 'TDS {measured_tds_pct}%: subextracción confirmada (< 1.15%). Ajuste inmediato: molienda más fina.',
          'barista': 'TDS {measured_tds_pct}% — subextracción. Acidez aguda, sin dulzor, cuerpo ligero. Causa probable: molienda gruesa o temperatura baja.',
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
      id: 'BREW-OVER-EXT-001',
      module: 'brewing',
      name: 'Sobreextracción confirmada — advertencia de calidad',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['tds', 'extraction', 'diagnosis'],
      supersedes: 'BREW-DIAG-OVER-EXTRACTED-001',
      conditions: [
        RuleCondition(
          variable: 'measured_tds_pct',
          operator: ConditionOperator.between,
          threshold: 1.56,
          thresholdMax: 3.0,
        ),
      ],
      outcome: RuleOutcome(
        action: 'DIAGNOSE_OVER_EXTRACTION',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.92,
        explanationByRole: {
          'farmer': 'El café salió muy cargado y amargo. La próxima, muele más grueso o reduce el tiempo.',
          'processor': 'TDS {measured_tds_pct}%: sobreextracción confirmada (> 1.55%). Causa principal: molienda muy fina o tiempo excesivo.',
          'barista': 'TDS {measured_tds_pct}% — sobreextracción. Amargor tardío, aspereza, astringencia. Ajuste inmediato: molienda más gruesa.',
        },
        suggestedActions: [
          'Molienda más gruesa: +1.5 clicks (mayor impacto)',
          'Reducir temperatura 1°C',
          'Acelerar el vertido 10–15 segundos',
        ],
        parameters: {
          'primary_adjustment': 'grind_coarser',
          'grind_adjustment_clicks': 1.5,
          'diagnosis': 'over_extraction',
        },
      ),
    ),
  ];

  // ── CALIDAD DEL AGUA (SCA Water Standards 2018) ───────────────────────────
  // waterTds/waterPh = 0.0 → no medido → between 0.1–X evita falsos positivos.
  static const List<AIRule> _waterRules = [
    AIRule(
      id: 'BREW-WATER-PURE-001',
      module: 'brewing',
      name: 'Agua demasiado pura (TDS bajo SCA)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['water', 'tds', 'quality'],
      conditions: [
        RuleCondition(
          variable: 'water_tds',
          operator: ConditionOperator.between,
          threshold: 0.1,
          thresholdMax: CoffeeThresholds.waterTdsOptimalMin - 0.1,
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARN_WATER_TOO_PURE',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.88,
        explanationByRole: {
          'farmer': 'El agua está muy pura — no tiene los minerales que el café necesita para saber bien.',
          'processor': 'TDS agua: {water_tds} ppm — por debajo del mínimo SCA (${CoffeeThresholds.waterTdsOptimalMin} ppm). Agua destilada o con osmosis inversa sin remineralizar.',
          'barista': 'TDS {water_tds} ppm — agua demasiado pura. Los minerales (Ca²⁺, Mg²⁺) son necesarios para la extracción. Agregar minerales o mezclar con agua de grifo filtrada.',
        },
        suggestedActions: [
          'Remineralizar el agua (Mg²⁺ target: 20–30 ppm)',
          'Mezclar agua osmosis con agua filtrada para alcanzar 75–150 ppm TDS',
        ],
        parameters: {
          'tds_min_sca': CoffeeThresholds.waterTdsOptimalMin,
          'reason': 'insufficient_minerals_for_extraction',
        },
      ),
    ),

    AIRule(
      id: 'BREW-WATER-HARD-001',
      module: 'brewing',
      name: 'Agua demasiado dura (TDS sobre SCA)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['water', 'tds', 'hardness', 'quality'],
      conditions: [
        RuleCondition(
          variable: 'water_tds',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.waterTdsOptimalMax,
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARN_WATER_HARD',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.90,
        explanationByRole: {
          'farmer': 'El agua está muy cargada de minerales — el café puede saber metálico.',
          'processor': 'TDS agua: {water_tds} ppm — supera el máximo SCA (${CoffeeThresholds.waterTdsOptimalMax} ppm). Dureza excesiva inhibe extracción de ácidos aromáticos.',
          'barista': 'TDS {water_tds} ppm — agua muy dura. Puede generar sabor metálico, incrustaciones en equipo y subextracción de aromáticos. Filtrar o usar mezcla con agua suavizada.',
        },
        suggestedActions: [
          'Instalar filtro de dureza (suavizador o carbón activo)',
          'Mezclar con agua osmotizada hasta alcanzar < 250 ppm TDS',
          'Revisar equipo por depósitos de cal',
        ],
        parameters: {
          'tds_max_sca': CoffeeThresholds.waterTdsOptimalMax,
          'reason': 'excess_minerals_flavor_interference',
        },
      ),
    ),

    AIRule(
      id: 'BREW-WATER-PH-LOW-001',
      module: 'brewing',
      name: 'pH de agua bajo (agua ácida)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['water', 'ph', 'quality'],
      conditions: [
        RuleCondition(
          variable: 'water_ph',
          operator: ConditionOperator.between,
          threshold: 0.1,
          thresholdMax: CoffeeThresholds.waterPhOptimalMin - 0.01,
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARN_WATER_PH_LOW',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.85,
        explanationByRole: {
          'farmer': 'El agua está muy ácida y puede hacer el café más amargo de lo normal.',
          'processor': 'pH agua: {water_ph} — por debajo del rango SCA (${CoffeeThresholds.waterPhOptimalMin}–${CoffeeThresholds.waterPhOptimalMax}). Agua ácida sobreextrae ácidos y puede dañar juntas.',
          'barista': 'pH {water_ph} — agua ácida. Potencia la percepción de acidez en taza y puede generar extracción irregular. Objetivo SCA: pH 6.5–7.5.',
        },
        suggestedActions: [
          'Usar agua filtrada o embotellada con pH neutro (6.5–7.5)',
          'Verificar fuente de agua (lluvia ácida, ósmosis sin buffer)',
        ],
        parameters: {
          'ph_min_sca': CoffeeThresholds.waterPhOptimalMin,
          'reason': 'acidic_water_overextraction_risk',
        },
      ),
    ),

    AIRule(
      id: 'BREW-WATER-PH-HIGH-001',
      module: 'brewing',
      name: 'pH de agua alto (agua alcalina)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['water', 'ph', 'quality'],
      conditions: [
        RuleCondition(
          variable: 'water_ph',
          operator: ConditionOperator.gt,
          threshold: CoffeeThresholds.waterPhOptimalMax,
        ),
      ],
      outcome: RuleOutcome(
        action: 'WARN_WATER_PH_HIGH',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.85,
        explanationByRole: {
          'farmer': 'El agua está muy alcalina y puede apagar los sabores del café.',
          'processor': 'pH agua: {water_ph} — por encima del rango SCA (${CoffeeThresholds.waterPhOptimalMax}). Alcalinidad amortigua la acidez del café, extracción plana.',
          'barista': 'pH {water_ph} — agua alcalina. La bicarbonato-alcalinidad neutraliza los ácidos del café → perfil plano y sin brillo. Objetivo SCA: pH 6.5–7.5.',
        },
        suggestedActions: [
          'Usar agua filtrada o embotellada con pH neutro',
          'Verificar dureza carbonatada (bicarbonatos altos elevan pH)',
        ],
        parameters: {
          'ph_max_sca': CoffeeThresholds.waterPhOptimalMax,
          'reason': 'alkaline_water_acid_buffering',
        },
      ),
    ),
  ];
}
