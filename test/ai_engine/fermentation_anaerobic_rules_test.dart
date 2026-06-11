import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/fermentation_rules.dart';

import '../helpers/test_context.dart';

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
    engine.loadRules(FermentationRules.all);
  });

  AIContext anaCtx({
    double ph           = 4.0,
    double tempC        = 15.0,
    double hoursElapsed = 50.0,
  }) =>
      ctx(module: 'fermentation', processType: 'anaerobic_lactic').copyWith(
        currentPh:                 ph,
        mucilagoTempC:             tempC,
        fermentationHoursElapsed:  hoursElapsed,
        fermentationStatus:        'active',
      );

  // ── FERM-ANAEROBIC-PH-CRITICAL-001 ──────────────────────────────────────

  group('FERM-ANAEROBIC-PH-CRITICAL-001 — pH crítico anaeróbico', () {
    test('dispara con pH 3.2 (sobrefermentación láctica)', () {
      final results = engine.evaluate(anaCtx(ph: 3.2));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-PH-CRITICAL-001'), isTrue);
    });

    test('nivel de alerta es critical', () {
      final results = engine.evaluate(anaCtx(ph: 3.0));
      final r = results.firstWhere((r) => r.ruleId == 'FERM-ANAEROBIC-PH-CRITICAL-001');
      expect(r.alertLevel, AlertLevel.critical);
    });

    test('no dispara con pH 3.8 (zona de atención, no crítico)', () {
      final results = engine.evaluate(anaCtx(ph: 3.8));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-PH-CRITICAL-001'), isFalse);
    });

    test('no dispara en proceso lavado con pH bajo', () {
      final notAnaerobic = ctx(module: 'fermentation', processType: 'lavado').copyWith(
        currentPh:          3.2,
        fermentationStatus: 'active',
      );
      final results = engine.evaluate(notAnaerobic);
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-PH-CRITICAL-001'), isFalse);
    });
  });

  // ── FERM-ANAEROBIC-PH-WARN-001 ──────────────────────────────────────────

  group('FERM-ANAEROBIC-PH-WARN-001 — pH zona de atención anaeróbico', () {
    test('dispara con pH 3.6 (entre 3.5 y 3.8)', () {
      final results = engine.evaluate(anaCtx(ph: 3.6));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-PH-WARN-001'), isTrue);
    });

    test('nivel de alerta es high', () {
      final results = engine.evaluate(anaCtx(ph: 3.7));
      final r = results.firstWhere((r) => r.ruleId == 'FERM-ANAEROBIC-PH-WARN-001');
      expect(r.alertLevel, AlertLevel.high);
    });

    test('no dispara con pH 4.2 (fuera de la zona de atención)', () {
      final results = engine.evaluate(anaCtx(ph: 4.2));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-PH-WARN-001'), isFalse);
    });

    test('no dispara con pH 3.4 (ya es crítico, cubre la regla critical)', () {
      final results = engine.evaluate(anaCtx(ph: 3.4));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-PH-WARN-001'), isFalse);
    });
  });

  // ── FERM-ANAEROBIC-TEMP-HIGH-001 ────────────────────────────────────────

  group('FERM-ANAEROBIC-TEMP-HIGH-001 — temperatura alta en anaeróbico', () {
    test('dispara con 22°C en anaeróbico', () {
      final results = engine.evaluate(anaCtx(tempC: 22.0));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-TEMP-HIGH-001'), isTrue);
    });

    test('nivel de alerta es warning', () {
      final results = engine.evaluate(anaCtx(tempC: 25.0));
      final r = results.firstWhere((r) => r.ruleId == 'FERM-ANAEROBIC-TEMP-HIGH-001');
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('no dispara con temperatura ideal de 15°C', () {
      final results = engine.evaluate(anaCtx(tempC: 15.0));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-TEMP-HIGH-001'), isFalse);
    });
  });

  // ── FERM-ANAEROBIC-TIME-MIN-001 ──────────────────────────────────────────

  group('FERM-ANAEROBIC-TIME-MIN-001 — tiempo mínimo anaeróbico', () {
    test('dispara con 24h (aún por debajo de las 48h mínimas)', () {
      final results = engine.evaluate(anaCtx(hoursElapsed: 24.0));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-TIME-MIN-001'), isTrue);
    });

    test('no dispara con 0.0h (valor por defecto — sin datos)', () {
      final results = engine.evaluate(anaCtx(hoursElapsed: 0.0));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-TIME-MIN-001'), isFalse);
    });

    test('no dispara con 48h o más (tiempo mínimo cumplido)', () {
      final results = engine.evaluate(anaCtx(hoursElapsed: 48.0));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-TIME-MIN-001'), isFalse);
    });

    test('dispara con 0.1h (primer registro justo iniciado)', () {
      final results = engine.evaluate(anaCtx(hoursElapsed: 0.1));
      expect(results.any((r) => r.ruleId == 'FERM-ANAEROBIC-TIME-MIN-001'), isTrue);
    });
  });
}
