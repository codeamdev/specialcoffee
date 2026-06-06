import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

/// Builds a minimal valid AIContext for tests.
/// Override only the fields relevant to the test case.
AIContext ctx({
  String userId = 'u_test',
  UserRole role = UserRole.processor,
  String module = 'fermentation',
  String varietyId = 'var_castillo',
  int altitudeMasl = 1650,
  String region = 'Huila',
  double ambientTempC = 20.0,
  double ambientHumidityPct = 70.0,
  String? processType = 'lavado',
  double currentPh = 4.2,
  double mucilagoTempC = 22.0,
  double fermentationHoursElapsed = 24.0,
  String fermentationStatus = 'active',
  String mucilageState = 'liquid',
  String? brewMethod,
  String roastLevel = 'medium',
  int roastDays = 10,
  double waterHardnessPpm = 120.0,
  double waterTds = 0.0,
  double waterPh = 0.0,
  double measuredTdsPct = 0.0,
  double measuredYieldPct = 0.0,
  double userSweetnessWeight = 0.5,
  double userAcidityWeight = 0.5,
  double rainProbabilityPct = 20.0,
  int userLotsCompleted = 5,
}) =>
    AIContext(
      userId: userId,
      userRole: role,
      module: module,
      varietyId: varietyId,
      altitudeMasl: altitudeMasl,
      region: region,
      ambientTempC: ambientTempC,
      ambientHumidityPct: ambientHumidityPct,
      processType: processType,
      currentPh: currentPh,
      mucilagoTempC: mucilagoTempC,
      fermentationHoursElapsed: fermentationHoursElapsed,
      fermentationStatus: fermentationStatus,
      mucilageState: mucilageState,
      brewMethod: brewMethod,
      roastLevel: roastLevel,
      roastDays: roastDays,
      waterHardnessPpm: waterHardnessPpm,
      waterTds: waterTds,
      waterPh: waterPh,
      measuredTdsPct: measuredTdsPct,
      measuredYieldPct: measuredYieldPct,
      userSweetnessWeight: userSweetnessWeight,
      userAcidityWeight: userAcidityWeight,
      rainProbabilityPct: rainProbabilityPct,
      userLotsCompleted: userLotsCompleted,
    );

/// Minimal AIRule factory for rule_engine tests.
AIRule rule({
  String id = 'TEST-001',
  String module = 'fermentation',
  int priority = 3,
  RuleLogic logic = RuleLogic.and,
  required List<RuleCondition> conditions,
  String? action,
  AlertLevel alertLevel = AlertLevel.info,
  double confidenceBase = 0.80,
  bool active = true,
  String? supersedes,
}) =>
    AIRule(
      id: id,
      module: module,
      name: id,
      priority: priority,
      logic: logic,
      conditions: conditions,
      outcome: RuleOutcome(
        action: action ?? id,
        alertLevel: alertLevel,
        confidenceBase: confidenceBase,
        explanationByRole: {
          'processor': 'Test explanation for $id',
          'barista': 'Barista explanation for $id',
        },
      ),
      active: active,
      supersedes: supersedes,
    );

RuleCondition numCond(
  String variable,
  ConditionOperator op,
  dynamic threshold, {
  double? max,
}) =>
    RuleCondition(
      variable: variable,
      operator: op,
      threshold: threshold,
      thresholdMax: max,
    );

RuleCondition strCond(String variable, ConditionOperator op, dynamic threshold) =>
    RuleCondition(variable: variable, operator: op, threshold: threshold);
