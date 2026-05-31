import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

import '../helpers/test_context.dart';

void main() {
  late RuleEngine engine;

  setUp(() => engine = RuleEngine());

  // ── loadRules ────────────────────────────────────────────────────────────

  group('RuleEngine.loadRules', () {
    test('rulesCount reflects loaded rules (inactive excluded)', () {
      engine.loadRules([
        rule(id: 'A', conditions: [numCond('current_ph', ConditionOperator.lt, 4.0)]),
        rule(id: 'B', active: false, conditions: [numCond('current_ph', ConditionOperator.lt, 4.0)]),
      ]);
      expect(engine.rulesCount, 1); // inactive B excluded
    });

    test('rulesVersion is stored', () {
      engine.loadRules([], version: '2.5');
      expect(engine.rulesVersion, '2.5');
    });

    test('rules sorted by priority ascending after load', () {
      engine.loadRules([
        rule(id: 'LOW', priority: 5, conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)]),
        rule(id: 'HIGH', priority: 1, conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)]),
      ]);
      final results = engine.evaluate(ctx());
      expect(results.first.ruleId, 'HIGH');
    });
  });

  // ── Module filtering ─────────────────────────────────────────────────────

  group('RuleEngine — module filtering', () {
    setUp(() {
      engine.loadRules([
        rule(
          id: 'FERM-001',
          module: 'fermentation',
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
        ),
        rule(
          id: 'BREW-001',
          module: 'brewing',
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
        ),
        rule(
          id: 'GLOBAL-001',
          module: 'global',
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
        ),
      ]);
    });

    test('fermentation module: only FERM and GLOBAL rules fire', () {
      final results = engine.evaluate(ctx(module: 'fermentation'));
      final ids = results.map((r) => r.ruleId).toList();
      expect(ids, contains('FERM-001'));
      expect(ids, contains('GLOBAL-001'));
      expect(ids, isNot(contains('BREW-001')));
    });

    test('brewing module: only BREW and GLOBAL rules fire', () {
      final results = engine.evaluate(ctx(module: 'brewing'));
      final ids = results.map((r) => r.ruleId).toList();
      expect(ids, contains('BREW-001'));
      expect(ids, contains('GLOBAL-001'));
      expect(ids, isNot(contains('FERM-001')));
    });

    test('module with no matching rules → empty list', () {
      final results = engine.evaluate(ctx(module: 'harvest'));
      // Only global matches; FERM and BREW don't match 'harvest'
      expect(results.map((r) => r.ruleId), contains('GLOBAL-001'));
    });
  });

  // ── AND / OR logic ───────────────────────────────────────────────────────

  group('RuleEngine — rule logic AND / OR', () {
    test('AND: both conditions must match', () {
      engine.loadRules([
        rule(
          id: 'AND-RULE',
          logic: RuleLogic.and,
          conditions: [
            numCond('current_ph', ConditionOperator.lt, 4.0),
            numCond('mucilago_temp_c', ConditionOperator.gt, 26.0),
          ],
        ),
      ]);

      // Only pH matches → should NOT fire
      final partial = engine.evaluate(ctx(currentPh: 3.8, mucilagoTempC: 22.0));
      expect(partial.any((r) => r.ruleId == 'AND-RULE'), isFalse);

      // Both match → should fire
      final both = engine.evaluate(ctx(currentPh: 3.8, mucilagoTempC: 28.0));
      expect(both.any((r) => r.ruleId == 'AND-RULE'), isTrue);
    });

    test('OR: any one condition matches → fires', () {
      engine.loadRules([
        rule(
          id: 'OR-RULE',
          logic: RuleLogic.or,
          conditions: [
            numCond('current_ph', ConditionOperator.lt, 3.5),
            numCond('mucilago_temp_c', ConditionOperator.gt, 30.0),
          ],
        ),
      ]);

      // Only temp matches → fires
      final tempOnly = engine.evaluate(ctx(currentPh: 4.2, mucilagoTempC: 31.0));
      expect(tempOnly.any((r) => r.ruleId == 'OR-RULE'), isTrue);

      // Only pH matches → fires
      final phOnly = engine.evaluate(ctx(currentPh: 3.2, mucilagoTempC: 22.0));
      expect(phOnly.any((r) => r.ruleId == 'OR-RULE'), isTrue);

      // Neither matches → does NOT fire
      final neither = engine.evaluate(ctx(currentPh: 4.2, mucilagoTempC: 22.0));
      expect(neither.any((r) => r.ruleId == 'OR-RULE'), isFalse);
    });

    test('rule with empty conditions → never fires', () {
      engine.loadRules([
        rule(id: 'EMPTY', conditions: []),
      ]);
      expect(engine.evaluate(ctx()), isEmpty);
    });
  });

  // ── Recommendation fields ────────────────────────────────────────────────

  group('RuleEngine — recommendation fields', () {
    setUp(() {
      engine.loadRules([
        rule(
          id: 'CHECK-001',
          module: 'fermentation',
          priority: 2,
          alertLevel: AlertLevel.high,
          confidenceBase: 0.85,
          action: 'CHECK_TEMPERATURE',
          conditions: [numCond('mucilago_temp_c', ConditionOperator.gt, 25.0)],
        ),
      ]);
    });

    test('recommendation has correct ruleId, action, alertLevel', () {
      final results = engine.evaluate(ctx(mucilagoTempC: 26.0));
      expect(results, hasLength(1));
      final rec = results.first;
      expect(rec.ruleId, 'CHECK-001');
      expect(rec.action, 'CHECK_TEMPERATURE');
      expect(rec.alertLevel, AlertLevel.high);
    });

    test('confidence is within [0, 1]', () {
      final results = engine.evaluate(ctx(mucilagoTempC: 26.0));
      expect(results.first.confidence, inInclusiveRange(0.0, 1.0));
    });

    test('generatedAt is recent (within last 5 seconds)', () {
      final before = DateTime.now().subtract(const Duration(seconds: 5));
      final results = engine.evaluate(ctx(mucilagoTempC: 26.0));
      expect(results.first.generatedAt.isAfter(before), isTrue);
    });

    test('explanation is not empty', () {
      final results = engine.evaluate(ctx(mucilagoTempC: 26.0));
      expect(results.first.explanation, isNotEmpty);
    });
  });

  // ── Priority ordering ────────────────────────────────────────────────────

  group('RuleEngine — priority ordering', () {
    test('priority 1 (critical) before priority 3 (info) in output', () {
      engine.loadRules([
        rule(
          id: 'INFO',
          priority: 3,
          alertLevel: AlertLevel.info,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
        ),
        rule(
          id: 'CRITICAL',
          priority: 1,
          alertLevel: AlertLevel.critical,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
        ),
      ]);
      final results = engine.evaluate(ctx());
      expect(results.first.ruleId, 'CRITICAL');
      expect(results.last.ruleId, 'INFO');
    });

    test('same priority → higher confidence comes first', () {
      engine.loadRules([
        rule(
          id: 'LOW-CONF',
          priority: 2,
          confidenceBase: 0.70,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
        ),
        rule(
          id: 'HIGH-CONF',
          priority: 2,
          confidenceBase: 0.90,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
        ),
      ]);
      final results = engine.evaluate(ctx());
      expect(results.first.ruleId, 'HIGH-CONF');
    });
  });

  // ── Conflict resolution (supersedes) ────────────────────────────────────

  group('RuleEngine — conflict resolution', () {
    test('rule with supersedes removes the superseded rule from output', () {
      engine.loadRules([
        rule(
          id: 'OLD-001',
          priority: 2,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
          action: 'OLD_ACTION',
        ),
        rule(
          id: 'NEW-002',
          priority: 1,
          supersedes: 'OLD-001',
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
          action: 'NEW_ACTION',
        ),
      ]);
      final results = engine.evaluate(ctx());
      final ids = results.map((r) => r.ruleId).toList();
      expect(ids, contains('NEW-002'));
      expect(ids, isNot(contains('OLD-001')));
    });

    test('same action: critical (0.75) beats warning (0.95) — alertLevel over confidence', () {
      engine.loadRules([
        rule(
          id: 'WARN-HIGH-CONF',
          priority: 2,
          alertLevel: AlertLevel.warning,
          confidenceBase: 0.95,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
          action: 'CHECK_TEMPERATURE',
        ),
        rule(
          id: 'CRIT-LOW-CONF',
          priority: 1,
          alertLevel: AlertLevel.critical,
          confidenceBase: 0.75,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
          action: 'CHECK_TEMPERATURE',
        ),
      ]);
      final results = engine.evaluate(ctx());
      expect(results.length, 1);
      expect(results.first.ruleId, 'CRIT-LOW-CONF');
      expect(results.first.alertLevel, AlertLevel.critical);
    });

    test('same action, same alertLevel: higher confidence wins', () {
      engine.loadRules([
        rule(
          id: 'LOW-CONF',
          priority: 2,
          alertLevel: AlertLevel.warning,
          confidenceBase: 0.70,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
          action: 'CHECK_TEMPERATURE',
        ),
        rule(
          id: 'HIGH-CONF',
          priority: 1,
          alertLevel: AlertLevel.warning,
          confidenceBase: 0.90,
          conditions: [numCond('altitude_masl', ConditionOperator.gt, 0)],
          action: 'CHECK_TEMPERATURE',
        ),
      ]);
      final results = engine.evaluate(ctx());
      expect(results.length, 1);
      expect(results.first.ruleId, 'HIGH-CONF');
    });
  });

  // ── Real-world scenarios ─────────────────────────────────────────────────

  group('RuleEngine — real-world scenario: critical fermentation', () {
    test('low pH during active fermentation fires critical recommendation', () {
      engine.loadRules([
        rule(
          id: 'FERM-PH-CRIT-001',
          module: 'fermentation',
          priority: 1,
          alertLevel: AlertLevel.critical,
          logic: RuleLogic.and,
          conditions: [
            strCond('fermentation_status', ConditionOperator.eq, 'active'),
            numCond('current_ph', ConditionOperator.lt, 3.8),
          ],
          action: 'STOP_FERMENTATION',
          confidenceBase: 0.95,
        ),
      ]);

      final critical = engine.evaluate(ctx(
        module: 'fermentation',
        fermentationStatus: 'active',
        currentPh: 3.5,
      ));
      expect(critical, hasLength(1));
      expect(critical.first.alertLevel, AlertLevel.critical);
      expect(critical.first.confidence, greaterThan(0.80));
    });

    test('process type filter: anaerobic rule does not fire for lavado', () {
      engine.loadRules([
        rule(
          id: 'ANAEROBIC-ONLY',
          module: 'fermentation',
          logic: RuleLogic.and,
          conditions: [
            strCond('process_type', ConditionOperator.eq, 'anaerobic_lactic'),
            numCond('fermentation_hours_elapsed', ConditionOperator.gt, 36),
          ],
          action: 'CHECK_LACTIC',
        ),
      ]);

      final lavado = engine.evaluate(ctx(
        module: 'fermentation',
        processType: 'lavado',
        fermentationHoursElapsed: 40.0,
      ));
      expect(lavado, isEmpty);

      final anaerobic = engine.evaluate(ctx(
        module: 'fermentation',
        processType: 'anaerobic_lactic',
        fermentationHoursElapsed: 40.0,
      ));
      expect(anaerobic, hasLength(1));
    });
  });
}
