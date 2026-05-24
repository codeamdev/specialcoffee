# Motor de Decisiones IA — SpecialCoffee AI
## Implementación del Rule Engine en Dart (Flutter)

**Versión:** 1.0 | **Fecha:** 30 de abril de 2026
**Autor:** AI Engineer
**Enfoque:** Implementación real, no teoría

---

## Decisión de implementación

> El motor es un sistema de reglas basado en datos (no hardcoded), evaluado 100% en el dispositivo, que produce recomendaciones ordenadas por confianza y urgencia. Las reglas viven en JSON actualizable sin publicar builds. El código evalúa — los datos deciden.

---

## 1. Núcleo del sistema: tipos y contratos

```dart
// lib/ai_engine/models/ai_context.dart
//
// Snapshot inmutable de todas las variables disponibles en un momento dado.
// El RuleEngine nunca lee de repositorios — solo de un AIContext ya construido.

@freezed
class AIContext with _$AIContext {
  const factory AIContext({
    // ── IDENTIDAD ────────────────────────────────────────────
    required String userId,
    required UserRole userRole,
    required String module,           // 'fermentation' | 'drying' | 'brewing' | 'harvest'

    // ── FINCA ────────────────────────────────────────────────
    String? lotId,
    String? plotId,
    required String varietyId,        // 'var_castillo' | 'var_geisha' | ...
    required int altitudeMasl,
    required String region,

    // ── AMBIENTE ─────────────────────────────────────────────
    required double ambientTempC,
    required double ambientHumidityPct,
    @Default(0.0) double rainProbabilityPct,
    @Default(0.0) double uvIndex,

    // ── PROCESO ACTIVO ────────────────────────────────────────
    String? processType,              // 'lavado' | 'natural' | 'honey_yellow' | ...
    @Default('') String fermentationStatus,  // 'active' | 'completed' | ''
    @Default(0.0) double fermentationHoursElapsed,
    @Default(0.0) double currentPh,
    @Default(0.0) double mucilagoTempC,
    @Default('') String mucilageState,      // 'liquid' | 'viscous' | 'gelatinous' | 'dry'
    @Default(0.0) double currentHumidityPct,
    @Default(0) int dryingDayNumber,

    // ── COSECHA ───────────────────────────────────────────────
    @Default(0.0) double brixLevel,
    @Default(0) int cherryColorPct,

    // ── PREPARACIÓN ───────────────────────────────────────────
    String? brewMethod,               // 'v60' | 'espresso' | 'chemex' | ...
    @Default('') String roastLevel,   // 'light' | 'medium' | 'dark'
    @Default(0) int roastDays,
    @Default(0.0) double waterHardnessPpm,
    @Default(0.0) double measuredTdsPct,
    @Default(0.0) double measuredYieldPct,

    // ── PERFIL APRENDIDO DEL USUARIO ─────────────────────────
    @Default(1.30) double userPreferredTdsMin,
    @Default(1.38) double userPreferredTdsMax,
    @Default(0.5) double userSweetnessWeight,
    @Default(0.5) double userAcidityWeight,
    @Default(0.78) double userAiTrustScore,

    // ── VARIEDAD (enriched desde catálogo) ───────────────────
    @Default('medium') String varietyFermentationSpeed,  // 'slow'|'medium'|'fast'
    @Default('medium') String varietySensitivity,        // 'low'|'medium'|'high'|'very_high'
    @Default(85.0) double varietyScaPotential,

    // ── HISTORIAL (para personalización) ─────────────────────
    @Default(0.0) double userAvgSca,
    @Default(0.0) double userAvgFermentationH,
    @Default(0) int userLotsCompleted,
  }) = _AIContext;

  factory AIContext.fromJson(Map<String, dynamic> json) =>
      _$AIContextFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/ai_engine/models/ai_rule.dart

enum ConditionOperator { gt, gte, lt, lte, eq, neq, between, inList, notIn }
enum AlertLevel { none, info, warning, high, critical }
enum RuleLogic { and, or }

@freezed
class RuleCondition with _$RuleCondition {
  const factory RuleCondition({
    required String variable,           // nombre del campo en AIContext
    required ConditionOperator operator,
    required dynamic threshold,
    double? thresholdMax,               // solo para 'between'
  }) = _RuleCondition;

  factory RuleCondition.fromJson(Map<String, dynamic> json) =>
      _$RuleConditionFromJson(json);
}

@freezed
class RuleOutcome with _$RuleOutcome {
  const factory RuleOutcome({
    required String action,
    required AlertLevel alertLevel,
    required double confidenceBase,
    required Map<String, String> explanationByRole,
    @Default([]) List<String> suggestedActions,
    @Default({}) Map<String, dynamic> parameters,
  }) = _RuleOutcome;

  factory RuleOutcome.fromJson(Map<String, dynamic> json) =>
      _$RuleOutcomeFromJson(json);
}

@freezed
class AIRule with _$AIRule {
  const factory AIRule({
    required String id,
    required String module,
    required String name,
    required int priority,              // 1=crítica, 5=informativa
    required RuleLogic logic,
    required List<RuleCondition> conditions,
    required RuleOutcome outcome,
    @Default(true) bool active,
    @Default([]) List<String> tags,
    String? supersedes,                 // ID de regla que esta reemplaza
    String? version,
  }) = _AIRule;

  factory AIRule.fromJson(Map<String, dynamic> json) =>
      _$AIRuleFromJson(json);
}

@freezed
class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String ruleId,
    required String action,
    required AlertLevel alertLevel,
    required double confidence,         // 0.0 – 1.0
    required String explanation,        // texto para el rol del usuario
    required List<String> suggestedActions,
    required Map<String, dynamic> parameters,
    required DateTime generatedAt,
  }) = _Recommendation;
}
```

---

## 2. Evaluador de condiciones

