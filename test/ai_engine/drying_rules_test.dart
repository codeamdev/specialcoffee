import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/constants/coffee_thresholds.dart';
import 'package:special_coffee/ai_engine/evaluators/condition_evaluator.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/drying_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final evaluator = ConditionEvaluator();

  AIContext dryingCtx({
    required String method,
    double ambientTempC = 25.0,
    double humidityPct = 50.0,
    int dayNumber = 1,
  }) =>
      AIContext(
        userId: 'u_test',
        userRole: UserRole.producer,
        module: 'drying',
        varietyId: 'var_castillo',
        altitudeMasl: 1600,
        region: 'Huila',
        ambientTempC: ambientTempC,
        ambientHumidityPct: 65.0,
        dryingMethod: method,
        currentHumidityPct: humidityPct,
        dryingDayNumber: dayNumber,
      );

  bool allConditions(String ruleId, AIContext context) {
    final r = DryingRules.all.firstWhere((r) => r.id == ruleId);
    return r.conditions.every((c) => evaluator.evaluate(c, context));
  }

  group('DRY-HEAT-STRESS-001 — solo patio y camas africanas', () {
    test('no dispara en patio con temp ≤ 35°C', () {
      expect(
        allConditions('DRY-HEAT-STRESS-001',
            dryingCtx(method: 'patio', ambientTempC: 34.9)),
        isFalse,
      );
    });

    test('dispara en patio con temp > 35°C', () {
      expect(
        allConditions('DRY-HEAT-STRESS-001',
            dryingCtx(method: 'patio', ambientTempC: 36.0)),
        isTrue,
      );
    });

    test('dispara en camas africanas con temp > 35°C', () {
      expect(
        allConditions('DRY-HEAT-STRESS-001',
            dryingCtx(method: 'camas_africanas', ambientTempC: 38.0)),
        isTrue,
      );
    });

    test('NO dispara en mecánico aunque temp > 35°C', () {
      expect(
        allConditions('DRY-HEAT-STRESS-001',
            dryingCtx(method: 'mecanico', ambientTempC: 38.0)),
        isFalse,
      );
    });
  });

  group('DRY-MECH-TEMP-WARN-001 — mecánico > 40°C', () {
    test('no dispara con temp ≤ ${CoffeeThresholds.dryingMechWarnTempC}°C', () {
      expect(
        allConditions('DRY-MECH-TEMP-WARN-001',
            dryingCtx(method: 'mecanico', ambientTempC: 40.0)),
        isFalse,
      );
    });

    test('dispara con temp > ${CoffeeThresholds.dryingMechWarnTempC}°C', () {
      expect(
        allConditions('DRY-MECH-TEMP-WARN-001',
            dryingCtx(method: 'mecanico', ambientTempC: 41.0)),
        isTrue,
      );
    });

    test('NO dispara en patio aunque temp > 40°C', () {
      expect(
        allConditions('DRY-MECH-TEMP-WARN-001',
            dryingCtx(method: 'patio', ambientTempC: 42.0)),
        isFalse,
      );
    });
  });

  group('DRY-MECH-TEMP-CRIT-001 — mecánico > 45°C', () {
    test('no dispara con temp ≤ ${CoffeeThresholds.dryingMechCritTempC}°C', () {
      expect(
        allConditions('DRY-MECH-TEMP-CRIT-001',
            dryingCtx(method: 'mecanico', ambientTempC: 44.0)),
        isFalse,
      );
    });

    test('dispara con temp > ${CoffeeThresholds.dryingMechCritTempC}°C', () {
      expect(
        allConditions('DRY-MECH-TEMP-CRIT-001',
            dryingCtx(method: 'mecanico', ambientTempC: 46.0)),
        isTrue,
      );
    });

    test('supersede correcto apunta a DRY-MECH-TEMP-WARN-001', () {
      final rule = DryingRules.all
          .firstWhere((r) => r.id == 'DRY-MECH-TEMP-CRIT-001');
      expect(rule.supersedes, equals('DRY-MECH-TEMP-WARN-001'));
    });

    test('alerta es high', () {
      final rule = DryingRules.all
          .firstWhere((r) => r.id == 'DRY-MECH-TEMP-CRIT-001');
      expect(rule.outcome.alertLevel, equals(AlertLevel.high));
    });
  });

  group('DRY-MECH-SLOW-001 — mecánico lento', () {
    test('no dispara antes del día ${CoffeeThresholds.dryingMechSlowDay}', () {
      expect(
        allConditions('DRY-MECH-SLOW-001',
            dryingCtx(method: 'mecanico', dayNumber: 4, humidityPct: 35.0)),
        isFalse,
      );
    });

    test('no dispara si humedad ≤ 30%', () {
      expect(
        allConditions('DRY-MECH-SLOW-001',
            dryingCtx(method: 'mecanico', dayNumber: 6, humidityPct: 29.0)),
        isFalse,
      );
    });

    test('dispara en día ${CoffeeThresholds.dryingMechSlowDay} con humedad > 30%', () {
      expect(
        allConditions('DRY-MECH-SLOW-001',
            dryingCtx(method: 'mecanico', dayNumber: 5, humidityPct: 31.0)),
        isTrue,
      );
    });

    test('NO dispara en patio aunque condiciones numéricas se cumplan', () {
      expect(
        allConditions('DRY-MECH-SLOW-001',
            dryingCtx(method: 'patio', dayNumber: 6, humidityPct: 35.0)),
        isFalse,
      );
    });
  });

  group('DRY-CAMAS-SLOW-001 — camas africanas lentas', () {
    test('no dispara antes del día ${CoffeeThresholds.dryingCamasSlowDay}', () {
      expect(
        allConditions('DRY-CAMAS-SLOW-001',
            dryingCtx(method: 'camas_africanas', dayNumber: 17, humidityPct: 20.0)),
        isFalse,
      );
    });

    test('no dispara si humedad ≤ 15%', () {
      expect(
        allConditions('DRY-CAMAS-SLOW-001',
            dryingCtx(method: 'camas_africanas', dayNumber: 19, humidityPct: 14.0)),
        isFalse,
      );
    });

    test('dispara en día ${CoffeeThresholds.dryingCamasSlowDay} con humedad > 15%', () {
      expect(
        allConditions('DRY-CAMAS-SLOW-001',
            dryingCtx(method: 'camas_africanas', dayNumber: 18, humidityPct: 16.0)),
        isTrue,
      );
    });

    test('NO dispara en patio aunque condiciones numéricas se cumplan', () {
      expect(
        allConditions('DRY-CAMAS-SLOW-001',
            dryingCtx(method: 'patio', dayNumber: 20, humidityPct: 18.0)),
        isFalse,
      );
    });
  });
}
