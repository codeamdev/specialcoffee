import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/drying_rules.dart';

import '../helpers/test_context.dart';

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
    engine.loadRules(DryingRules.all);
  });

  AIContext dryCtx({
    double ambientTempC      = 25.0,
    double ambientHumidityPct = 65.0,
    double currentHumidityPct = 40.0,
    int    dryingDayNumber   = 5,
  }) =>
      ctx(
        module:            'drying',
        ambientTempC:      ambientTempC,
        ambientHumidityPct: ambientHumidityPct,
      ).copyWith(
        currentHumidityPct: currentHumidityPct,
        dryingDayNumber:    dryingDayNumber,
      );

  // ── Existing rules still fire (C-1 constraint: no regressions) ─────────

  group('Existing drying rules — no regressions', () {
    test('DRY-TARGET-REACHED-001 still fires at 11% humidity', () {
      final results = engine.evaluate(dryCtx(currentHumidityPct: 11.0));
      expect(results.any((r) => r.ruleId == 'DRY-TARGET-REACHED-001'), isTrue);
    });

    test('DRY-OVER-DRIED-001 still fires at 9% humidity', () {
      final results = engine.evaluate(dryCtx(currentHumidityPct: 9.0));
      expect(results.any((r) => r.ruleId == 'DRY-OVER-DRIED-001'), isTrue);
    });

    test('DRY-SLOW-PROGRESS-001 still fires at day 10 / 35% humidity', () {
      final results = engine.evaluate(
          dryCtx(dryingDayNumber: 10, currentHumidityPct: 35.0));
      expect(results.any((r) => r.ruleId == 'DRY-SLOW-PROGRESS-001'), isTrue);
    });
  });

  // ── DRY-HEAT-STRESS-001 ─────────────────────────────────────────────────

  group('DRY-HEAT-STRESS-001 — ambient temp too high', () {
    test('ambient 36°C > 35°C → fires REDUCE_SUN_EXPOSURE (warning)', () {
      final results = engine.evaluate(dryCtx(ambientTempC: 36.0));
      expect(results.any((r) => r.ruleId == 'DRY-HEAT-STRESS-001'), isTrue);
      final rec = results.firstWhere((r) => r.ruleId == 'DRY-HEAT-STRESS-001');
      expect(rec.action, 'REDUCE_SUN_EXPOSURE');
      expect(rec.alertLevel, AlertLevel.warning);
    });

    test('ambient exactly 35°C → does NOT fire (gt, not gte)', () {
      final results = engine.evaluate(
          dryCtx(ambientTempC: CoffeeThresholds.dryingHeatStressTempC));
      expect(results.any((r) => r.ruleId == 'DRY-HEAT-STRESS-001'), isFalse);
    });

    test('ambient 28°C (normal) → does NOT fire', () {
      final results = engine.evaluate(dryCtx(ambientTempC: 28.0));
      expect(results.any((r) => r.ruleId == 'DRY-HEAT-STRESS-001'), isFalse);
    });
  });

  // ── DRY-HIGH-AMBIENT-HUMIDITY-001 ───────────────────────────────────────

  group('DRY-HIGH-AMBIENT-HUMIDITY-001 — high ambient humidity', () {
    test('amb_hum 82% + grain_hum 20% → fires MONITOR_MOLD_RISK (warning)', () {
      final results = engine.evaluate(
          dryCtx(ambientHumidityPct: 82.0, currentHumidityPct: 20.0));
      expect(results.any((r) => r.ruleId == 'DRY-HIGH-AMBIENT-HUMIDITY-001'), isTrue);
      expect(
        results.firstWhere((r) => r.ruleId == 'DRY-HIGH-AMBIENT-HUMIDITY-001')
            .alertLevel,
        AlertLevel.warning,
      );
    });

    test('amb_hum 82% + grain already dry (11%) → does NOT fire (coffee safe)', () {
      final results = engine.evaluate(
          dryCtx(ambientHumidityPct: 82.0, currentHumidityPct: 11.0));
      expect(results.any((r) => r.ruleId == 'DRY-HIGH-AMBIENT-HUMIDITY-001'), isFalse);
    });

    test('amb_hum exactly 80% → does NOT fire (gt, not gte)', () {
      final results = engine.evaluate(
          dryCtx(ambientHumidityPct: CoffeeThresholds.dryingHighAmbHumidityPct,
              currentHumidityPct: 30.0));
      expect(results.any((r) => r.ruleId == 'DRY-HIGH-AMBIENT-HUMIDITY-001'), isFalse);
    });
  });

  // ── DRY-CRITICAL-AMBIENT-HUMIDITY-001 ───────────────────────────────────

  group('DRY-CRITICAL-AMBIENT-HUMIDITY-001 — critical humidity + supersedes warning', () {
    test('amb_hum 87% + day 5 → fires SHELTER_COFFEE_IMMEDIATELY (high)', () {
      final results = engine.evaluate(
          dryCtx(ambientHumidityPct: 87.0, dryingDayNumber: 5, currentHumidityPct: 30.0));
      expect(results.any((r) => r.ruleId == 'DRY-CRITICAL-AMBIENT-HUMIDITY-001'), isTrue);
      final rec = results.firstWhere((r) => r.ruleId == 'DRY-CRITICAL-AMBIENT-HUMIDITY-001');
      expect(rec.action, 'SHELTER_COFFEE_IMMEDIATELY');
      expect(rec.alertLevel, AlertLevel.high);
    });

    test('DRY-CRITICAL supersedes DRY-HIGH — only SHELTER fires at 87%', () {
      final results = engine.evaluate(
          dryCtx(ambientHumidityPct: 87.0, dryingDayNumber: 5, currentHumidityPct: 30.0));
      // ConflictResolver must eliminate DRY-HIGH-AMBIENT-HUMIDITY-001
      expect(results.any((r) => r.ruleId == 'DRY-HIGH-AMBIENT-HUMIDITY-001'), isFalse);
      expect(results.any((r) => r.ruleId == 'DRY-CRITICAL-AMBIENT-HUMIDITY-001'), isTrue);
    });

    test('amb_hum 87% + day 2 (before threshold) → does NOT fire', () {
      final results = engine.evaluate(
          dryCtx(ambientHumidityPct: 87.0, dryingDayNumber: 2));
      expect(results.any((r) => r.ruleId == 'DRY-CRITICAL-AMBIENT-HUMIDITY-001'), isFalse);
    });

    test('amb_hum exactly 85% → does NOT fire (gt, not gte)', () {
      final results = engine.evaluate(
          dryCtx(ambientHumidityPct: CoffeeThresholds.dryingCritAmbHumidityPct,
              dryingDayNumber: 5));
      expect(results.any((r) => r.ruleId == 'DRY-CRITICAL-AMBIENT-HUMIDITY-001'), isFalse);
    });
  });

  // ── DRY-TURNING-REMINDER-001 ────────────────────────────────────────────

  group('DRY-TURNING-REMINDER-001 — turning reminder', () {
    test('day 5 + grain_hum 45% → fires INCREASE_TURNING_FREQUENCY (info)', () {
      final results = engine.evaluate(
          dryCtx(dryingDayNumber: 5, currentHumidityPct: 45.0));
      expect(results.any((r) => r.ruleId == 'DRY-TURNING-REMINDER-001'), isTrue);
      expect(
        results.firstWhere((r) => r.ruleId == 'DRY-TURNING-REMINDER-001')
            .alertLevel,
        AlertLevel.info,
      );
    });

    test('day 3 (exactly at start threshold) + grain_hum 50% → fires', () {
      final results = engine.evaluate(
          dryCtx(dryingDayNumber: CoffeeThresholds.dryingTurningStartDay,
              currentHumidityPct: 50.0));
      expect(results.any((r) => r.ruleId == 'DRY-TURNING-REMINDER-001'), isTrue);
    });

    test('day 2 (before threshold) + grain_hum 50% → does NOT fire', () {
      final results = engine.evaluate(
          dryCtx(dryingDayNumber: 2, currentHumidityPct: 50.0));
      expect(results.any((r) => r.ruleId == 'DRY-TURNING-REMINDER-001'), isFalse);
    });

    test('day 5 + grain_hum 11% (near dry) → does NOT fire', () {
      final results = engine.evaluate(
          dryCtx(dryingDayNumber: 5, currentHumidityPct: 11.0));
      expect(results.any((r) => r.ruleId == 'DRY-TURNING-REMINDER-001'), isFalse);
    });

    test('day 5 + grain_hum exactly 40% → does NOT fire (gt, not gte)', () {
      final results = engine.evaluate(dryCtx(
          dryingDayNumber: 5,
          currentHumidityPct: CoffeeThresholds.dryingTurningMinGrainHum));
      expect(results.any((r) => r.ruleId == 'DRY-TURNING-REMINDER-001'), isFalse);
    });
  });

  // ── AllRules count (smoke) ───────────────────────────────────────────────

  group('DryingRules total', () {
    test('11 rules loaded (7 original + 4 nuevas de método)', () {
      expect(DryingRules.all.length, 11);
    });
  });
}