```dart
// lib/ai_engine/evaluators/condition_evaluator.dart
//
// Lee el AIContext dinámicamente por nombre de campo.
// Usa reflection simple con un mapa de accessors
// (más seguro que dart:mirrors en Flutter).

class ConditionEvaluator {
  // Mapa de accessors: variable_name → función que extrae el valor del contexto
  static final Map<String, double Function(AIContext)> _accessors = {
    'altitude_masl':            (c) => c.altitudeMasl.toDouble(),
    'ambient_temp_c':           (c) => c.ambientTempC,
    'ambient_humidity_pct':     (c) => c.ambientHumidityPct,
    'rain_probability_pct':     (c) => c.rainProbabilityPct,
    'uv_index':                 (c) => c.uvIndex,
    'brix_level':               (c) => c.brixLevel,
    'cherry_color_pct':         (c) => c.cherryColorPct.toDouble(),
    'fermentation_hours_elapsed': (c) => c.fermentationHoursElapsed,
    'current_ph':               (c) => c.currentPh,
    'mucilago_temp_c':          (c) => c.mucilagoTempC,
    'current_humidity_pct':     (c) => c.currentHumidityPct,
    'drying_day_number':        (c) => c.dryingDayNumber.toDouble(),
    'roast_days':               (c) => c.roastDays.toDouble(),
    'water_hardness_ppm':       (c) => c.waterHardnessPpm,
    'measured_tds_pct':         (c) => c.measuredTdsPct,
    'measured_yield_pct':       (c) => c.measuredYieldPct,
    'user_preferred_tds_min':   (c) => c.userPreferredTdsMin,
    'user_preferred_tds_max':   (c) => c.userPreferredTdsMax,
    'variety_sca_potential':    (c) => c.varietyScaPotential,
    'user_avg_sca':             (c) => c.userAvgSca,
    'user_lots_completed':      (c) => c.userLotsCompleted.toDouble(),
  };

  // Accessors para variables de texto (enums como strings)
  static final Map<String, String Function(AIContext)> _stringAccessors = {
    'process_type':              (c) => c.processType ?? '',
    'fermentation_status':       (c) => c.fermentationStatus,
    'mucilage_state':            (c) => c.mucilageState,
    'brew_method':               (c) => c.brewMethod ?? '',
    'roast_level':               (c) => c.roastLevel,
    'variety_id':                (c) => c.varietyId,
    'variety_fermentation_speed':(c) => c.varietyFermentationSpeed,
    'variety_sensitivity':       (c) => c.varietySensitivity,
    'region':                    (c) => c.region,
    'user_role':                 (c) => c.userRole.name,
    'module':                    (c) => c.module,
  };

  bool evaluate(RuleCondition condition, AIContext context) {
    // Intenta como numérico primero
    final numAccessor = _accessors[condition.variable];
    if (numAccessor != null) {
      return _evaluateNumeric(numAccessor(context), condition);
    }

    // Intenta como texto
    final strAccessor = _stringAccessors[condition.variable];
    if (strAccessor != null) {
      return _evaluateString(strAccessor(context), condition);
    }

    // Variable no reconocida — falla silenciosamente (regla no aplica)
    assert(false, 'Variable no reconocida en AIContext: ${condition.variable}');
    return false;
  }

  bool _evaluateNumeric(double value, RuleCondition c) {
    return switch (c.operator) {
      ConditionOperator.gt      => value > (c.threshold as num).toDouble(),
      ConditionOperator.gte     => value >= (c.threshold as num).toDouble(),
      ConditionOperator.lt      => value < (c.threshold as num).toDouble(),
      ConditionOperator.lte     => value <= (c.threshold as num).toDouble(),
      ConditionOperator.eq      => value == (c.threshold as num).toDouble(),
      ConditionOperator.neq     => value != (c.threshold as num).toDouble(),
      ConditionOperator.between => value >= (c.threshold as num).toDouble()
                                && value <= c.thresholdMax!,
      ConditionOperator.inList  => (c.threshold as List).contains(value),
      ConditionOperator.notIn   => !(c.threshold as List).contains(value),
    };
  }

  bool _evaluateString(String value, RuleCondition c) {
    return switch (c.operator) {
      ConditionOperator.eq      => value == c.threshold.toString(),
      ConditionOperator.neq     => value != c.threshold.toString(),
      ConditionOperator.inList  => (c.threshold as List)
                                     .map((e) => e.toString())
                                     .contains(value),
      ConditionOperator.notIn   => !(c.threshold as List)
                                     .map((e) => e.toString())
                                     .contains(value),
      _ => false,
    };
  }
}
```

---

## 3. Motor central: RuleEngine

```dart
// lib/ai_engine/core/rule_engine.dart

class RuleEngine {
  final ConditionEvaluator _evaluator;
  final ExplanationBuilder _explanationBuilder;
  final ConflictResolver _conflictResolver;
  final ConfidenceAdjuster _confidenceAdjuster;

  List<AIRule> _rules = [];
  String _rulesVersion = '';

  RuleEngine({
    required ConditionEvaluator evaluator,
    required ExplanationBuilder explanationBuilder,
    required ConflictResolver conflictResolver,
    required ConfidenceAdjuster confidenceAdjuster,
  })  : _evaluator = evaluator,
        _explanationBuilder = explanationBuilder,
        _conflictResolver = conflictResolver,
        _confidenceAdjuster = confidenceAdjuster;

  void loadRules(List<AIRule> rules, String version) {
    _rules = rules.where((r) => r.active).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    _rulesVersion = version;
  }

  List<Recommendation> evaluate(AIContext context) {
    // 1. Filtrar reglas por módulo activo
    final modulerules = _rules
        .where((r) => r.module == context.module || r.module == 'global')
        .toList();

    // 2. Evaluar condiciones
    final firedRules = modulerules
        .where((rule) => _allConditionsMet(rule, context))
        .toList();

    if (firedRules.isEmpty) return [];

    // 3. Resolver conflictos (reglas contradictorias)
    final resolvedRules = _conflictResolver.resolve(firedRules);

    // 4. Ajustar confianza según riqueza del contexto
    final scoredRules = resolvedRules.map((rule) {
      final adjustedConfidence = _confidenceAdjuster.adjust(
        baseConfidence: rule.outcome.confidenceBase,
        rule: rule,
        context: context,
      );
      return (rule: rule, confidence: adjustedConfidence);
    }).toList();

    // 5. Ordenar: prioridad (críticas primero), luego confianza
    scoredRules.sort((a, b) {
      final priorityDiff = a.rule.priority.compareTo(b.rule.priority);
      if (priorityDiff != 0) return priorityDiff;
      return b.confidence.compareTo(a.confidence);
    });

    // 6. Construir Recommendations con texto personalizado
    return scoredRules.map((scored) {
      return Recommendation(
        ruleId: scored.rule.id,
        action: scored.rule.outcome.action,
        alertLevel: scored.rule.outcome.alertLevel,
        confidence: scored.confidence,
        explanation: _explanationBuilder.build(
          rule: scored.rule,
          context: context,
          confidence: scored.confidence,
        ),
        suggestedActions: scored.rule.outcome.suggestedActions,
        parameters: scored.rule.outcome.parameters,
        generatedAt: DateTime.now(),
      );
    }).toList();
  }

  bool _allConditionsMet(AIRule rule, AIContext context) {
    if (rule.conditions.isEmpty) return false;

    return switch (rule.logic) {
      RuleLogic.and => rule.conditions.every(
          (c) => _evaluator.evaluate(c, context)),
      RuleLogic.or  => rule.conditions.any(
          (c) => _evaluator.evaluate(c, context)),
    };
  }
}
```

---

## 4. Ajuste de confianza por contexto

