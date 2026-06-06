// ignore_for_file: avoid_print
//
// Ejemplos ejecutables del motor de IA.
// Correr con: dart lib/ai_engine/examples/engine_examples.dart
//
// Los 4 ejemplos corresponden exactamente a los casos documentados en RULE_ENGINE.md.

import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/ai_engine/core/alert_engine.dart';
import 'package:special_coffee/ai_engine/core/brew_recipe_generator.dart';
import 'package:special_coffee/ai_engine/core/conflict_resolver.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/evaluators/condition_evaluator.dart';
import 'package:special_coffee/ai_engine/evaluators/confidence_adjuster.dart';
import 'package:special_coffee/ai_engine/evaluators/explanation_builder.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/alert.dart';
import 'package:special_coffee/ai_engine/rules/all_rules.dart';

Future<void> main() async {
  // Ensamblar el motor sin Flutter (puro Dart para testing/ejemplos)
  final ruleEngine = RuleEngine(
    evaluator: ConditionEvaluator(),
    explanationBuilder: ExplanationBuilder(),
    conflictResolver: ConflictResolver(),
    confidenceAdjuster: ConfidenceAdjuster(),
  );
  ruleEngine.loadRules(AllRules.all, version: AllRules.version);

  final brewGenerator = BrewRecipeGenerator();
  final alertEngine = AlertEngine();

  _printDivider('MOTOR DE IA — SPECIALCOFFEE v${AllRules.version}');
  print('Reglas cargadas: ${ruleEngine.rulesCount}');

  await _example1_processSelection(ruleEngine);
  await _example2_fermentationCritical(ruleEngine, alertEngine);
  await _example3_brewRecipe(brewGenerator, ruleEngine);
  await _example4_postExtractionDiagnosis(ruleEngine);
}

// ── EJEMPLO 1: Selección de proceso — Geisha 1920m ───────────────────────────
Future<void> _example1_processSelection(RuleEngine engine) async {
  _printDivider('EJEMPLO 1 — Selección de proceso (Geisha, 1920 msnm)');

  final context = const AIContext(
    userId: 'user_001',
    userRole: UserRole.producer,
    module: 'process_selection',
    varietyId: 'var_geisha',
    altitudeMasl: 1920,
    region: 'Huila',
    ambientTempC: 16.0,
    ambientHumidityPct: 82.0,
    rainProbabilityPct: 8.0,
    varietySensitivity: 'very_high',
    varietyScaPotential: 89.5,
    userLotsCompleted: 8,
  );

  final recommendations = engine.evaluate(context);

  if (recommendations.isEmpty) {
    print('Sin recomendaciones para este contexto.');
    return;
  }

  for (final rec in recommendations) {
    _printRecommendation(rec);
  }

  // SALIDA ESPERADA:
  // action:      SELECT_PROCESS_ANAEROBIC
  // confidence:  0.87 (0.84 base + 0.03 por userLotsCompleted > 5)
  // alertLevel:  none
  // explanation: "Variedad de alta complejidad (Geisha) a 1920 msnm..."
}

// ── EJEMPLO 2: Alerta crítica de fermentación (2am, pH 3.4) ─────────────────
Future<void> _example2_fermentationCritical(
    RuleEngine engine, AlertEngine alertEngine) async {
  _printDivider('EJEMPLO 2 — Alerta crítica: pH 3.4 en lavado activo');

  // AlertEngine primero — evaluación < 1ms
  final immediateAlerts = alertEngine.evaluateFermentationReading(
    ph: 3.4,
    mucilagoTemp: 28.5,
    processType: 'lavado',
    lotId: 'lot_abc123',
  );

  print('── AlertEngine (evaluación inmediata):');
  for (final alert in immediateAlerts) {
    print(
      '   [${alert.level.name.toUpperCase()}] ${alert.type.name} — '
      'valor: ${alert.triggerValue} / umbral: ${alert.threshold}',
    );
  }

  // RuleEngine — contexto completo
  final context = const AIContext(
    userId: 'user_001',
    userRole: UserRole.producer,
    module: 'fermentation',
    varietyId: 'var_castillo',
    altitudeMasl: 1650,
    region: 'Nariño',
    ambientTempC: 22.0,
    ambientHumidityPct: 75.0,
    processType: 'lavado',
    fermentationStatus: 'active',
    fermentationHoursElapsed: 28.5,
    currentPh: 3.4,
    mucilagoTempC: 28.5,
    userLotsCompleted: 12,
  );

  final recommendations = engine.evaluate(context);
  print('\n── RuleEngine (recomendaciones ordenadas):');
  for (final rec in recommendations) {
    _printRecommendation(rec);
  }

  // Proyección de tiempo final
  final readings = [
    const FermentationReading(hoursElapsed: 20.0, phValue: 5.8, tempC: 24.0),
    const FermentationReading(hoursElapsed: 22.0, phValue: 5.1, tempC: 25.0),
    const FermentationReading(hoursElapsed: 24.0, phValue: 4.3, tempC: 27.0),
    const FermentationReading(hoursElapsed: 28.5, phValue: 3.4, tempC: 28.5),
  ];
  final projection = alertEngine.projectFermentationEndHours(
    readings: readings,
    targetPhMin: 4.0,
  );
  print(
    '\n── Proyección de fin (regresión lineal): '
    '${projection != null ? '${projection.toStringAsFixed(1)}h restantes' : 'no disponible (pH ya superó el umbral)'}',
  );

  // SALIDA ESPERADA:
  // AlertEngine: CRITICAL phCritical — 3.4 / 3.5 + WARNING tempHigh — 28.5 / 27.0
  // RuleEngine [0]: STOP_FERMENTATION_IMMEDIATELY, priority=1, confidence=0.97
  // RuleEngine [1]: REDUCE_TEMPERATURE, priority=2, confidence=0.87
  // Proyección: null (pH ya pasó el punto crítico — acción inmediata requerida)
}

