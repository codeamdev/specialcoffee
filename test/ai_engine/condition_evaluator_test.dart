import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/evaluators/condition_evaluator.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

import '../helpers/test_context.dart';

void main() {
  late ConditionEvaluator evaluator;

  setUp(() => evaluator = ConditionEvaluator());

  // ── Numeric operators ────────────────────────────────────────────────────

  group('ConditionEvaluator — numeric operators', () {
    test('gt: 1650 > 1500 → true', () {
      expect(
        evaluator.evaluate(
          numCond('altitude_masl', ConditionOperator.gt, 1500),
          ctx(altitudeMasl: 1650),
        ),
        isTrue,
      );
    });

    test('gt: 1500 > 1500 → false', () {
      expect(
        evaluator.evaluate(
          numCond('altitude_masl', ConditionOperator.gt, 1500),
          ctx(altitudeMasl: 1500),
        ),
        isFalse,
      );
    });

    test('gte: 1500 >= 1500 → true', () {
      expect(
        evaluator.evaluate(
          numCond('altitude_masl', ConditionOperator.gte, 1500),
          ctx(altitudeMasl: 1500),
        ),
        isTrue,
      );
    });

    test('lt: 3.8 < 4.0 → true', () {
      expect(
        evaluator.evaluate(
          numCond('current_ph', ConditionOperator.lt, 4.0),
          ctx(currentPh: 3.8),
        ),
        isTrue,
      );
    });

    test('lte: 4.0 <= 4.0 → true', () {
      expect(
        evaluator.evaluate(
          numCond('current_ph', ConditionOperator.lte, 4.0),
          ctx(currentPh: 4.0),
        ),
        isTrue,
      );
    });

    test('eq: 24.0 == 24 → true', () {
      expect(
        evaluator.evaluate(
          numCond('fermentation_hours_elapsed', ConditionOperator.eq, 24),
          ctx(fermentationHoursElapsed: 24.0),
        ),
        isTrue,
      );
    });

    test('neq: 20 != 30 → true', () {
      expect(
        evaluator.evaluate(
          numCond('ambient_temp_c', ConditionOperator.neq, 30),
          ctx(ambientTempC: 20.0),
        ),
        isTrue,
      );
    });

    test('between: 4.3 in [4.0, 4.8] → true', () {
      expect(
        evaluator.evaluate(
          numCond('current_ph', ConditionOperator.between, 4.0, max: 4.8),
          ctx(currentPh: 4.3),
        ),
        isTrue,
      );
    });

    test('between: 3.9 not in [4.0, 4.8] → false', () {
      expect(
        evaluator.evaluate(
          numCond('current_ph', ConditionOperator.between, 4.0, max: 4.8),
          ctx(currentPh: 3.9),
        ),
        isFalse,
      );
    });

    test('between: boundaries inclusive — 4.0 in [4.0, 4.8] → true', () {
      expect(
        evaluator.evaluate(
          numCond('current_ph', ConditionOperator.between, 4.0, max: 4.8),
          ctx(currentPh: 4.0),
        ),
        isTrue,
      );
    });

    test('inList: 1650 in [1500, 1650, 2000] → true', () {
      expect(
        evaluator.evaluate(
          numCond('altitude_masl', ConditionOperator.inList, [1500, 1650, 2000]),
          ctx(altitudeMasl: 1650),
        ),
        isTrue,
      );
    });

    test('notIn: 1700 not in [1500, 1600] → true', () {
      expect(
        evaluator.evaluate(
          numCond('altitude_masl', ConditionOperator.notIn, [1500, 1600]),
          ctx(altitudeMasl: 1700),
        ),
        isTrue,
      );
    });
  });

  // ── String operators ─────────────────────────────────────────────────────

  group('ConditionEvaluator — string operators', () {
    test('eq: processType == lavado → true', () {
      expect(
        evaluator.evaluate(
          strCond('process_type', ConditionOperator.eq, 'lavado'),
          ctx(processType: 'lavado'),
        ),
        isTrue,
      );
    });

    test('eq: processType == natural when lavado → false', () {
      expect(
        evaluator.evaluate(
          strCond('process_type', ConditionOperator.eq, 'natural'),
          ctx(processType: 'lavado'),
        ),
        isFalse,
      );
    });

    test('neq: roastLevel != dark when medium → true', () {
      expect(
        evaluator.evaluate(
          strCond('roast_level', ConditionOperator.neq, 'dark'),
          ctx(roastLevel: 'medium'),
        ),
        isTrue,
      );
    });

    test('inList: mucilage_state in [liquid, viscous] → true', () {
      expect(
        evaluator.evaluate(
          strCond('mucilage_state', ConditionOperator.inList, ['liquid', 'viscous']),
          ctx(mucilageState: 'liquid'),
        ),
        isTrue,
      );
    });

    test('notIn: region not in [Nariño, Cauca] → true', () {
      expect(
        evaluator.evaluate(
          strCond('region', ConditionOperator.notIn, ['Nariño', 'Cauca']),
          ctx(region: 'Huila'),
        ),
        isTrue,
      );
    });

    test('user_role accessor: producer → true', () {
      expect(
        evaluator.evaluate(
          strCond('user_role', ConditionOperator.eq, 'producer'),
          ctx(role: UserRole.producer),
        ),
        isTrue,
      );
    });

    test('null processType accessed as empty string — eq empty → true', () {
      expect(
        evaluator.evaluate(
          strCond('process_type', ConditionOperator.eq, ''),
          ctx(processType: null),
        ),
        isTrue,
      );
    });
  });

  // ── All numeric fields accessible ────────────────────────────────────────

  group('ConditionEvaluator — field coverage', () {
    final numericFields = <String, double>{
      'altitude_masl': 1650,
      'ambient_temp_c': 20.0,
      'ambient_humidity_pct': 70.0,
      'rain_probability_pct': 20.0,
      'uv_index': 3.0,
      'brix_level': 0.0,
      'cherry_color_pct': 0.0,
      'fermentation_hours_elapsed': 24.0,
      'current_ph': 4.2,
      'mucilago_temp_c': 22.0,
      'current_humidity_pct': 0.0,
      'drying_day_number': 0.0,
      'roast_days': 10.0,
      'water_hardness_ppm': 120.0,
      'measured_tds_pct': 0.0,
      'measured_yield_pct': 0.0,
      'user_preferred_tds_min': 1.30,
      'user_preferred_tds_max': 1.38,
      'user_sweetness_weight': 0.5,
      'user_acidity_weight': 0.5,
      'user_ai_trust_score': 0.78,
      'variety_sca_potential': 85.0,
      'user_avg_sca': 0.0,
      'user_avg_fermentation_h': 0.0,
      'user_lots_completed': 5.0,
    };

    for (final entry in numericFields.entries) {
      test('numeric field "${entry.key}" is accessible', () {
        expect(
          () => evaluator.evaluate(
            numCond(entry.key, ConditionOperator.gte, 0),
            ctx(),
          ),
          returnsNormally,
        );
      });
    }

    final stringFields = [
      'process_type',
      'fermentation_status',
      'mucilage_state',
      'brew_method',
      'roast_level',
      'variety_id',
      'variety_fermentation_speed',
      'variety_sensitivity',
      'region',
      'user_role',
      'module',
    ];

    for (final field in stringFields) {
      test('string field "$field" is accessible', () {
        expect(
          () => evaluator.evaluate(
            strCond(field, ConditionOperator.neq, '__nonexistent__'),
            ctx(),
          ),
          returnsNormally,
        );
      });
    }
  });

  // ── Unknown variable ─────────────────────────────────────────────────────

  group('ConditionEvaluator — unknown variable', () {
    test('unknown variable → returns false (does not throw in production)', () {
      expect(
        evaluator.evaluate(
          numCond('nonexistent_field', ConditionOperator.gt, 0),
          ctx(),
        ),
        isFalse,
      );
    });
  });
}