```dart
// lib/ai_engine/evaluators/confidence_adjuster.dart
//
// La confianza base de una regla sube o baja según la calidad
// de los datos disponibles en el contexto.

class ConfidenceAdjuster {
  double adjust({
    required double baseConfidence,
    required AIRule rule,
    required AIContext context,
  }) {
    double bonus = 0.0;

    // Dato de primera mano (sensor) vs estimación visual
    if (rule.tags.contains('ph') && context.currentPh > 0) {
      bonus += 0.03;  // pH medido con instrumento real
    }
    if (rule.tags.contains('brix') && context.brixLevel > 0) {
      bonus += 0.03;  // Brix medido con refractómetro
    }

    // Historial del usuario — más lotes = mejor calibración
    if (context.userLotsCompleted > 5) bonus += 0.02;
    if (context.userLotsCompleted > 20) bonus += 0.02;

    // Datos de clima disponibles (no solo default)
    if (context.rainProbabilityPct > 0) bonus += 0.01;

    // Penalización por datos faltantes o estimados
    if (context.brixLevel == 0 && rule.tags.contains('harvest')) {
      bonus -= 0.08;  // Recomendar cosecha sin Brix es arriesgado
    }
    if (context.ambientTempC == 20.0 && rule.tags.contains('fermentation')) {
      // 20°C es el default — posiblemente no fue medido
      bonus -= 0.05;
    }

    // Penalización por variedad desconocida
    if (context.varietyId == 'var_unknown') bonus -= 0.10;

    return (baseConfidence + bonus).clamp(0.30, 0.99);
  }
}
```

---

## 5. Módulo de Producción: reglas completas

### 5.1 Reglas de cosecha (JSON + evaluación)

```json
[
  {
    "id": "HARV-BRIX-OPTIMAL-001",
    "module": "harvest",
    "name": "Brix en rango óptimo para cosecha",
    "priority": 2,
    "logic": "AND",
    "tags": ["brix", "harvest", "go"],
    "active": true,
    "conditions": [
      { "variable": "brix_level", "operator": "between", "threshold": 20.0, "threshold_max": 24.0 },
      { "variable": "cherry_color_pct", "operator": "gte", "threshold": 75 }
    ],
    "outcome": {
      "action": "HARVEST_NOW",
      "alert_level": "none",
      "confidence_base": 0.92,
      "explanation_by_role": {
        "farmer": "✅ Coseche ahora — sus cerezas están en el punto justo de madurez.",
        "processor": "✅ Brix {brix_level}° y {cherry_color_pct}% de color rojo. Condiciones óptimas de cosecha.",
        "barista": "✅ Brix {brix_level}° — madurez completa. Perfil azucarado esperado."
      },
      "suggested_actions": [
        "Iniciar cosecha selectiva en las próximas 36 horas",
        "Separar cerezas por nivel de madurez si es posible"
      ],
      "parameters": { "harvest_window_hours": 36 }
    }
  },
  {
    "id": "HARV-BRIX-LOW-001",
    "module": "harvest",
    "name": "Brix bajo — madurez incompleta",
    "priority": 2,
    "logic": "AND",
    "tags": ["brix", "harvest", "warning"],
    "active": true,
    "conditions": [
      { "variable": "brix_level", "operator": "between", "threshold": 17.0, "threshold_max": 19.9 }
    ],
    "outcome": {
      "action": "DELAY_HARVEST",
      "alert_level": "warning",
      "confidence_base": 0.88,
      "explanation_by_role": {
        "farmer": "⚠️ Espere 3–5 días más. Sus cerezas aún no están dulces. Cosechar ahora da café amargo.",
        "processor": "⚠️ Brix {brix_level}° — subóptimo. Posponer cosecha 3–5 días para desarrollo de azúcares.",
        "barista": "⚠️ Brix {brix_level}° — subdesarrollo de azúcares. Riesgo de astringencia y baja dulzura en taza."
      },
      "suggested_actions": [
        "Posponer cosecha mínimo 3 días",
        "Nueva lectura de Brix en 48 horas",
        "Si lluvia en pronóstico, evaluar riesgo de esperar"
      ],
      "parameters": { "wait_days_min": 3, "wait_days_max": 5, "recheck_hours": 48 }
    }
  },
  {
    "id": "HARV-RAIN-URGENT-001",
    "module": "harvest",
    "name": "Cosecha urgente por lluvia inminente",
    "priority": 1,
    "logic": "AND",
    "tags": ["harvest", "weather", "urgent"],
    "active": true,
    "conditions": [
      { "variable": "brix_level", "operator": "between", "threshold": 19.0, "threshold_max": 24.0 },
      { "variable": "rain_probability_pct", "operator": "gte", "threshold": 70.0 }
    ],
    "outcome": {
      "action": "HARVEST_URGENT",
      "alert_level": "high",
      "confidence_base": 0.85,
      "explanation_by_role": {
        "farmer": "⚠️ Coseche hoy si puede — la lluvia puede dañar las cerezas en el árbol y diluir el azúcar.",
        "processor": "⚠️ Lluvia > 70% en 24h con Brix {brix_level}°. Cosecha de emergencia recomendada hoy.",
        "barista": "⚠️ Lluvia inminente con Brix en transición. Cosecha ahora preserva el desarrollo alcanzado."
      },
      "suggested_actions": [
        "Cosechar en las próximas 12 horas",
        "Priorizar parcelas de mayor altitud (más expuestas)"
      ],
      "parameters": { "urgency_hours": 12 }
    }
  }
]
```

### 5.2 Reglas de proceso (selección)

```dart
// lib/ai_engine/rules/process_selection_rules.dart
//
// Las reglas de selección de proceso son más complejas y se
// benefician de estar en Dart para el cálculo de score combinado.

class ProcessSelectionModule {
  static List<AIRule> get rules => [
    // ── PROCESO LAVADO ───────────────────────────────────────
    const AIRule(
      id: 'PROC-LAVADO-HIGH-ALT-001',
      module: 'process_selection',
      name: 'Lavado para altitudes medias-altas con temp fresca',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['process', 'lavado', 'altitude'],
      conditions: [
        RuleCondition(
          variable: 'altitude_masl',
          operator: ConditionOperator.between,
          threshold: 1400,
          thresholdMax: 2200,
        ),
        RuleCondition(
          variable: 'ambient_temp_c',
          operator: ConditionOperator.between,
          threshold: 15.0,
          thresholdMax: 24.0,
        ),
        RuleCondition(
          variable: 'variety_sensitivity',
          operator: ConditionOperator.inList,
          threshold: ['low', 'medium', 'high'],
        ),
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

    // ── PROCESO ANAERÓBICO ────────────────────────────────────
    const AIRule(
      id: 'PROC-ANAEROBIC-GEISHA-001',
      module: 'process_selection',
      name: 'Anaeróbico para variedades de alta complejidad en alturas > 1800',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['process', 'anaerobic', 'specialty'],
      conditions: [
        RuleCondition(
          variable: 'altitude_masl',
          operator: ConditionOperator.gte,
          threshold: 1800,
        ),
        RuleCondition(
          variable: 'ambient_temp_c',
          operator: ConditionOperator.lte,
          threshold: 21.0,
        ),
        RuleCondition(
          variable: 'variety_sensitivity',
          operator: ConditionOperator.inList,
          threshold: ['high', 'very_high'],
        ),
        RuleCondition(
          variable: 'variety_sca_potential',
          operator: ConditionOperator.gte,
          threshold: 86.0,
        ),
      ],
      outcome: RuleOutcome(
        action: 'SELECT_PROCESS_ANAEROBIC',
        alertLevel: AlertLevel.none,
        confidenceBase: 0.84,
        explanationByRole: {
          'farmer': 'Con su café y la temperatura fresca, el proceso anaeróbico puede dar un café muy especial y con mejor precio.',
          'processor': 'Variedad de alta complejidad ({variety_id}) a {altitude_masl} msnm y {ambient_temp_c}°C: anaeróbico láctico recomendado. Fermentación 48–72h con tanque sellado.',
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

    // ── PROCESO NATURAL ────────────────────────────────────────
    const AIRule(
      id: 'PROC-NATURAL-DRY-CONDITIONS-001',
      module: 'process_selection',
      name: 'Natural para condiciones secas y alturas medias',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['process', 'natural', 'weather'],
      conditions: [
        RuleCondition(
          variable: 'ambient_humidity_pct',
          operator: ConditionOperator.lte,
          threshold: 70.0,
        ),
        RuleCondition(
          variable: 'rain_probability_pct',
          operator: ConditionOperator.lte,
          threshold: 20.0,
        ),
        RuleCondition(
          variable: 'altitude_masl',
          operator: ConditionOperator.between,
          threshold: 1200,
          thresholdMax: 1800,
        ),
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
```

