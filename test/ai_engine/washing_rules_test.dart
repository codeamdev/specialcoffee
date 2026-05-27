import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/washing_rules.dart';

import '../helpers/test_context.dart';

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
    engine.loadRules(WashingRules.all);
  });

  AIContext washCtx({
    double waterTempC    = 22.0,
    int    waterChanges  = 2,
    double effluentPh    = 4.5,
  }) =>
      ctx(
        module:      'washing',
        processType: 'lavado',
      ).copyWith(
        washingWaterTempC:   waterTempC,
        washingWaterChanges: waterChanges,
        washingEffluentPh:   effluentPh,
      );

  // ── WASH-TEMP-HIGH-001 ──────────────────────────────────────────────────

  group('WASH-TEMP-HIGH-001 — water too hot', () {
    test('temp > 30°C → fires REDUCE_WASH_WATER_TEMP (warning)', () {
      final results = engine.evaluate(washCtx(waterTempC: 31.0));
      expect(results.any((r) => r.ruleId == 'WASH-TEMP-HIGH-001'), isTrue);
      final rec = results.firstWhere((r) => r.ruleId == 'WASH-TEMP-HIGH-001');
      expect(rec.action, 'REDUCE_WASH_WATER_TEMP');
      expect(rec.alertLevel, AlertLevel.warning);
    });

    test('temp exactly 30°C → does NOT fire (threshold is gt, not gte)', () {
      final results = engine.evaluate(washCtx(waterTempC: 30.0));
      expect(results.any((r) => r.ruleId == 'WASH-TEMP-HIGH-001'), isFalse);
    });

    test('temp 22°C (normal) → does NOT fire', () {
      final results = engine.evaluate(washCtx(waterTempC: 22.0));
      expect(results.any((r) => r.ruleId == 'WASH-TEMP-HIGH-001'), isFalse);
    });
  });

  // ── WASH-TEMP-LOW-001 ───────────────────────────────────────────────────

  group('WASH-TEMP-LOW-001 — water too cold', () {
    test('temp 10°C (between 0.1 and 14.9) → fires WARM_WASH_WATER', () {
      final results = engine.evaluate(washCtx(waterTempC: 10.0));
      expect(results.any((r) => r.ruleId == 'WASH-TEMP-LOW-001'), isTrue);
      expect(
        results.firstWhere((r) => r.ruleId == 'WASH-TEMP-LOW-001').alertLevel,
        AlertLevel.info,
      );
    });

    test('temp 0.0 (default) → does NOT fire (avoids false positive)', () {
      final results = engine.evaluate(washCtx(waterTempC: 0.0));
      expect(results.any((r) => r.ruleId == 'WASH-TEMP-LOW-001'), isFalse);
    });

    test('temp 15.0 (exactly at min) → does NOT fire (threshold is exclusive upper)', () {
      final results = engine.evaluate(washCtx(waterTempC: CoffeeThresholds.washingWaterTempCMin));
      expect(results.any((r) => r.ruleId == 'WASH-TEMP-LOW-001'), isFalse);
    });

    test('temp 22°C (normal) → does NOT fire', () {
      final results = engine.evaluate(washCtx(waterTempC: 22.0));
      expect(results.any((r) => r.ruleId == 'WASH-TEMP-LOW-001'), isFalse);
    });
  });

  // ── WASH-INSUFFICIENT-CHANGES-001 ──────────────────────────────────────

  group('WASH-INSUFFICIENT-CHANGES-001 — too few water changes', () {
    test('waterChanges = 1 → fires ADD_WATER_CHANGE (warning)', () {
      final results = engine.evaluate(washCtx(waterChanges: 1));
      expect(results.any((r) => r.ruleId == 'WASH-INSUFFICIENT-CHANGES-001'), isTrue);
      expect(
        results.firstWhere((r) => r.ruleId == 'WASH-INSUFFICIENT-CHANGES-001').alertLevel,
        AlertLevel.warning,
      );
    });

    test('waterChanges = 0 (default) → does NOT fire', () {
      final results = engine.evaluate(washCtx(waterChanges: 0));
      expect(results.any((r) => r.ruleId == 'WASH-INSUFFICIENT-CHANGES-001'), isFalse);
    });

    test('waterChanges = 2 (threshold) → does NOT fire', () {
      final results = engine.evaluate(washCtx(waterChanges: 2));
      expect(results.any((r) => r.ruleId == 'WASH-INSUFFICIENT-CHANGES-001'), isFalse);
    });

    test('waterChanges = 3 → does NOT fire', () {
      final results = engine.evaluate(washCtx(waterChanges: 3));
      expect(results.any((r) => r.ruleId == 'WASH-INSUFFICIENT-CHANGES-001'), isFalse);
    });
  });

  // ── WASH-EFFLUENT-PH-HIGH-001 ───────────────────────────────────────────

  group('WASH-EFFLUENT-PH-HIGH-001 — high effluent pH', () {
    test('effluentPh 6.0 > 5.5 → fires CHECK_FERMENTATION_COMPLETION (warning)', () {
      final results = engine.evaluate(washCtx(effluentPh: 6.0));
      expect(results.any((r) => r.ruleId == 'WASH-EFFLUENT-PH-HIGH-001'), isTrue);
      expect(
        results.firstWhere((r) => r.ruleId == 'WASH-EFFLUENT-PH-HIGH-001').alertLevel,
        AlertLevel.warning,
      );
    });

    test('effluentPh 0.0 (default not-entered) → does NOT fire', () {
      final results = engine.evaluate(washCtx(effluentPh: 0.0));
      expect(results.any((r) => r.ruleId == 'WASH-EFFLUENT-PH-HIGH-001'), isFalse);
    });

    test('effluentPh 4.5 (good fermentation) → does NOT fire', () {
      final results = engine.evaluate(washCtx(effluentPh: 4.5));
      expect(results.any((r) => r.ruleId == 'WASH-EFFLUENT-PH-HIGH-001'), isFalse);
    });

    test('effluentPh exactly 5.5 → does NOT fire (gt, not gte)', () {
      final results = engine.evaluate(
          washCtx(effluentPh: CoffeeThresholds.washingEffluentPhWarn));
      expect(results.any((r) => r.ruleId == 'WASH-EFFLUENT-PH-HIGH-001'), isFalse);
    });
  });

  // ── No false positives from defaults ────────────────────────────────────

  group('No rules fire on all-default washing context', () {
    test('default context (all zeros) → no washing rules fire', () {
      final results = engine.evaluate(washCtx(
        waterTempC:   0.0,
        waterChanges: 0,
        effluentPh:   0.0,
      ));
      expect(results, isEmpty);
    });
  });

  // ── Combined scenario ────────────────────────────────────────────────────

  group('Multiple conditions in one session', () {
    test('hot water + 1 change → both rules fire', () {
      final results = engine.evaluate(washCtx(waterTempC: 35.0, waterChanges: 1));
      expect(results.any((r) => r.ruleId == 'WASH-TEMP-HIGH-001'), isTrue);
      expect(results.any((r) => r.ruleId == 'WASH-INSUFFICIENT-CHANGES-001'), isTrue);
    });

    test('good conditions → no washing rules fire', () {
      final results = engine.evaluate(
          washCtx(waterTempC: 22.0, waterChanges: 3, effluentPh: 4.5));
      expect(results, isEmpty);
    });
  });
}
