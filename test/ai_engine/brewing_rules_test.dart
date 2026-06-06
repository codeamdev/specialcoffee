import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/core/conflict_resolver.dart';
import 'package:special_coffee/ai_engine/evaluators/condition_evaluator.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/brewing_rules.dart';
import '../helpers/test_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final evaluator = ConditionEvaluator();
  final resolver  = ConflictResolver();

  // Fires only the rules that match the given context.
  List<AIRule> fire(List<AIRule> rules, dynamic context) {
    final fired = rules.where((r) => _matches(r, context, evaluator)).toList();
    return resolver.resolve(fired);
  }

  bool hasId(List<AIRule> rules, String id) =>
      rules.any((r) => r.id == id);

  // ── Freshness rules ─────────────────────────────────────────────────────────

  group('BREW-FRESH-FILTER-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-FRESH-FILTER-001');

    test('fires for very fresh filter coffee (roastDays=3)', () {
      final c = ctx(roastDays: 3, brewMethod: 'v60');
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire when roastDays is at threshold (roastDays=5)', () {
      final c = ctx(roastDays: 5, brewMethod: 'v60');
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire for espresso', () {
      final c = ctx(roastDays: 2, brewMethod: 'espresso');
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire for roastDays=0 (default — no data recorded)', () {
      final c = ctx(roastDays: 0, brewMethod: 'v60');
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  group('BREW-FRESH-ESPRESSO-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-FRESH-ESPRESSO-001');

    test('fires for espresso at 5 days (< 10 threshold)', () {
      final c = ctx(roastDays: 5, brewMethod: 'espresso');
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire at exactly 10 days', () {
      final c = ctx(roastDays: 10, brewMethod: 'espresso');
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  group('BREW-STALE-FILTER-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-STALE-FILTER-001');

    test('fires for stale filter coffee (roastDays=60 > 45)', () {
      final c = ctx(roastDays: 60, brewMethod: 'chemex');
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire at exactly 45 days', () {
      final c = ctx(roastDays: 45, brewMethod: 'v60');
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire for espresso', () {
      final c = ctx(roastDays: 60, brewMethod: 'espresso');
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  group('BREW-STALE-ESPRESSO-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-STALE-ESPRESSO-001');

    test('fires for stale espresso (roastDays=35 > 30)', () {
      final c = ctx(roastDays: 35, brewMethod: 'espresso');
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire for filter even when very stale', () {
      final c = ctx(roastDays: 60, brewMethod: 'french_press');
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  // ── Ratio rules ─────────────────────────────────────────────────────────────

  group('BREW-RATIO-LIGHT-FILTER-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-RATIO-LIGHT-FILTER-001');

    test('fires for light roast + v60', () {
      final c = ctx(roastLevel: 'light', brewMethod: 'v60');
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire for dark roast', () {
      final c = ctx(roastLevel: 'dark', brewMethod: 'v60');
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire for espresso', () {
      final c = ctx(roastLevel: 'light', brewMethod: 'espresso');
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  group('BREW-RATIO-DARK-ESPRESSO-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-RATIO-DARK-ESPRESSO-001');

    test('fires for dark roast + espresso', () {
      final c = ctx(roastLevel: 'dark', brewMethod: 'espresso');
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire for light roast', () {
      final c = ctx(roastLevel: 'light', brewMethod: 'espresso');
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  // ── Extraction rules + ConflictResolver ─────────────────────────────────────

  group('BREW-SUB-EXT-001 — supersedes BREW-DIAG-UNDER-EXTRACTED-001', () {
    test('fires for TDS 0.9 (between 0.1–1.14)', () {
      final subExt = BrewingRules.all.firstWhere((r) => r.id == 'BREW-SUB-EXT-001');
      final c = ctx(measuredTdsPct: 0.9, brewMethod: 'v60');
      expect(_matches(subExt, c, evaluator), isTrue);
    });

    test('does not fire for TDS=0.0 (default — no measurement)', () {
      final subExt = BrewingRules.all.firstWhere((r) => r.id == 'BREW-SUB-EXT-001');
      final c = ctx(measuredTdsPct: 0.0);
      expect(_matches(subExt, c, evaluator), isFalse);
    });

    test('ConflictResolver keeps BREW-SUB-EXT-001 (warning) and drops BREW-DIAG-UNDER-EXTRACTED-001 (info)', () {
      final c = ctx(measuredTdsPct: 0.9, brewMethod: 'v60');
      final resolved = fire(BrewingRules.all, c);

      expect(hasId(resolved, 'BREW-SUB-EXT-001'), isTrue);
      expect(hasId(resolved, 'BREW-DIAG-UNDER-EXTRACTED-001'), isFalse);
    });

    test('resolved result has alertLevel warning for under-extraction action', () {
      final c = ctx(measuredTdsPct: 0.9, brewMethod: 'v60');
      final resolved = fire(BrewingRules.all, c);
      final rule = resolved.firstWhere((r) => r.outcome.action == 'DIAGNOSE_UNDER_EXTRACTION');
      expect(rule.outcome.alertLevel, AlertLevel.warning);
    });
  });

  group('BREW-OVER-EXT-001 — supersedes BREW-DIAG-OVER-EXTRACTED-001', () {
    test('fires for TDS 1.8 (between 1.56–3.0)', () {
      final overExt = BrewingRules.all.firstWhere((r) => r.id == 'BREW-OVER-EXT-001');
      final c = ctx(measuredTdsPct: 1.8, brewMethod: 'v60');
      expect(_matches(overExt, c, evaluator), isTrue);
    });

    test('ConflictResolver keeps BREW-OVER-EXT-001 (warning) and drops BREW-DIAG-OVER-EXTRACTED-001 (info)', () {
      final c = ctx(measuredTdsPct: 1.8, brewMethod: 'v60');
      final resolved = fire(BrewingRules.all, c);

      expect(hasId(resolved, 'BREW-OVER-EXT-001'), isTrue);
      expect(hasId(resolved, 'BREW-DIAG-OVER-EXTRACTED-001'), isFalse);
    });
  });

  // ── Water quality rules ──────────────────────────────────────────────────────

  group('BREW-WATER-PURE-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-WATER-PURE-001');

    test('fires when waterTds=50 (< 75 ppm SCA min)', () {
      final c = ctx(waterTds: 50.0);
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire for waterTds=0.0 (default — no measurement)', () {
      final c = ctx(waterTds: 0.0);
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire when waterTds is in SCA range (150 ppm)', () {
      final c = ctx(waterTds: 150.0);
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire when waterTds is exactly at SCA min (75 ppm)', () {
      final c = ctx(waterTds: CoffeeThresholds.waterTdsOptimalMin);
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  group('BREW-WATER-HARD-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-WATER-HARD-001');

    test('fires when waterTds=300 (> 250 ppm SCA max)', () {
      final c = ctx(waterTds: 300.0);
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire for waterTds in SCA range', () {
      final c = ctx(waterTds: 200.0);
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire for default waterTds=0.0', () {
      final c = ctx(waterTds: 0.0);
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  group('BREW-WATER-PH-LOW-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-WATER-PH-LOW-001');

    test('fires when waterPh=5.0 (< 6.5 SCA min)', () {
      final c = ctx(waterPh: 5.0);
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire for waterPh=0.0 (default)', () {
      final c = ctx(waterPh: 0.0);
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire for waterPh in SCA range (7.0)', () {
      final c = ctx(waterPh: 7.0);
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  group('BREW-WATER-PH-HIGH-001', () {
    final rule = BrewingRules.all.firstWhere((r) => r.id == 'BREW-WATER-PH-HIGH-001');

    test('fires when waterPh=8.0 (> 7.5 SCA max)', () {
      final c = ctx(waterPh: 8.0);
      expect(_matches(rule, c, evaluator), isTrue);
    });

    test('does not fire for waterPh in SCA range', () {
      final c = ctx(waterPh: 7.0);
      expect(_matches(rule, c, evaluator), isFalse);
    });

    test('does not fire for default waterPh=0.0', () {
      final c = ctx(waterPh: 0.0);
      expect(_matches(rule, c, evaluator), isFalse);
    });
  });

  // ── AllRules coverage ────────────────────────────────────────────────────────

  test('BrewingRules.all contains exactly 22 rules (8 original + 14 new)', () {
    expect(BrewingRules.all.length, 22);
  });

  test('all rule IDs in BrewingRules.all are unique', () {
    final ids = BrewingRules.all.map((r) => r.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}

// ── Helpers ──────────────────────────────────────────────────────────────────

bool _matches(AIRule rule, dynamic context, ConditionEvaluator evaluator) {
  final results = rule.conditions.map((c) => evaluator.evaluate(c, context)).toList();
  return rule.logic == RuleLogic.and
      ? results.every((r) => r)
      : results.any((r) => r);
}
