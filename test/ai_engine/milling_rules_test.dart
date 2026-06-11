import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/milling_rules.dart';

import '../helpers/test_context.dart';

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
    engine.loadRules(MillingRules.all);
  });

  AIContext millingCtx({double yieldPct = 0.0}) =>
      ctx(module: 'milling').copyWith(millingYieldPct: yieldPct);

  // ── MILL-YIELD-LOW-001 ────────────────────────────────────────────────────

  group('MILL-YIELD-LOW-001 — rendimiento crítico < 18%', () {
    test('dispara con yield 15% (por debajo del mínimo SCA)', () {
      final results = engine.evaluate(millingCtx(yieldPct: 15.0));
      expect(
        results.any((r) => r.ruleId == 'MILL-YIELD-LOW-001'),
        isTrue,
      );
    });

    test('nivel de alerta es critical', () {
      final results = engine.evaluate(millingCtx(yieldPct: 12.0));
      final result = results.firstWhere((r) => r.ruleId == 'MILL-YIELD-LOW-001');
      expect(result.alertLevel, AlertLevel.critical);
    });

    test('no dispara con yield 18% (límite inferior del rango SCA)', () {
      final results = engine.evaluate(millingCtx(yieldPct: 18.0));
      expect(results.any((r) => r.ruleId == 'MILL-YIELD-LOW-001'), isFalse);
    });

    test('no dispara con yield 0.0 (valor por defecto — sin datos)', () {
      final results = engine.evaluate(millingCtx(yieldPct: 0.0));
      expect(results.any((r) => r.ruleId == 'MILL-YIELD-LOW-001'), isFalse);
    });

    test('dispara con yield 0.1 (mínimo del rango between)', () {
      final results = engine.evaluate(millingCtx(yieldPct: 0.1));
      expect(results.any((r) => r.ruleId == 'MILL-YIELD-LOW-001'), isTrue);
    });
  });

  // ── MILL-YIELD-HIGH-001 ───────────────────────────────────────────────────

  group('MILL-YIELD-HIGH-001 — rendimiento alto > 22%', () {
    test('dispara con yield 25% (sobre el máximo SCA)', () {
      final results = engine.evaluate(millingCtx(yieldPct: 25.0));
      expect(
        results.any((r) => r.ruleId == 'MILL-YIELD-HIGH-001'),
        isTrue,
      );
    });

    test('nivel de alerta es info', () {
      final results = engine.evaluate(millingCtx(yieldPct: 30.0));
      final result = results.firstWhere((r) => r.ruleId == 'MILL-YIELD-HIGH-001');
      expect(result.alertLevel, AlertLevel.info);
    });

    test('no dispara con yield 22% (límite superior del rango SCA)', () {
      final results = engine.evaluate(millingCtx(yieldPct: 22.0));
      expect(results.any((r) => r.ruleId == 'MILL-YIELD-HIGH-001'), isFalse);
    });

    test('no dispara con yield en rango óptimo 20%', () {
      final results = engine.evaluate(millingCtx(yieldPct: 20.0));
      expect(results.any((r) => r.ruleId == 'MILL-YIELD-HIGH-001'), isFalse);
    });
  });

  // ── Rango óptimo SCA ──────────────────────────────────────────────────────

  group('Rango óptimo SCA 18–22%', () {
    test('sin alertas de trilla para yield 19%', () {
      final results = engine.evaluate(millingCtx(yieldPct: 19.0));
      expect(
        results.where((r) => r.ruleId.startsWith('MILL-')),
        isEmpty,
      );
    });

    test('sin alertas de trilla para yield 21.5%', () {
      final results = engine.evaluate(millingCtx(yieldPct: 21.5));
      expect(
        results.where((r) => r.ruleId.startsWith('MILL-')),
        isEmpty,
      );
    });
  });
}
