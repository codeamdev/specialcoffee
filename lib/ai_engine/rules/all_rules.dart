import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/brewing_rules.dart';
import 'package:special_coffee/ai_engine/rules/classification_rules.dart';
import 'package:special_coffee/ai_engine/rules/cupping_rules.dart';
import 'package:special_coffee/ai_engine/rules/depulping_rules.dart';
import 'package:special_coffee/ai_engine/rules/drying_rules.dart';
import 'package:special_coffee/ai_engine/rules/fermentation_rules.dart';
import 'package:special_coffee/ai_engine/rules/harvest_rules.dart';
import 'package:special_coffee/ai_engine/rules/process_selection_rules.dart';
import 'package:special_coffee/ai_engine/rules/washing_rules.dart';

abstract final class AllRules {
  static List<AIRule> get all => [
    ...HarvestRules.all,
    ...ClassificationRules.all,
    ...DepulpingRules.all,
    ...ProcessSelectionRules.all,
    ...FermentationRules.all,
    ...WashingRules.all,
    ...DryingRules.all,
    ...BrewingRules.all,
    ...CuppingRules.all,
  ];

  static const String version = '1.2.0';
}