### 5.3 Reglas de fermentación (críticas)

```dart
// lib/ai_engine/rules/fermentation_rules.dart

class FermentationRules {
  static List<AIRule> get all => [
    ..._alertRules,
    ..._guidanceRules,
    ..._projectionRules,
  ];

  // ── ALERTAS (prioridad 1) ────────────────────────────────────

  static List<AIRule> get _alertRules => [
    const AIRule(
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

    const AIRule(
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
        parameters: { 'urgency_hours': 2, 'recheck_minutes': 30 },
      ),
    ),

    const AIRule(
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
        parameters: { 'next_reading_hours': 1 },
      ),
    ),

    const AIRule(
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
        parameters: { 'recheck_hours': 2 },
      ),
    ),
  ];

  // ── ORIENTACIÓN (prioridad 3) ────────────────────────────────

  static List<AIRule> get _guidanceRules => [
    const AIRule(
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
        parameters: { 'wash_repetitions': 3 },
      ),
    ),
  ];

  // ── PROYECCIONES (prioridad 4) ───────────────────────────────

  static List<AIRule> get _projectionRules => [
    const AIRule(
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
        parameters: { 'additional_hours_estimate': 15, 'next_reading_hours': 4 },
      ),
    ),
  ];
}
```

### 5.4 Reglas de secado

```dart
// lib/ai_engine/rules/drying_rules.dart

class DryingRules {
  static List<AIRule> get all => [
    const AIRule(
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
        parameters: { 'min_rest_days': 30, 'max_storage_temp_c': 20 },
      ),
    ),

    const AIRule(
      id: 'DRY-OVER-DRIED-001',
      module: 'drying',
      name: 'SobreSecado — humedad por debajo del mínimo',
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
          'processor': '⚠️ Humedad {current_humidity_pct}% — por debajo del mínimo (10.5%). Transferir urgente. Riesgo de fragmented beans y pérdida de rendimiento en trilla.',
          'barista': '⚠️ Sobredesecado ({current_humidity_pct}%). En taza: riesgo de notas de madera, cuerpo reducido y pérdida de complejidad aromática.',
        },
        suggestedActions: [
          'Retirar del área de secado inmediatamente',
          'Almacenar en ambiente controlado (65–70% HR)',
          'NO trillar hasta que estabilice humedad',
        ],
        parameters: { 'urgency': 'immediate' },
      ),
    ),

    const AIRule(
      id: 'DRY-SLOW-PROGRESS-001',
      module: 'drying',
      name: 'Progreso de secado lento — debajo de curva',
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
          'Si hay lluvia, cubrir y descubrir inmediatamente',
        ],
        parameters: {},
      ),
    ),
  ];
}
```

---

## 6. Módulo de Preparación: reglas de brewing

```dart
// lib/ai_engine/rules/brewing_rules.dart

class BrewingRules {
  static List<AIRule> get all => [
    ..._recipeRules,
    ..._diagnosisRules,
  ];

  // ── AJUSTES DE RECETA ────────────────────────────────────────

  static List<AIRule> get _recipeRules => [
    const AIRule(
      id: 'BREW-TEMP-ALTITUDE-001',
      module: 'brewing',
      name: 'Ajuste de temperatura por altitud (Bogotá y ciudades altas)',
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
        suggestedActions: [],
        parameters: {
          'temp_adjustment_c': -2.0,
          'reason': 'altitude_boiling_point_reduction',
        },
      ),
    ),

    const AIRule(
      id: 'BREW-BLOOM-FRESH-ROAST-001',
      module: 'brewing',
      name: 'Bloom extendido para café recién tostado',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['bloom', 'roast', 'recipe', 'v60', 'chemex'],
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
          'barista': '{roast_days} días de tueste: degassing activo. Bloom +15s (total {bloom_seconds}s) con 3× la dosis de agua.',
        },
        suggestedActions: [],
        parameters: { 'bloom_extension_seconds': 15, 'bloom_water_ratio': 3.0 },
      ),
    ),

    const AIRule(
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
          'barista': 'Tu preferencia de dulzor ({user_sweetness_weight}) sugiere ratio 1:15–1:15.5 vs el estándar 1:16. Extrae más sólidos de azúcar.',
        },
        suggestedActions: [],
        parameters: { 'ratio_adjustment': 0.5, 'direction': 'more_concentrated' },
      ),
    ),

    const AIRule(
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
        suggestedActions: [],
        parameters: { 'temp_adjustment_c': 1.0, 'base_temp_c': 93.0 },
      ),
    ),
  ];

  // ── DIAGNÓSTICO POST-EXTRACCIÓN ──────────────────────────────

  static List<AIRule> get _diagnosisRules => [
    const AIRule(
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

    const AIRule(
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
          'barista': 'TDS {measured_tds_pct}% bajo objetivo ({user_preferred_tds_min}%). Subextracción: acidez aguda, dulzor bajo, cuerpo ligero. Ajuste: molienda más fina.',
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

    const AIRule(
      id: 'BREW-DIAG-OPTIMAL-001',
      module: 'brewing',
      name: 'Extracción en rango óptimo personal',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['tds', 'extraction', 'optimal'],
      conditions: [
        RuleCondition(variable: 'measured_tds_pct', operator: ConditionOperator.gte, threshold: 1.15),
        RuleCondition(variable: 'measured_tds_pct', operator: ConditionOperator.lte, threshold: 1.45),
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
        parameters: { 'session_quality': 'optimal' },
      ),
    ),
  ];
}
```

---

## 7. Constructor de contexto y generador de recetas

