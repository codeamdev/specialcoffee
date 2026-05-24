import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_rule.freezed.dart';
part 'ai_rule.g.dart';

enum ConditionOperator { gt, gte, lt, lte, eq, neq, between, inList, notIn }
enum AlertLevel { none, info, warning, high, critical }
enum RuleLogic { and, or }

@freezed
abstract class RuleCondition with _$RuleCondition {
  const factory RuleCondition({
    required String variable,          // campo del AIContext
    required ConditionOperator operator,
    required dynamic threshold,        // num para comparaciones; List para inList
    double? thresholdMax,              // solo para 'between'
  }) = _RuleCondition;

  factory RuleCondition.fromJson(Map<String, dynamic> json) =>
      _$RuleConditionFromJson(json);
}

@freezed
abstract class RuleOutcome with _$RuleOutcome {
  const factory RuleOutcome({
    required String action,
    required AlertLevel alertLevel,
    required double confidenceBase,
    required Map<String, String> explanationByRole, // UserRole.name → plantilla
    @Default([]) List<String> suggestedActions,
    @Default({}) Map<String, dynamic> parameters,
  }) = _RuleOutcome;

  factory RuleOutcome.fromJson(Map<String, dynamic> json) =>
      _$RuleOutcomeFromJson(json);
}

@freezed
abstract class AIRule with _$AIRule {
  const factory AIRule({
    required String id,
    required String module,
    required String name,
    required int priority,             // 1=crítica, 5=informativa
    required RuleLogic logic,
    required List<RuleCondition> conditions,
    required RuleOutcome outcome,
    @Default(true) bool active,
    @Default([]) List<String> tags,
    String? supersedes,                // ID de regla que esta reemplaza
    String? version,
  }) = _AIRule;

  factory AIRule.fromJson(Map<String, dynamic> json) =>
      _$AIRuleFromJson(json);
}

@freezed
abstract class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String ruleId,
    required String action,
    required AlertLevel alertLevel,
    required double confidence,        // 0.0 – 1.0
    required String explanation,       // texto final para el rol del usuario
    required List<String> suggestedActions,
    required Map<String, dynamic> parameters,
    required DateTime generatedAt,
  }) = _Recommendation;
}
