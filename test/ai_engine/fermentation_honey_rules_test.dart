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

  AIContext honeyCtx({
    double tempC         = 22.0,
    double hoursElapsed  = 24.0,
    String mucilageState = 'liquid',
  }) =>
      ctx(module: 'fermentation', processType: 'honey_yellow').copyWith(
        mucilagoTempC:             tempC,
        fermentationHoursElapsed:  hoursElapsed,
        mucilageState:             mucilageState,
        fermentationStatus:        'active',
      );

  // ── FERM-HONEY-TEMP-HIGH-001 ─────────────────────────────────────────────

  group('FERM-HONEY-TEMP-HIGH-001 — temperatura alta en honey', () {
    test('dispara con mucílago a 29°C en honey', () {
      final results = engine.evaluate(honeyCtx(tempC: 29.0));
      expect(results.any((r) => r.ruleId == 'FERM-HONEY-TEMP-HIGH-001'), isTrue);
    });

    test('nivel de alerta es warning', () {
      final results = engine.evaluate(honeyCtx(tempC: 30.0));
      final r = results.firstWhere((r) => r.ruleId == 'FERM-HONEY-TEMP-HIGH-001');
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('no dispara con temperatura normal de 25°C', () {
      final results = engine.evaluate(honeyCtx(tempC: 25.0));
      expect(results.any((r) => r.ruleId == 'FERM-HONEY-TEMP-HIGH-001'), isFalse);
    });

    test('no dispara en proceso lavado aunque la temp sea alta', () {
      final lavadoCtx = ctx(module: 'fermentation', processType: 'lavado').copyWith(
        mucilagoTempC:      30.0,
        fermentationStatus: 'active',
      );
      final results = engine.evaluate(lavadoCtx);
      expect(results.any((r) => r.ruleId == 'FERM-HONEY-TEMP-HIGH-001'), isFalse);
    });
  });

  // ── FERM-HONEY-TIME-LONG-001 ─────────────────────────────────────────────

  group('FERM-HONEY-TIME-LONG-001 — tiempo excesivo en honey', () {
    test('dispara con 100h en honey', () {
      final results = engine.evaluate(honeyCtx(hoursElapsed: 100.0));
      expect(results.any((r) => r.ruleId == 'FERM-HONEY-TIME-LONG-001'), isTrue);
    });

    test('nivel de alerta es warning', () {
      final results = engine.evaluate(honeyCtx(hoursElapsed: 120.0));
      final r = results.firstWhere((r) => r.ruleId == 'FERM-HONEY-TIME-LONG-001');
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('no dispara con 72h (dentro del rango normal)', () {
      final results = engine.evaluate(honeyCtx(hoursElapsed: 72.0));
      expect(results.any((r) => r.ruleId == 'FERM-HONEY-TIME-LONG-001'), isFalse);
    });
  });

  // ── FERM-HONEY-ENDPOINT-001 ──────────────────────────────────────────────

  group('FERM-HONEY-ENDPOINT-001 — endpoint honey', () {
    test('dispara con mucílago seco y ≥48h en honey', () {
      final results = engine.evaluate(honeyCtx(hoursElapsed: 60.0, mucilageState: 'dry'));
      expect(results.any((r) => r.ruleId == 'FERM-HONEY-ENDPOINT-001'), isTrue);
    });

    test('nivel de alerta es info', () {
      final results = engine.evaluate(honeyCtx(hoursElapsed: 72.0, mucilageState: 'dry'));
      final r = results.firstWhere((r) => r.ruleId == 'FERM-HONEY-ENDPOINT-001');
      expect(r.alertLevel, AlertLevel.info);
    });

    test('no dispara con mucílago líquido aunque hayan pasado 60h', () {
      final results = engine.evaluate(honeyCtx(hoursElapsed: 60.0, mucilageState: 'liquid'));
      expect(results.any((r) => r.ruleId == 'FERM-HONEY-ENDPOINT-001'), isFalse);
    });

    test('no dispara con mucílago seco pero < 48h', () {
      final results = engine.evaluate(honeyCtx(hoursElapsed: 30.0, mucilageState: 'dry'));
      expect(results.any((r) => r.ruleId == 'FERM-HONEY-ENDPOINT-001'), isFalse);
    });
  });
}