```dart
// lib/ai_engine/core/brew_recipe_generator.dart
//
// Genera la receta base inicial antes de que el usuario empiece a preparar.
// No usa el rule engine genérico — es lógica de dominio específica de brewing.

class BrewRecipeGenerator {
  // Tablas de base por método (en condiciones estándar: 1000 msnm, 20°C, 150ppm)
  static const Map<String, _BaseRecipe> _baseRecipes = {
    'v60':         _BaseRecipe(ratio: 15.5, tempC: 91.0, bloomRatio: 2.5, bloomSeconds: 35),
    'chemex':      _BaseRecipe(ratio: 16.5, tempC: 92.0, bloomRatio: 2.5, bloomSeconds: 40),
    'french_press':_BaseRecipe(ratio: 15.0, tempC: 93.0, bloomRatio: 0, bloomSeconds: 0),
    'aeropress':   _BaseRecipe(ratio: 13.0, tempC: 85.0, bloomRatio: 3.0, bloomSeconds: 30),
    'espresso':    _BaseRecipe(ratio: 2.0,  tempC: 93.0, bloomRatio: 0, bloomSeconds: 0),
    'moka':        _BaseRecipe(ratio: 7.5,  tempC: 0,    bloomRatio: 0, bloomSeconds: 0),
    'chemex':      _BaseRecipe(ratio: 16.5, tempC: 92.0, bloomRatio: 2.5, bloomSeconds: 40),
  };

  BrewRecipe generate(AIContext context) {
    final base = _baseRecipes[context.brewMethod] ?? _baseRecipes['v60']!;

    double tempC = base.tempC;
    double ratio = base.ratio;
    int bloomSeconds = base.bloomSeconds;

    // ── Ajuste 1: Altitud → temperatura de ebullición ───────────
    // Temperatura de ebullición ≈ 100 - (altitud / 300)
    if (context.altitudeMasl > 1500) {
      final boilingPoint = 100 - (context.altitudeMasl / 300);
      final maxUsableTemp = boilingPoint - 2.0;  // nunca sobre el punto de ebullición
      tempC = tempC.clamp(tempC - 3.0, maxUsableTemp);
    }

    // ── Ajuste 2: Nivel de tueste → temperatura ─────────────────
    tempC += switch (context.roastLevel) {
      'light'  => 1.0,   // más temperatura para tuestes claros
      'dark'   => -2.0,  // menos temperatura para tuestes oscuros
      _        => 0.0,
    };

    // ── Ajuste 3: Días de tueste → bloom ────────────────────────
    if (context.roastDays <= 7) {
      bloomSeconds += 20;  // café muy fresco, mucho CO₂
    } else if (context.roastDays <= 14) {
      bloomSeconds += 10;  // café fresco
    } else if (context.roastDays > 45) {
      bloomSeconds = (bloomSeconds * 0.75).round();  // café añejo, poco CO₂
    }

    // ── Ajuste 4: Proceso del café → temperatura ─────────────────
    if (context.processType != null) {
      tempC += switch (context.processType!) {
        'anaerobic_lactic' => -1.0,   // más delicado
        'natural'          => -0.5,
        'lavado'           => 0.0,
        _                  => 0.0,
      };
    }

    // ── Ajuste 5: Preferencias de usuario → ratio ────────────────
    if (context.userSweetnessWeight > 0.7) {
      ratio -= 0.5;  // más concentrado para perfiles dulces
    } else if (context.userAcidityWeight > 0.7) {
      ratio += 0.5;  // más diluido para perfiles de acidez brillante
    }

    // ── Ajuste 6: Dureza del agua → temperatura ──────────────────
    if (context.waterHardnessPpm > 200) {
      tempC -= 1.0;  // agua muy dura necesita menos temperatura
    } else if (context.waterHardnessPpm < 50) {
      tempC += 0.5;  // agua muy suave extrae más rápido
    }

    // ── Calcular parámetros derivados ────────────────────────────
    final doseG = 20.0;  // dosis base fija — el usuario puede cambiarla
    final waterG = doseG * ratio;
    final bloomG = doseG * base.bloomRatio;

    return BrewRecipe(
      method: context.brewMethod!,
      doseG: doseG,
      waterG: waterG,
      ratio: ratio,
      waterTempC: tempC.roundToDouble(),
      bloomG: bloomG,
      bloomSeconds: bloomSeconds,
      tdsTargetMin: context.userPreferredTdsMin,
      tdsTargetMax: context.userPreferredTdsMax,
      yieldTargetMin: 19.0,
      yieldTargetMax: 21.0,
      adjustmentsApplied: _buildAdjustmentsLog(context, base, tempC, ratio, bloomSeconds),
    );
  }

  List<String> _buildAdjustmentsLog(AIContext ctx, _BaseRecipe base,
      double finalTemp, double finalRatio, int finalBloom) {
    final log = <String>[];
    if ((finalTemp - base.tempC).abs() > 0.1) {
      log.add('Temperatura ajustada a ${finalTemp}°C (altitud ${ctx.altitudeMasl} msnm)');
    }
    if (ctx.roastDays <= 14) {
      log.add('Bloom extendido por café reciente (${ctx.roastDays} días de tueste)');
    }
    if (ctx.userSweetnessWeight > 0.7) {
      log.add('Ratio más concentrado por preferencia de dulzor del usuario');
    }
    return log;
  }
}

class _BaseRecipe {
  final double ratio;
  final double tempC;
  final double bloomRatio;
  final int bloomSeconds;
  const _BaseRecipe({
    required this.ratio,
    required this.tempC,
    required this.bloomRatio,
    required this.bloomSeconds,
  });
}
```

---

## 8. AlertEngine — monitor permanente de umbrales

