import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class ClassificationRules {
  static List<AIRule> get all => [
    // ── BRIX CEREZA CRÍTICO ───────────────────────────────────────────────────
    const AIRule(
      id: 'CLAS-BRIX-CRITICAL-001',
      module: 'classification',
      name: 'Brix cereza crítico — no procesar',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['brix', 'classification', 'critical'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.lt, threshold: CoffeeThresholds.brixCriticalMax),
      ],
      outcome: RuleOutcome(
        action: 'STOP_PROCESS',
        alertLevel: AlertLevel.critical,
        confidenceBase: 0.97,
        explanationByRole: {
          'farmer': '🚫 Brix {brix_level}° — cereza inmadura. No iniciar proceso: el lote producirá café amargo y sin cuerpo.',
          'processor': '🚫 Brix {brix_level}° crítico. Azúcares insuficientes para fermentación viable — detener proceso.',
          'barista': '🚫 Brix {brix_level}° — subdesarrollo severo confirmado en clasificación. Taza sin dulzura garantizada.',
        },
        suggestedActions: [
          'No iniciar fermentación ni secado con este lote',
          'Considerar mezcla con cerezas de mayor madurez si es posible',
          'Documentar para rastrear problema de cosecha',
        ],
        parameters: {},
      ),
    ),

    // ── BRIX CEREZA BAJO ─────────────────────────────────────────────────────
    const AIRule(
      id: 'CLAS-BRIX-LOW-001',
      module: 'classification',
      name: 'Brix cereza bajo — proceso con precaución',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['brix', 'classification', 'warning'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.between, threshold: CoffeeThresholds.brixLowMin, thresholdMax: CoffeeThresholds.brixLowMax),
      ],
      outcome: RuleOutcome(
        action: 'PROCESS_WITH_CAUTION',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.86,
        explanationByRole: {
          'farmer': '⚠️ Brix {brix_level}° bajo. El café puede quedar con menos dulzura de lo esperado.',
          'processor': '⚠️ Brix {brix_level}° subóptimo. Considerar fermentación más corta para minimizar degradación de azúcares.',
          'barista': '⚠️ Brix {brix_level}° — subdesarrollo moderado. Esperar perfil con menos dulzura y posible astringencia.',
        },
        suggestedActions: [
          'Acortar tiempo de fermentación 10–20% respecto al estándar',
          'Monitorear pH más frecuentemente durante fermentación',
          'Documentar resultado para correlacionar con taza final',
        ],
        parameters: {'fermentation_adjustment_pct': -15},
      ),
    ),

    // ── BRIX CEREZA ÓPTIMO ────────────────────────────────────────────────────
    const AIRule(
      id: 'CLAS-BRIX-OPTIMAL-001',
      module: 'classification',
      name: 'Brix cereza óptimo — proceder',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['brix', 'classification', 'go'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.between, threshold: CoffeeThresholds.brixOptimalMin, thresholdMax: CoffeeThresholds.brixOptimalMax),
      ],
      outcome: RuleOutcome(
        action: 'PROCEED_TO_PROCESS',
        alertLevel: AlertLevel.none,
        confidenceBase: 0.93,
        explanationByRole: {
          'farmer': '✅ Brix {brix_level}° — rango specialty. Lote listo para procesar.',
          'processor': '✅ Brix {brix_level}° en rango óptimo (18–24°). Iniciar proceso según plan.',
          'barista': '✅ Brix {brix_level}° — madurez confirmada. Esperar perfil dulce con buena complejidad.',
        },
        suggestedActions: [
          'Iniciar proceso planificado en las próximas 4–6 horas',
          'Mantener cerezas a la sombra hasta inicio del proceso',
        ],
        parameters: {'max_wait_hours': 6},
      ),
    ),

    // ── BRIX CEREZA ALTO — sobremadurez ──────────────────────────────────────
    const AIRule(
      id: 'CLAS-BRIX-HIGH-001',
      module: 'classification',
      name: 'Brix alto — sobremadurez, procesar urgente',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['brix', 'classification', 'overripe'],
      conditions: [
        RuleCondition(variable: 'brix_level', operator: ConditionOperator.gt, threshold: CoffeeThresholds.brixOptimalMax),
      ],
      outcome: RuleOutcome(
        action: 'PROCESS_URGENT',
        alertLevel: AlertLevel.high,
        confidenceBase: 0.88,
        explanationByRole: {
          'farmer': '⚠️ Brix {brix_level}° — sobremadurez. Iniciar proceso hoy para evitar fermentación indeseada.',
          'processor': '⚠️ Brix {brix_level}° supera 24°. Sobremadurez activa — procesar en máximo 2 horas.',
          'barista': '⚠️ Brix {brix_level}° elevado. Riesgo de notas fermentadas indeseadas si se demora el proceso.',
        },
        suggestedActions: [
          'Iniciar proceso en menos de 2 horas',
          'Separar cerezas muy blandas o con manchas oscuras',
          'Considerar proceso natural corto si la infraestructura lo permite',
        ],
        parameters: {'max_wait_hours': 2},
      ),
    ),

    // ── FLOTACIÓN ALTA — advertencia ─────────────────────────────────────────
    // D-5: umbral 20% estimado — calibrar con Cenicafé / FNC.
    const AIRule(
      id: 'CLAS-FLOAT-WARN-001',
      module: 'classification',
      name: 'Flotación elevada — revisar cosecha',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['flotation', 'classification', 'warning'],
      conditions: [
        RuleCondition(variable: 'flotation_float_pct', operator: ConditionOperator.gte, threshold: CoffeeThresholds.flotationWarnPct),
      ],
      outcome: RuleOutcome(
        action: 'REVIEW_HARVEST_QUALITY',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.80,
        explanationByRole: {
          'farmer': '⚠️ El {flotation_float_pct}% de las cerezas flotaron. Más del 20% puede indicar problema en la cosecha.',
          'processor': '⚠️ Flotación {flotation_float_pct}% — alto. Revisar prácticas de cosecha para próximo pase.',
          'barista': '⚠️ Flotación elevada sugiere cerezas defectuosas. Monitorear taza para defectos.',
        },
        suggestedActions: [
          'Revisar selectividad de recolectores en próximo pase',
          'Verificar si hay problema de broca o enfermedad en la parcela',
          'Documentar tasa de flotación para rastrear tendencia',
        ],
        parameters: {'flotation_warn_pct': CoffeeThresholds.flotationWarnPct},
      ),
    ),

    // ── FLOTACIÓN CRÍTICA ─────────────────────────────────────────────────────
    // D-5: umbral 35% estimado — calibrar con Cenicafé / FNC.
    const AIRule(
      id: 'CLAS-FLOAT-CRITICAL-001',
      module: 'classification',
      name: 'Flotación crítica — calidad de campo comprometida',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['flotation', 'classification', 'critical'],
      conditions: [
        RuleCondition(variable: 'flotation_float_pct', operator: ConditionOperator.gte, threshold: CoffeeThresholds.flotationCriticalPct),
      ],
      outcome: RuleOutcome(
        action: 'ALERT_HARVEST_QUALITY',
        alertLevel: AlertLevel.critical,
        confidenceBase: 0.85,
        explanationByRole: {
          'farmer': '🔴 El {flotation_float_pct}% de las cerezas son defectuosas. Revisar urgentemente el estado del cafetal.',
          'processor': '🔴 Flotación {flotation_float_pct}% — crítico. Problema sistémico de calidad en campo.',
          'barista': '🔴 Flotación crítica: lote de alto riesgo. Evaluar si continuar procesamiento.',
        },
        suggestedActions: [
          'Inspeccionar parcela por broca, roya u otras enfermedades',
          'Considerar si vale la pena procesar el lote restante',
          'Notificar al agrónomo de finca',
        ],
        parameters: {'flotation_critical_pct': CoffeeThresholds.flotationCriticalPct},
      ),
    ),

    // ── APROVECHAMIENTO BAJO ──────────────────────────────────────────────────
    // D-5: umbral 60% estimado — calibrar. NO confundir con rendimiento de trilla
    // (kg pergamino seco / kg cereza ≈ 18–22%) que corresponde al Ítem #9.
    const AIRule(
      id: 'CLAS-APROVECH-BAJO-001',
      module: 'classification',
      name: 'Eficiencia de clasificación baja',
      priority: 3,
      logic: RuleLogic.and,
      tags: ['yield', 'classification', 'warning'],
      conditions: [
        RuleCondition(variable: 'pct_aprovechamiento', operator: ConditionOperator.lt, threshold: CoffeeThresholds.aprovechamientoMinPct),
      ],
      outcome: RuleOutcome(
        action: 'REVIEW_CLASSIFICATION_EFFICIENCY',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.78,
        explanationByRole: {
          'farmer': '⚠️ Solo el {pct_aprovechamiento}% de las cerezas pasaron clasificación. Revisar calidad de cosecha.',
          'processor': '⚠️ Eficiencia de clasificación {pct_aprovechamiento}% — por debajo del 60% esperado.',
          'barista': '⚠️ Alta tasa de descarte. El lote procesado tiene mejor calidad, pero revisar causa raíz.',
        },
        suggestedActions: [
          'Analizar si el descarte fue por flotación o selección manual',
          'Revisar madurez promedio en la próxima cosecha',
          'Documentar para comparar con lotes anteriores',
        ],
        parameters: {'aprovechamiento_min_pct': CoffeeThresholds.aprovechamientoMinPct},
      ),
    ),
  ];
}
