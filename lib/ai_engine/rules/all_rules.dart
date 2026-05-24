import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/brewing_rules.dart';
import 'package:special_coffee/ai_engine/rules/drying_rules.dart';
import 'package:special_coffee/ai_engine/rules/fermentation_rules.dart';
import 'package:special_coffee/ai_engine/rules/harvest_rules.dart';
import 'package:special_coffee/ai_engine/rules/process_selection_rules.dart';

/// Catálogo completo de reglas v1.0.
/// Cargado por el AIEngine en el arranque de la app.
/// En producción, las reglas vienen de Firebase Remote Config (JSON).
/// Esta lista actúa como fallback offline.
abstract final class AllRules {
  static List<AIRule> get all => [
    ...HarvestRules.all,
    ...ProcessSelectionRules.all,
    ...FermentationRules.all,
    ...DryingRules.all,
    ...BrewingRules.all,
  ];

  static const String version = '1.0.0';
}