```dart
// lib/ai_engine/core/alert_engine.dart
//
// Evaluación rápida de umbrales — más eficiente que el RuleEngine completo.
// Corre cada vez que llega una nueva lectura, sin esperar evaluación completa.

class AlertEngine {
  // Umbrales hardcoded como constantes — solo para alertas críticas.
  // Las reglas de orientación y proyección van en el RuleEngine JSON.

  static const Map<String, _AlertThresholds> _fermentationThresholds = {
    'lavado': _AlertThresholds(
      phCriticalLow: 3.5,
      phHighLow: 4.0,
      phOptimalMin: 4.0,
      phOptimalMax: 4.8,
      tempCriticalHigh: 30.0,
      tempHighHigh: 27.0,
      tempOptimalMin: 16.0,
      tempOptimalMax: 25.0,
    ),
    'natural': _AlertThresholds(
      phCriticalLow: 3.2,
      phHighLow: 3.6,
      phOptimalMin: 3.5,
      phOptimalMax: 4.2,
      tempCriticalHigh: 28.0,
      tempHighHigh: 25.0,
      tempOptimalMin: 15.0,
      tempOptimalMax: 22.0,
    ),
    'anaerobic_lactic': _AlertThresholds(
      phCriticalLow: 3.0,
      phHighLow: 3.5,
      phOptimalMin: 3.5,
      phOptimalMax: 4.5,
      tempCriticalHigh: 25.0,
      tempHighHigh: 22.0,
      tempOptimalMin: 14.0,
      tempOptimalMax: 20.0,
    ),
  };

  List<Alert> evaluateFermentationReading({
    required double ph,
    required double mucilagoTemp,
    required String processType,
    required String lotId,
  }) {
    final thresholds = _fermentationThresholds[processType]
        ?? _fermentationThresholds['lavado']!;

    final alerts = <Alert>[];

    // ── pH ───────────────────────────────────────────────────────
    if (ph < thresholds.phCriticalLow) {
      alerts.add(Alert(
        type: AlertType.phCritical,
        level: AlertLevel.critical,
        triggerValue: ph,
        threshold: thresholds.phCriticalLow,
        lotId: lotId,
        ruleId: 'FERM-PH-CRITICAL-$processType'.toUpperCase(),
      ));
    } else if (ph < thresholds.phHighLow) {
      alerts.add(Alert(
        type: AlertType.phHigh,
        level: AlertLevel.high,
        triggerValue: ph,
        threshold: thresholds.phHighLow,
        lotId: lotId,
        ruleId: 'FERM-PH-HIGH-001',
      ));
    }

    // ── Temperatura ───────────────────────────────────────────────
    if (mucilagoTemp > thresholds.tempCriticalHigh) {
      alerts.add(Alert(
        type: AlertType.tempCritical,
        level: AlertLevel.critical,
        triggerValue: mucilagoTemp,
        threshold: thresholds.tempCriticalHigh,
        lotId: lotId,
        ruleId: 'FERM-TEMP-CRITICAL-001',
      ));
    } else if (mucilagoTemp > thresholds.tempHighHigh) {
      alerts.add(Alert(
        type: AlertType.tempHigh,
        level: AlertLevel.warning,
        triggerValue: mucilagoTemp,
        threshold: thresholds.tempHighHigh,
        lotId: lotId,
        ruleId: 'FERM-TEMP-HIGH-001',
      ));
    }

    return alerts;
  }

  // Proyección de tiempo de finalización basada en tasa de cambio de pH
  double? projectFermentationEndHours({
    required List<FermentationReading> readings,
    required double targetPhMin,
  }) {
    if (readings.length < 3) return null;  // necesita al menos 3 puntos

    // Regresión lineal simple sobre las últimas 4 lecturas
    final recent = readings.length > 4
        ? readings.sublist(readings.length - 4)
        : readings;

    final n = recent.length.toDouble();
    final sumX = recent.map((r) => r.hoursElapsed).reduce((a, b) => a + b);
    final sumY = recent.map((r) => r.phValue).reduce((a, b) => a + b);
    final sumXY = recent.map((r) => r.hoursElapsed * r.phValue).reduce((a, b) => a + b);
    final sumX2 = recent.map((r) => r.hoursElapsed * r.hoursElapsed).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    if (slope >= 0) return null;  // pH no está bajando — no proyectar

    // h = (targetPh - intercept) / slope
    final hoursToTarget = (targetPhMin - intercept) / slope;
    final currentHours = recent.last.hoursElapsed;

    return (hoursToTarget - currentHours).clamp(0, 48);
  }
}

class _AlertThresholds {
  final double phCriticalLow;
  final double phHighLow;
  final double phOptimalMin;
  final double phOptimalMax;
  final double tempCriticalHigh;
  final double tempHighHigh;
  final double tempOptimalMin;
  final double tempOptimalMax;
  const _AlertThresholds({
    required this.phCriticalLow,
    required this.phHighLow,
    required this.phOptimalMin,
    required this.phOptimalMax,
    required this.tempCriticalHigh,
    required this.tempHighHigh,
    required this.tempOptimalMin,
    required this.tempOptimalMax,
  });
}
```

---

## 9. Ejemplos reales: input → output

### Ejemplo 1 — Selección de proceso

```
INPUT (AIContext):
  variety_id             = 'var_geisha'
  altitude_masl          = 1.920
  ambient_temp_c         = 16.0
  ambient_humidity_pct   = 82.0
  rain_probability_pct   = 8.0
  variety_sensitivity    = 'very_high'
  variety_sca_potential  = 89.5
  module                 = 'process_selection'

REGLAS QUE SE ACTIVAN:
  PROC-ANAEROBIC-GEISHA-001:
    ✅ altitude_masl >= 1800    (1920 >= 1800)
    ✅ ambient_temp_c <= 21     (16.0 <= 21.0)
    ✅ variety_sensitivity IN   [high, very_high]
    ✅ variety_sca_potential >= 86  (89.5 >= 86.0)
    → ACTIVA con confianza base 0.84
    → ConfidenceAdjuster: +0.03 (usuario > 5 lotes) = 0.87

  PROC-LAVADO-HIGH-ALT-001:
    ✅ altitude_masl BETWEEN 1400-2200
    ✅ ambient_temp_c BETWEEN 15-24
    ✅ variety_sensitivity IN [low, medium, high]  ← 'very_high' NO está
    → NO ACTIVA

OUTPUT:
  Recommendation(
    ruleId: 'PROC-ANAEROBIC-GEISHA-001',
    action: 'SELECT_PROCESS_ANAEROBIC',
    alertLevel: AlertLevel.none,
    confidence: 0.87,
    explanation: 'Variedad de alta complejidad (Geisha) a 1.920 msnm y 16°C:
      anaeróbico láctico recomendado. Fermentación 48–72h con tanque sellado.',
    suggestedActions: [
      'Usar tanque sellado con válvula de CO₂',
      'Fermentación 48–72h según pH',
      'Monitorear cada 6 horas',
    ],
    parameters: {
      'estimated_fermentation_min_h': 48,
      'estimated_fermentation_max_h': 72,
      'expected_sca_range': [86, 92],
    },
  )
```

### Ejemplo 2 — Alerta crítica de fermentación (2am)

```
INPUT (nueva lectura):
  current_ph             = 3.4
  mucilago_temp_c        = 28.5
  process_type           = 'lavado'
  fermentation_status    = 'active'
  fermentation_hours     = 28.5
  module                 = 'fermentation'

EVALUACIÓN AlertEngine (< 1ms, antes que el RuleEngine):
  ph (3.4) < phCriticalLow (3.5) para 'lavado' → CRITICAL

EVALUACIÓN RuleEngine:
  FERM-PH-CRITICAL-LAVADO-001:
    ✅ current_ph < 3.5
    ✅ process_type == 'lavado'
    ✅ fermentation_status == 'active'
    → ACTIVA priority=1, confidence=0.97

  FERM-TEMP-HIGH-001:
    ✅ mucilago_temp_c BETWEEN 27–30 (28.5)
    ✅ fermentation_status == 'active'
    → ACTIVA priority=2, confidence=0.87

OUTPUT (ordenado por prioridad):
  [0] Recommendation(
    ruleId: 'FERM-PH-CRITICAL-LAVADO-001',
    action: 'STOP_FERMENTATION_IMMEDIATELY',
    alertLevel: AlertLevel.critical,
    confidence: 0.97,
    explanation: '🔴 DETENGA LA FERMENTACIÓN AHORA. El café tiene demasiada
      acidez y va a quedar con sabor a vinagre. Llévelo al canal de lavado
      con agua limpia.',
    parameters: { 'urgency_hours': 1, 'vibration_pattern': 'critical' },
  )
  [1] Recommendation(
    ruleId: 'FERM-TEMP-HIGH-001',
    action: 'REDUCE_TEMPERATURE',
    alertLevel: AlertLevel.warning,
    confidence: 0.87,
    ...  ← presentada después de resolver la crítica
  )

ACCIONES DEL SISTEMA:
  → Firebase Cloud Function detecta alert_level = 'critical'
  → Envía push notification con vibración 'critical'
  → Modal bloqueante en la app (no dismissable sin confirmación)
```

