import 'package:special_coffee/ai_engine/models/ai_rule.dart';

enum AlertType { phCritical, phHigh, tempCritical, tempHigh, humidityHigh }

class Alert {
  final AlertType type;
  final AlertLevel level;
  final double triggerValue;
  final double threshold;
  final String lotId;
  final String ruleId;
  final DateTime triggeredAt;

  const Alert({
    required this.type,
    required this.level,
    required this.triggerValue,
    required this.threshold,
    required this.lotId,
    required this.ruleId,
    DateTime? triggeredAt,
  }) : triggeredAt = triggeredAt ?? const _Now();
}

// Auxiliar para regresión lineal en AlertEngine
class FermentationReading {
  final double hoursElapsed;
  final double phValue;
  final double tempC;

  const FermentationReading({
    required this.hoursElapsed,
    required this.phValue,
    required this.tempC,
  });
}

// Workaround para const DateTime.now() en const constructors
class _Now implements DateTime {
  const _Now();
  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}
