import 'package:freezed_annotation/freezed_annotation.dart';

part 'brew_recipe.freezed.dart';

@freezed
abstract class BrewRecipe with _$BrewRecipe {
  const factory BrewRecipe({
    required String method,
    required double doseG,
    required double waterG,
    required double ratio,
    required double waterTempC,
    required double bloomG,
    required int bloomSeconds,
    required double tdsTargetMin,
    required double tdsTargetMax,
    required double yieldTargetMin,
    required double yieldTargetMax,
    @Default([]) List<String> adjustmentsApplied,
    // Cold brew only: maceración en frío (horas). 0 = método caliente.
    @Default(0) int steepHours,
  }) = _BrewRecipe;
}