### Ejemplo 3 — Receta V60 personalizada para barista en Bogotá

```
INPUT (AIContext):
  brew_method            = 'v60'
  altitude_masl          = 2.600   (Bogotá)
  variety_id             = 'var_geisha'
  process_type           = 'anaerobic_lactic'
  roast_level            = 'light'
  roast_days             = 12
  water_hardness_ppm     = 120
  user_sweetness_weight  = 0.82
  user_preferred_tds_min = 1.30
  user_preferred_tds_max = 1.38
  ambient_temp_c         = 15.0

CÁLCULO BrewRecipeGenerator:
  Base V60: ratio=15.5, temp=91.0°C, bloom=35s

  Ajuste 1 (altitud 2600):
    boiling_point = 100 - (2600/300) = 91.3°C
    max_usable = 89.3°C
    temp = min(91.0, 89.3) = 89.3°C → redondeado 89°C

  Ajuste 2 (tueste light):
    temp += 1.0 → 90°C ← pero ya está limitado a 89°C por altitud
    → permanece 89°C

  Ajuste 3 (12 días de tueste ≤ 14):
    bloom += 10 → 45 segundos

  Ajuste 4 (proceso anaeróbico):
    temp += -1.0 → 88°C

  Ajuste 5 (sweetness_weight = 0.82 > 0.7):
    ratio -= 0.5 → 15.0

  Ajuste 6 (agua 120ppm — dentro de rango):
    sin ajuste

  DERIVADOS:
    dose = 20g
    water = 20 × 15.0 = 300g
    bloom_g = 20 × 2.5 = 50g

OUTPUT BrewRecipe:
  method:           v60
  dose_g:           20.0
  water_g:          300.0
  ratio:            15.0
  water_temp_c:     88.0
  bloom_g:          50.0
  bloom_seconds:    45
  tds_target_min:   1.30%
  tds_target_max:   1.38%
  adjustments: [
    'Temperatura ajustada a 88°C (altitud 2600 msnm)',
    'Bloom extendido por café reciente (12 días de tueste)',
    'Ratio más concentrado (1:15) por preferencia de dulzor del usuario',
  ]
```

### Ejemplo 4 — Diagnóstico post-extracción

```
INPUT:
  measured_tds_pct    = 1.52
  measured_yield_pct  = 23.4
  user_preferred_tds_max = 1.38
  module              = 'brewing'

REGLA ACTIVADA:
  BREW-DIAG-OVER-EXTRACTED-001:
    ✅ measured_tds_pct > 1.55 → NO (1.52 < 1.55)
    ✅ measured_yield_pct > 23.0 → SÍ (23.4 > 23.0)
    Logic: OR → ACTIVA

OUTPUT:
  Recommendation(
    action: 'DIAGNOSE_OVER_EXTRACTION',
    alertLevel: AlertLevel.info,
    confidence: 0.90,
    explanation: 'TDS 1.52% supera tu objetivo (1.38%). Sobreextracción:
      amargor y aspereza tardía. Ajuste principal: molienda más gruesa.',
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
  )
```

---

## 10. Generador de explicaciones dinámicas

```dart
// lib/ai_engine/evaluators/explanation_builder.dart
//
// Toma la plantilla de texto de la regla y la personaliza
// con valores reales del contexto actual.

class ExplanationBuilder {
  String build({
    required AIRule rule,
    required AIContext context,
    required double confidence,
  }) {
    // Seleccionar texto por rol del usuario
    final roleKey = context.userRole.name;
    final template = rule.outcome.explanationByRole[roleKey]
        ?? rule.outcome.explanationByRole['processor']   // fallback
        ?? rule.outcome.explanationByRole.values.first;

    // Sustituir variables en la plantilla
    var explanation = template
        .replaceAll('{altitude_masl}',        context.altitudeMasl.toString())
        .replaceAll('{ambient_temp_c}',        context.ambientTempC.toString())
        .replaceAll('{current_ph}',            context.currentPh.toStringAsFixed(1))
        .replaceAll('{mucilago_temp_c}',       context.mucilagoTempC.toString())
        .replaceAll('{brix_level}',            context.brixLevel.toString())
        .replaceAll('{cherry_color_pct}',      context.cherryColorPct.toString())
        .replaceAll('{current_humidity_pct}',  context.currentHumidityPct.toStringAsFixed(1))
        .replaceAll('{drying_day_number}',     context.dryingDayNumber.toString())
        .replaceAll('{variety_id}',            _prettyVariety(context.varietyId))
        .replaceAll('{variety_sca_potential}', context.varietyScaPotential.toString())
        .replaceAll('{process_type}',          _prettyProcess(context.processType ?? ''))
        .replaceAll('{measured_tds_pct}',      context.measuredTdsPct.toStringAsFixed(2))
        .replaceAll('{measured_yield_pct}',    context.measuredYieldPct.toStringAsFixed(1))
        .replaceAll('{user_preferred_tds_max}',context.userPreferredTdsMax.toString())
        .replaceAll('{user_preferred_tds_min}',context.userPreferredTdsMin.toString())
        .replaceAll('{user_sweetness_weight}', context.userSweetnessWeight.toStringAsFixed(1))
        .replaceAll('{fermentation_hours_elapsed}', context.fermentationHoursElapsed.toStringAsFixed(1))
        .replaceAll('{rain_probability_pct}',  context.rainProbabilityPct.toString())
        .replaceAll('{roast_days}',            context.roastDays.toString())
        .replaceAll('{bloom_seconds}',         _calcBloomSeconds(context).toString());

    // Añadir nivel de confianza si es barista/procesador y confianza < 0.75
    if (confidence < 0.75 &&
        context.userRole != UserRole.farmer) {
      explanation += '\n(Confianza: ${(confidence * 100).round()}% — '
          'algunos datos no están disponibles)';
    }

    return explanation;
  }

  String _prettyVariety(String id) => switch (id) {
    'var_geisha'   => 'Geisha',
    'var_castillo' => 'Castillo',
    'var_caturra'  => 'Caturra',
    'var_bourbon'  => 'Bourbon',
    _              => id.replaceAll('var_', '').capitalize(),
  };

  String _prettyProcess(String id) => switch (id) {
    'lavado'           => 'Lavado',
    'natural'          => 'Natural',
    'anaerobic_lactic' => 'Anaeróbico láctico',
    'honey_yellow'     => 'Honey amarillo',
    _                  => id,
  };

  int _calcBloomSeconds(AIContext ctx) {
    int base = 35;
    if (ctx.roastDays <= 7)  base += 20;
    else if (ctx.roastDays <= 14) base += 10;
    return base;
  }
}
```

---

## 11. Evolución a Machine Learning

### Fase actual (v1.0) → ML (v2.0): qué cambia y qué no

```
LO QUE NO CAMBIA:
  ✅ El contrato InferenceAdapter — la UI y use cases no saben
     si el motor es rule-based o ML
  ✅ El AIContext como estructura de input
  ✅ El Recommendation como estructura de output
  ✅ El AlertEngine — sigue siendo rule-based (más predecible)

LO QUE CAMBIA:
  InferenceAdapter implementación:
    v1.0: RuleBasedInferenceAdapter
    v2.0: TFLiteInferenceAdapter (con fallback a rules)
```

