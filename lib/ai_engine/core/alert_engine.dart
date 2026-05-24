import 'package:special_coffee/ai_engine/models/alert.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

/// Monitor de umbrales de baja latencia.
/// Corre en <1ms por lectura — evaluación inmediata sin esperar el RuleEngine completo.
/// Se invoca en cada nueva lectura de sensor (pH, temperatura, humedad).
class AlertEngine {
  static const Map<String, _AlertThresholds> _fermentationThresholds = {
    'lavado': _AlertThresholds(
      phCriticalLow: 3.5,
      phHighLow: 4.0,
      phOptimalMin: 4.0,
      phOptimalMax: 4.8,
      tempCriticalHigh: 30.0,
      tempHighHigh: 27.0,
      tempOptimalMin: 16.0,
      tempOptimalMax: 25.0,
    ),
    'natural': _AlertThresholds(
      phCriticalLow: 3.2,
      phHighLow: 3.6,
      phOptimalMin: 3.5,
      phOptimalMax: 4.2,
      tempCriticalHigh: 28.0,
      tempHighHigh: 25.0,
      tempOptimalMin: 15.0,
      tempOptimalMax: 22.0,
    ),
    'anaerobic_lactic': _AlertThresholds(
      phCriticalLow: 3.0,
      phHighLow: 3.5,
      phOptimalMin: 3.5,
      phOptimalMax: 4.5,
      tempCriticalHigh: 25.0,
      tempHighHigh: 22.0,
      tempOptimalMin: 14.0,
      tempOptimalMax: 20.0,
    ),
    'honey_yellow': _AlertThresholds(
      phCriticalLow: 3.3,
      phHighLow: 3.8,
      phOptimalMin: 3.8,
      phOptimalMax: 4.5,
      tempCriticalHigh: 28.0,
      tempHighHigh: 26.0,
      tempOptimalMin: 16.0,
      tempOptimalMax: 23.0,
    ),
  };

  /// Evalúa una nueva lectura de fermentación y retorna alertas activas.
  List<Alert> evaluateFermentationReading({
    required double ph,
    required double mucilagoTemp,
    required String processType,
    required String lotId,
  }) {
    final thresholds = _fermentationThresholds[processType]
        ?? _fermentationThresholds['lavado']!;

    final alerts = <Alert>[];
    final processUpper = processType.toUpperCase();

    // ── pH ────────────────────────────────────────────────────────────────────
    if (ph < thresholds.phCriticalLow) {
      alerts.add(Alert(
        type: AlertType.phCritical,
        level: AlertLevel.critical,
        triggerValue: ph,
        threshold: thresholds.phCriticalLow,
        lotId: lotId,
        ruleId: 'FERM-PH-CRITICAL-$processUpper-001',
        triggeredAt: DateTime.now(),
      ));
    } else if (ph < thresholds.phHighLow) {
      alerts.add(Alert(
        type: AlertType.phHigh,
        level: AlertLevel.high,
        triggerValue: ph,
        threshold: thresholds.phHighLow,
        lotId: lotId,
        ruleId: 'FERM-PH-HIGH-001',
        triggeredAt: DateTime.now(),
      ));
    }

    // ── Temperatura ───────────────────────────────────────────────────────────
    if (mucilagoTemp > thresholds.tempCriticalHigh) {
      alerts.add(Alert(
        type: AlertType.tempCritical,
        level: AlertLevel.critical,
        triggerValue: mucilagoTemp,
        threshold: thresholds.tempCriticalHigh,
        lotId: lotId,
        ruleId: 'FERM-TEMP-CRITICAL-001',
        triggeredAt: DateTime.now(),
      ));
    } else if (mucilagoTemp > thresholds.tempHighHigh) {
      alerts.add(Alert(
        type: AlertType.tempHigh,
        level: AlertLevel.warning,
        triggerValue: mucilagoTemp,
        threshold: thresholds.tempHighHigh,
        lotId: lotId,
        ruleId: 'FERM-TEMP-HIGH-001',
        triggeredAt: DateTime.now(),
      ));
    }

    return alerts;
  }

  /// Proyecta el tiempo restante de fermentación usando regresión lineal
  /// sobre las últimas N lecturas de pH.
  /// Retorna null si no hay suficientes lecturas o el pH no está bajando.
  double? projectFermentationEndHours({
    required List<FermentationReading> readings,
    required double targetPhMin,
  }) {
    if (readings.length < 3) return null;

    final recent = readings.length > 4
        ? readings.sublist(readings.length - 4)
        : readings;

    final n = recent.length.toDouble();
    final sumX = recent.map((r) => r.hoursElapsed).reduce((a, b) => a + b);
    final sumY = recent.map((r) => r.phValue).reduce((a, b) => a + b);
    final sumXY = recent.map((r) => r.hoursElapsed * r.phValue).reduce((a, b) => a + b);
    final sumX2 = recent.map((r) => r.hoursElapsed * r.hoursElapsed).reduce((a, b) => a + b);

    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return null;

    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;

    if (slope >= 0) return null; // pH no está bajando — no proyectar

    final hoursToTarget = (targetPhMin - intercept) / slope;
    final remainingHours = hoursToTarget - recent.last.hoursElapsed;

    return remainingHours.clamp(0.0, 48.0);
  }

  /// Verifica si el nivel de humedad de secado es crítico.
  AlertLevel dryingHumidityLevel(double humidityPct) {
    if (humidityPct < 10.0) return AlertLevel.high;
    if (humidityPct >= 10.5 && humidityPct <= 12.0) return AlertLevel.none;
    if (humidityPct > 45.0) return AlertLevel.warning;
    return AlertLevel.info;
  }
}

class _AlertThresholds {
  final double phCriticalLow;
  final double phHighLow;
  final double phOptimalMin;
  final double phOptimalMax;
  final double tempCriticalHigh;
  final double tempHighHigh;
  final double tempOptimalMin;
  final double tempOptimalMax;

  const _AlertThresholds({
    required this.phCriticalLow,
    required this.phHighLow,
    required this.phOptimalMin,
    required this.phOptimalMax,
    required this.tempCriticalHigh,
    required this.tempHighHigh,
    required this.tempOptimalMin,
    required this.tempOptimalMax,
  });
}
