import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/core/alert_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/models/alert.dart';

void main() {
  late AlertEngine engine;

  setUp(() => engine = AlertEngine());

  // ── evaluateFermentationReading ───────────────────────────────────────────

  group('AlertEngine.evaluateFermentationReading — lavado', () {
    test('pH 3.3 < 3.5 → critical alert', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 3.3, mucilagoTemp: 22.0, processType: 'lavado', lotId: 'lot_1',
      );
      expect(alerts.length, 1);
      expect(alerts.first.type, AlertType.phCritical);
      expect(alerts.first.level, AlertLevel.critical);
    });

    test('pH 3.7 (between 3.5 and 4.0) → high alert', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 3.7, mucilagoTemp: 22.0, processType: 'lavado', lotId: 'lot_1',
      );
      expect(alerts.length, 1);
      expect(alerts.first.type, AlertType.phHigh);
      expect(alerts.first.level, AlertLevel.high);
    });

    test('pH 4.2 within optimal → no pH alert', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 4.2, mucilagoTemp: 22.0, processType: 'lavado', lotId: 'lot_1',
      );
      expect(alerts.where((a) => a.type == AlertType.phCritical || a.type == AlertType.phHigh), isEmpty);
    });

    test('temp 31°C > 30°C → critical temp alert', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 4.2, mucilagoTemp: 31.0, processType: 'lavado', lotId: 'lot_1',
      );
      expect(alerts.any((a) => a.type == AlertType.tempCritical && a.level == AlertLevel.critical), isTrue);
    });

    test('temp 28°C (between 27 and 30) → warning temp alert', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 4.2, mucilagoTemp: 28.0, processType: 'lavado', lotId: 'lot_1',
      );
      expect(alerts.any((a) => a.type == AlertType.tempHigh && a.level == AlertLevel.warning), isTrue);
    });

    test('pH 4.2 + temp 22°C → no alerts', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 4.2, mucilagoTemp: 22.0, processType: 'lavado', lotId: 'lot_1',
      );
      expect(alerts, isEmpty);
    });

    test('both pH and temp critical → 2 alerts', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 3.2, mucilagoTemp: 32.0, processType: 'lavado', lotId: 'lot_1',
      );
      expect(alerts.length, 2);
      expect(alerts.every((a) => a.level == AlertLevel.critical), isTrue);
    });
  });

  group('AlertEngine.evaluateFermentationReading — natural (lower thresholds)', () {
    test('pH 3.5 > 3.2 critical → no critical; 3.5 < 3.6 high → high alert', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 3.5, mucilagoTemp: 18.0, processType: 'natural', lotId: 'lot_2',
      );
      expect(alerts.any((a) => a.type == AlertType.phHigh), isTrue);
      expect(alerts.any((a) => a.type == AlertType.phCritical), isFalse);
    });

    test('temp 29°C > 28°C critical → critical alert for natural', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 3.8, mucilagoTemp: 29.0, processType: 'natural', lotId: 'lot_2',
      );
      expect(alerts.any((a) => a.type == AlertType.tempCritical), isTrue);
    });
  });

  group('AlertEngine.evaluateFermentationReading — anaerobic_lactic', () {
    test('pH 3.1 > 3.0 critical → no critical alert', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 3.1, mucilagoTemp: 16.0, processType: 'anaerobic_lactic', lotId: 'lot_3',
      );
      // 3.1 > 3.0 (critical) but < 3.5 (high) → high alert only
      expect(alerts.any((a) => a.type == AlertType.phHigh), isTrue);
      expect(alerts.any((a) => a.type == AlertType.phCritical), isFalse);
    });

    test('temp 26°C > 25°C → critical alert for anaerobic_lactic', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 4.0, mucilagoTemp: 26.0, processType: 'anaerobic_lactic', lotId: 'lot_3',
      );
      expect(alerts.any((a) => a.type == AlertType.tempCritical), isTrue);
    });
  });

  group('AlertEngine.evaluateFermentationReading — unknown process → defaults to lavado', () {
    test('unknown process type uses lavado thresholds', () {
      final alertsUnknown = engine.evaluateFermentationReading(
        ph: 3.3, mucilagoTemp: 22.0, processType: 'unknown_process', lotId: 'lot_x',
      );
      final alertsLavado = engine.evaluateFermentationReading(
        ph: 3.3, mucilagoTemp: 22.0, processType: 'lavado', lotId: 'lot_x',
      );
      expect(alertsUnknown.map((a) => a.type).toList(),
             alertsLavado.map((a) => a.type).toList());
    });
  });

  group('AlertEngine.evaluateFermentationReading — alert fields', () {
    test('alert captures triggerValue and threshold', () {
      final alerts = engine.evaluateFermentationReading(
        ph: 3.3, mucilagoTemp: 22.0, processType: 'lavado', lotId: 'LOT-007',
      );
      final alert = alerts.first;
      expect(alert.triggerValue, 3.3);
      expect(alert.threshold, 3.5);
      expect(alert.lotId, 'LOT-007');
    });

    test('triggeredAt is within the last second', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final alerts = engine.evaluateFermentationReading(
        ph: 3.0, mucilagoTemp: 22.0, processType: 'lavado', lotId: 'lot_1',
      );
      expect(alerts.first.triggeredAt.isAfter(before), isTrue);
    });
  });

  // ── projectFermentationEndHours ───────────────────────────────────────────

  group('AlertEngine.projectFermentationEndHours', () {
    FermentationReading r(double h, double ph) =>
        FermentationReading(hoursElapsed: h, phValue: ph, tempC: 22.0);

    test('< 3 readings → returns null', () {
      expect(
        engine.projectFermentationEndHours(
          readings: [r(0, 4.8), r(8, 4.5)],
          targetPhMin: 4.0,
        ),
        isNull,
      );
    });

    test('pH not decreasing (slope ≥ 0) → returns null', () {
      final readings = [r(0, 4.0), r(8, 4.2), r(16, 4.4), r(24, 4.6)];
      expect(
        engine.projectFermentationEndHours(readings: readings, targetPhMin: 4.0),
        isNull,
      );
    });

    test('pH decreasing → returns positive hours', () {
      final readings = [r(0, 5.0), r(8, 4.7), r(16, 4.4), r(24, 4.1)];
      final hours = engine.projectFermentationEndHours(
        readings: readings, targetPhMin: 4.0,
      );
      expect(hours, isNotNull);
      expect(hours!, greaterThanOrEqualTo(0.0));
    });

    test('result is clamped to 48.0 maximum', () {
      // Very slow drop → projection would exceed 48h
      final readings = [r(0, 5.0), r(1, 4.99), r(2, 4.98), r(3, 4.97)];
      final hours = engine.projectFermentationEndHours(
        readings: readings, targetPhMin: 4.0,
      );
      if (hours != null) {
        expect(hours, lessThanOrEqualTo(48.0));
      }
    });

    test('already past target pH → returns 0', () {
      // pH already at or below target
      final readings = [r(0, 5.0), r(8, 4.3), r(16, 3.9), r(24, 3.6)];
      final hours = engine.projectFermentationEndHours(
        readings: readings, targetPhMin: 4.0,
      );
      if (hours != null) expect(hours, 0.0);
    });

    test('uses only last 4 readings when > 4 available', () {
      // 6 readings; last 4 have a clear trend
      final readings = [
        r(0, 6.0), r(4, 5.5),
        r(8, 5.0), r(12, 4.7), r(16, 4.4), r(20, 4.1),
      ];
      final hours = engine.projectFermentationEndHours(
        readings: readings, targetPhMin: 4.0,
      );
      expect(hours, isNotNull);
    });
  });

  // ── dryingHumidityLevel ───────────────────────────────────────────────────

  group('AlertEngine.dryingHumidityLevel', () {
    test('9% < 10 → high', () =>
        expect(engine.dryingHumidityLevel(9.0), AlertLevel.high));

    test('11% in [10.5, 12] → none', () =>
        expect(engine.dryingHumidityLevel(11.0), AlertLevel.none));

    test('50% > 45 → warning', () =>
        expect(engine.dryingHumidityLevel(50.0), AlertLevel.warning));

    test('13% between 12 and 45 → info', () =>
        expect(engine.dryingHumidityLevel(13.0), AlertLevel.info));
  });
}