### Feature engineering para el modelo ML

```python
# scripts/ml/feature_engineering.py
# Cómo se preparan los datos de Firestore para entrenar el modelo

import pandas as pd
from sklearn.preprocessing import LabelEncoder

def build_feature_matrix(lots_df, readings_df):
    """
    Construye la matriz de features para el modelo de predicción de SCA.
    Solo lotes con sca_evaluation y todos los campos completos.
    """

    features = pd.DataFrame()

    # ── Features de finca ────────────────────────────────────────
    features['altitude_masl'] = lots_df['altitude_masl']

    le_variety = LabelEncoder()
    features['variety_encoded'] = le_variety.fit_transform(lots_df['variety_id'])

    le_process = LabelEncoder()
    features['process_encoded'] = le_process.fit_transform(lots_df['process_type'])

    # ── Features de cosecha ──────────────────────────────────────
    features['brix_level']        = lots_df['harvest_brix']
    features['cherry_color_pct']  = lots_df['harvest_color_pct']
    features['defect_pct']        = lots_df['harvest_defect_pct']

    # ── Features de fermentación (agregados) ─────────────────────
    ferm_agg = readings_df.groupby('lot_id').agg(
        ph_mean=('ph_value', 'mean'),
        ph_min=('ph_value', 'min'),
        ph_final=('ph_value', 'last'),
        temp_mean=('mucilago_temp_c', 'mean'),
        temp_max=('mucilago_temp_c', 'max'),
        duration_hours=('hours_elapsed', 'max'),
    ).reset_index()

    features = features.merge(ferm_agg, left_on='lot_id', right_on='lot_id')

    # ── Features ambientales ─────────────────────────────────────
    features['ambient_temp_at_ferm'] = lots_df['ferm_ambient_temp']
    features['humidity_at_ferm']     = lots_df['ferm_ambient_humidity']

    # ── Features de secado ───────────────────────────────────────
    features['drying_days']          = lots_df['drying_actual_days']
    features['humidity_final']       = lots_df['drying_humidity_final']
    le_drying = LabelEncoder()
    features['drying_method']        = le_drying.fit_transform(lots_df['drying_method'])

    # ── Feature de adherencia a IA ───────────────────────────────
    features['ai_adherence_ratio']   = lots_df['ai_recommendations_followed_pct']

    # ── Target ───────────────────────────────────────────────────
    target = lots_df['sca_score']

    return features, target


# Resultado: ~25 features → modelo GradientBoosting o XGBoost
# Con ~3.000 lotes: MAE esperado < 2.5 puntos SCA
# Con ~10.000 lotes: MAE < 1.5 puntos SCA
```

### Modelo TFLite en Flutter (v2.0)

```dart
// lib/ai_engine/adapters/tflite_inference_adapter.dart

class TFLiteInferenceAdapter implements InferenceAdapter {
  final Interpreter _interpreter;
  final RuleBasedInferenceAdapter _fallback;
  final FeatureExtractor _featureExtractor;

  @override
  bool get supportsOfflineInference => true;  // el modelo está en el bundle

  @override
  Future<QualityPrediction> predictSCAScore(LotContext context) async {
    try {
      // 1. Extraer los 25 features en el orden que espera el modelo
      final features = _featureExtractor.extract(context);  // Float32List

      // 2. Preparar tensores de entrada y salida
      final input = [features];
      final output = List.filled(1, 0.0).reshape([1, 1]);

      // 3. Inferencia en dispositivo (< 10ms)
      _interpreter.run(input, output);

      final predictedScore = output[0][0] as double;
      final confidence = _calculateConfidence(context, features);

      return QualityPrediction(
        predictedSca: predictedScore.clamp(60.0, 100.0),
        confidenceScore: confidence,
        modelVersion: 'tflite_v2.1',
      );
    } catch (e) {
      // Si el modelo falla, fallback transparente al rule engine
      return _fallback.predictSCAScore(context);
    }
  }

  // La confianza del modelo ML se basa en qué tan parecido
  // es este lote al dataset de entrenamiento (out-of-distribution detection)
  double _calculateConfidence(LotContext context, Float32List features) {
    // Implementación simplificada — en producción: Mahalanobis distance
    // al centroide del training set
    double confidence = 0.85;
    if (context.lot.varietyId == 'var_unknown') confidence -= 0.15;
    if (context.fermentationReadings.length < 4) confidence -= 0.10;
    return confidence.clamp(0.30, 0.95);
  }
}
```

### Roadmap de IA: cuándo activar ML

```
CRITERIO DE ACTIVACIÓN ML:

  Cuantitativo:
    ✅ >= 3.000 lotes cerrados con sca_evaluation de Q Grader
    ✅ MAE en validación cruzada < 2.5 puntos SCA
    ✅ Cobertura de variedades > 80% de las usadas en producción

  Cualitativo:
    ✅ El modelo supera al rule engine en >= 60% de los casos de prueba
    ✅ El modelo no alucina (no predice 95+ pts en lotes de baja calidad)
    ✅ Explicabilidad aceptable (SHAP values disponibles en backend)

  Estrategia de rollout:
    Semana 1: ML activo para 5% de usuarios (A/B test)
    Semana 3: Comparar MAE real ML vs rule engine
    Semana 6: Si ML gana, ampliar a 50%
    Semana 10: 100% con rule engine como fallback permanente

  EL RULE ENGINE NUNCA SE ELIMINA:
    → Fallback cuando el modelo falla
    → Alertas críticas (más predecible que ML para casos extremos)
    → Nuevas variedades o regiones sin datos suficientes
```

---

## Resumen del motor

```
PRODUCCIÓN:
  Módulo harvest      → 3 reglas (go/no-go cosecha, urgencia por lluvia)
  Módulo process_sel. → 3 reglas (lavado, anaeróbico, natural)
  Módulo fermentation → 7 reglas (4 alertas + 2 orientación + 1 proyección)
  Módulo drying       → 3 reglas (target, sobredesecado, progreso lento)
  Total MVP producción: ~20 reglas base (+180 variantes por proceso)

PREPARACIÓN:
  Recipe generator    → 6 ajustes algorítmicos (no reglas — lógica continua)
  Diagnosis module    → 3 reglas (sobre/sub/óptima extracción)
  Total MVP brewing:  ~12 reglas + recipe generator

ALERTENGINE (umbrales directos):
  Fermentación: 3 procesos × (2 pH + 2 temp) = 12 umbrales
  Secado: 3 umbrales (objetivo, sobredesecado, progreso)
  Evaluación: < 1ms por lectura

TIEMPO DE EVALUACIÓN COMPLETA (rule engine):
  < 5ms en dispositivo mid-range Android
  Sin llamadas HTTP — 100% offline
```

---

*Próximo paso: implementar el ContextBuilder que ensambla el AIContext desde los repositorios locales y conectar el RuleEngine con los Riverpod providers definidos en la arquitectura.*

**Autor:** AI Engineer | SpecialCoffee AI
