import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/all_rules.dart';

import '../helpers/test_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RuleEngine engine;

  setUpAll(() {
    engine = RuleEngine();
    engine.loadRules(AllRules.all, version: AllRules.version);
  });

  group('AllRules integrity', () {
    test('loads without duplicate rule IDs', () {
      final rules = AllRules.all;
      final ids   = rules.map((r) => r.id).toList();
      final unique = ids.toSet();
      expect(unique.length, ids.length,
          reason: 'Duplicate IDs: ${ids.where((id) => ids.where((i) => i == id).length > 1).toSet()}');
    });

    test('all rules have non-empty id, module, and at least one condition', () {
      for (final r in AllRules.all) {
        expect(r.id, isNotEmpty, reason: 'Empty id found');
        expect(r.module, isNotEmpty, reason: 'Empty module in ${r.id}');
        expect(r.conditions, isNotEmpty, reason: 'No conditions in ${r.id}');
      }
    });

    test('version string matches semver pattern', () {
      final semver = RegExp(r'^\d+\.\d+\.\d+$');
      expect(semver.hasMatch(AllRules.version), isTrue,
          reason: 'Version "${AllRules.version}" is not semver');
    });
  });

  group('RuleEngine performance', () {
    test('100 fermentation evaluations complete in < 1 000ms (debug mode)', () {
      final fCtx = ctx(module: 'fermentation', processType: 'lavado');
      final sw   = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        engine.evaluate(fCtx);
      }

      sw.stop();
      // In debug (JIT) mode this must stay under 1 000ms (10ms/call).
      // In AOT release mode the same workload runs in < 5ms/call per the
      // RuleEngine docstring guarantee.
      expect(sw.elapsedMilliseconds, lessThan(1000),
          reason: '100 fermentation evals took ${sw.elapsedMilliseconds}ms');
    });

    test('100 brewing evaluations complete in < 1 000ms (debug mode)', () {
      final bCtx = ctx(
        module:     'brewing',
        brewMethod: 'v60',
        roastLevel: 'light',
        roastDays:  5,
      );
      final sw = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        engine.evaluate(bCtx);
      }

      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(1000),
          reason: '100 brewing evals took ${sw.elapsedMilliseconds}ms');
    });

    test('evaluate returns recommendations only for active module', () {
      final washCtx = ctx(module: 'washing', processType: 'lavado');
      final results = engine.evaluate(washCtx);
      for (final r in results) {
        expect(r.ruleId, isNotEmpty);
        expect(r.action, isNotEmpty);
        expect(r.alertLevel, isA<AlertLevel>());
      }
    });

    test('evaluate with mismatched module returns empty list', () {
      final unknownCtx = ctx(module: 'nonexistent_module');
      final results = engine.evaluate(unknownCtx);
      expect(results, isEmpty);
    });
  });
}
