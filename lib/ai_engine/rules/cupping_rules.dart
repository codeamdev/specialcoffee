import 'package:special_coffee/ai_engine/models/ai_rule.dart';

abstract final class CuppingRules {
  static List<AIRule> get all => [
    // ── OUTSTANDING ≥ 90 ─────────────────────────────────────────────────────
    const AIRule(
      id: 'CUP-OUTSTANDING-001',
      module: 'cupping',
      name: 'Catación Outstanding (≥ 90 pts)',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['cupping', 'quality', 'outstanding'],
      conditions: [
        RuleCondition(
          variable: 'sca_total_score',
          operator: ConditionOperator.gte,
          threshold: 90.0,
        ),
      ],
      outcome: RuleOutcome(
        action: 'CUPPING_OUTSTANDING',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.95,
        explanationByRole: {
          'farmer':    '✅ Puntaje Outstanding (≥ 90 pts). Documenta cada detalle de este proceso — es un referente para replicar.',
          'processor': '✅ Lote Outstanding. Registra parámetros exactos de fermentación, despulpado y secado para replicar este resultado.',
          'barista':   '✅ Puntaje Outstanding. Diseña recetas que resalten los atributos más altos de este lote.',
        },
        suggestedActions: [
          'Documenta el proceso completo con fotos y notas',
          'Considera certificar este lote como specialty premium',
          'Guarda muestras de referencia para comparación futura',
        ],
      ),
    ),

    // ── SPECIALTY 80–89.75 ────────────────────────────────────────────────────
    const AIRule(
      id: 'CUP-SPECIALTY-001',
      module: 'cupping',
      name: 'Catación Specialty (80–89 pts)',
      priority: 2,
      logic: RuleLogic.and,
      tags: ['cupping', 'quality', 'specialty'],
      conditions: [
        RuleCondition(
          variable: 'sca_total_score',
          operator: ConditionOperator.between,
          threshold: 80.0,
          thresholdMax: 89.75,
        ),
      ],
      outcome: RuleOutcome(
        action: 'CUPPING_SPECIALTY',
        alertLevel: AlertLevel.info,
        confidenceBase: 0.92,
        explanationByRole: {
          'farmer':    '☕ Lote specialty (≥ 80 pts). Revisa el atributo con menor puntaje — ahí está la oportunidad de mejora para el próximo lote.',
          'processor': '☕ Lote specialty. Compara parámetros de este lote con los de puntajes más altos para identificar brechas de proceso.',
          'barista':   '☕ Lote specialty. Extrae resaltando los atributos con mayor puntaje; ajusta temperatura y tiempo según acidez y cuerpo.',
        },
        suggestedActions: [
          'Identifica el atributo SCA con menor puntaje',
          'Ajusta esa etapa del proceso en el próximo lote',
        ],
      ),
    ),

    // ── BELOW SPECIALTY < 80 ─────────────────────────────────────────────────
    const AIRule(
      id: 'CUP-BELOW-SPECIALTY-001',
      module: 'cupping',
      name: 'Catación bajo specialty (< 80 pts)',
      priority: 1,
      logic: RuleLogic.and,
      tags: ['cupping', 'quality', 'below-specialty'],
      conditions: [
        RuleCondition(
          variable: 'sca_total_score',
          operator: ConditionOperator.lt,
          threshold: 80.0,
        ),
      ],
      outcome: RuleOutcome(
        action: 'CUPPING_BELOW_SPECIALTY',
        alertLevel: AlertLevel.warning,
        confidenceBase: 0.90,
        explanationByRole: {
          'farmer':    '⚠️ Puntaje por debajo de 80 pts. Revisa el proceso desde cosecha: madurez de cereza, tiempos de fermentación y secado.',
          'processor': '⚠️ Lote bajo specialty. Analiza qué atributo tuvo mayor penalización y correla con los parámetros de proceso registrados.',
          'barista':   '⚠️ Puntaje bajo specialty. Evalúa si los defectos son de proceso o extracción antes de descartar el lote.',
        },
        suggestedActions: [
          'Revisa el registro de cosecha: color y madurez de cereza',
          'Evalúa tiempos y temperatura de fermentación',
          'Verifica humedad final de secado',
          'Realiza un segundo cupping variando parámetros de extracción',
        ],
      ),
    ),
  ];
}