// ── EJEMPLO 3: Receta V60 para barista en Bogotá ─────────────────────────────
Future<void> _example3_brewRecipe(
    BrewRecipeGenerator generator, RuleEngine engine) async {
  _printDivider('EJEMPLO 3 — Receta V60: Bogotá (2600 msnm), Geisha anaeróbico, 12 días');

  final context = const AIContext(
    userId: 'user_002',
    userRole: UserRole.barista,
    module: 'brewing',
    varietyId: 'var_geisha',
    altitudeMasl: 2600,
    region: 'Bogotá',
    ambientTempC: 15.0,
    ambientHumidityPct: 68.0,
    processType: 'anaerobic_lactic',
    brewMethod: 'v60',
    roastLevel: 'light',
    roastDays: 12,
    waterHardnessPpm: 120.0,
    userSweetnessWeight: 0.82,
    userPreferredTdsMin: 1.30,
    userPreferredTdsMax: 1.38,
    userLotsCompleted: 45,
  );

  // Receta algorítmica
  final recipe = generator.generate(context);

  print('── BrewRecipeGenerator output:');
  print('   Método:          ${recipe.method.toUpperCase()}');
  print('   Dosis:           ${recipe.doseG}g café / ${recipe.waterG.toStringAsFixed(0)}g agua');
  print('   Ratio:           1:${recipe.ratio.toStringAsFixed(1)}');
  print('   Temperatura:     ${recipe.waterTempC}°C');
  print('   Bloom:           ${recipe.bloomG.toStringAsFixed(0)}g × ${recipe.bloomSeconds}s');
  print('   TDS objetivo:    ${recipe.tdsTargetMin}–${recipe.tdsTargetMax}%');
  print('   Ajustes aplicados:');
  for (final adj in recipe.adjustmentsApplied) {
    print('     • $adj');
  }

  // RuleEngine — reglas adicionales de context
  final recommendations = engine.evaluate(context);
  if (recommendations.isNotEmpty) {
    print('\n── Reglas activas sobre este brewing:');
    for (final rec in recommendations) {
      _printRecommendation(rec);
    }
  }

  // SALIDA ESPERADA:
  // Temperatura: 88°C (91 base → 89.3 por altitud → 88.3 por anaeróbico → 88)
  // Bloom: 45s (35 base + 10 por 12 días de tueste ≤ 14)
  // Ratio: 1:15.0 (15.5 base - 0.5 por sweetness 0.82 > 0.7)
  // Water: 20g × 15.0 = 300g
  // Bloom water: 20g × 2.5 = 50g
}

// ── EJEMPLO 4: Diagnóstico post-extracción ───────────────────────────────────
Future<void> _example4_postExtractionDiagnosis(RuleEngine engine) async {
  _printDivider('EJEMPLO 4 — Diagnóstico: TDS 1.52%, rendimiento 23.4%');

  final context = const AIContext(
    userId: 'user_002',
    userRole: UserRole.barista,
    module: 'brewing',
    varietyId: 'var_geisha',
    altitudeMasl: 2600,
    region: 'Bogotá',
    ambientTempC: 15.0,
    ambientHumidityPct: 68.0,
    brewMethod: 'v60',
    measuredTdsPct: 1.52,
    measuredYieldPct: 23.4,
    userPreferredTdsMin: 1.30,
    userPreferredTdsMax: 1.38,
    userLotsCompleted: 45,
  );

  final recommendations = engine.evaluate(context);

  print('── Diagnóstico RuleEngine:');
  for (final rec in recommendations) {
    _printRecommendation(rec);
  }

  // SALIDA ESPERADA:
  // action:   DIAGNOSE_OVER_EXTRACTION (OR: yield 23.4 > 23.0 → activa)
  // confidence: 0.92 (0.90 base + 0.02 por userLotsCompleted > 20)
  // suggestedActions: [Molienda +1.5 clicks, Reducir temp 1°C, ...]
  // explanation: "TDS 1.52% supera tu objetivo (1.38%). Sobreextracción..."
}

// ── Helpers de presentación ───────────────────────────────────────────────────
void _printRecommendation(dynamic rec) {
  print('\n   ┌─ [${rec.alertLevel.name.toUpperCase()}] ${rec.action}');
  print('   │  Regla:       ${rec.ruleId}');
  print('   │  Confianza:   ${(rec.confidence * 100).toStringAsFixed(0)}%');
  print('   │  Explicación: ${rec.explanation}');
  if ((rec.suggestedActions as List).isNotEmpty) {
    print('   │  Acciones:');
    for (final action in rec.suggestedActions as List) {
      print('   │    • $action');
    }
  }
  if ((rec.parameters as Map).isNotEmpty) {
    print('   │  Parámetros: ${rec.parameters}');
  }
  print('   └─────────────────────────────────────────');
}

void _printDivider(String title) {
  print('\n');
  print('═' * 60);
  print('  $title');
  print('═' * 60);
}
