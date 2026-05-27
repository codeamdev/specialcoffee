import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

/// Evalúa condiciones de una AIRule contra un AIContext.
/// Usa mapas de accessors en lugar de dart:mirrors — seguro en Flutter y compila en AOT.
class ConditionEvaluator {
  // ── Campos numéricos del AIContext accesibles por nombre de variable ────────
  static final Map<String, double Function(AIContext)> _numericAccessors = {
    'altitude_masl':               (c) => c.altitudeMasl.toDouble(),
    'ambient_temp_c':              (c) => c.ambientTempC,
    'ambient_humidity_pct':        (c) => c.ambientHumidityPct,
    'rain_probability_pct':        (c) => c.rainProbabilityPct,
    'uv_index':                    (c) => c.uvIndex,
    'brix_level':                  (c) => c.brixLevel,
    'cherry_color_pct':            (c) => c.cherryColorPct.toDouble(),
    'flotation_float_pct':         (c) => c.flotationFloatPct,
    'pct_aprovechamiento':         (c) => c.pctAprovechamiento,
    'hours_from_depulping_reference': (c) => c.hoursFromDepulpingReference,
    'fermentation_hours_elapsed':  (c) => c.fermentationHoursElapsed,
    'current_ph':                  (c) => c.currentPh,
    'mucilago_temp_c':             (c) => c.mucilagoTempC,
    'current_humidity_pct':        (c) => c.currentHumidityPct,
    'drying_day_number':           (c) => c.dryingDayNumber.toDouble(),
    'roast_days':                  (c) => c.roastDays.toDouble(),
    'water_hardness_ppm':          (c) => c.waterHardnessPpm,
    'measured_tds_pct':            (c) => c.measuredTdsPct,
    'measured_yield_pct':          (c) => c.measuredYieldPct,
    'user_preferred_tds_min':      (c) => c.userPreferredTdsMin,
    'user_preferred_tds_max':      (c) => c.userPreferredTdsMax,
    'user_sweetness_weight':       (c) => c.userSweetnessWeight,
    'user_acidity_weight':         (c) => c.userAcidityWeight,
    'user_ai_trust_score':         (c) => c.userAiTrustScore,
    'variety_sca_potential':       (c) => c.varietyScaPotential,
    'user_avg_sca':                (c) => c.userAvgSca,
    'user_avg_fermentation_h':     (c) => c.userAvgFermentationH,
    'user_lots_completed':         (c) => c.userLotsCompleted.toDouble(),
    'sca_total_score':             (c) => c.scaTotalScore,
    'user_specialty_rate_pct':     (c) => c.userSpecialtyRatePct,
  };

  // ── Campos de texto del AIContext ────────────────────────────────────────────
  static final Map<String, String Function(AIContext)> _stringAccessors = {
    'process_type':               (c) => c.processType ?? '',
    'fermentation_status':        (c) => c.fermentationStatus,
    'mucilage_state':             (c) => c.mucilageState,
    'brew_method':                (c) => c.brewMethod ?? '',
    'roast_level':                (c) => c.roastLevel,
    'variety_id':                 (c) => c.varietyId,
    'variety_fermentation_speed': (c) => c.varietyFermentationSpeed,
    'variety_sensitivity':        (c) => c.varietySensitivity,
    'region':                     (c) => c.region,
    'user_role':                  (c) => c.userRole.name,
    'module':                     (c) => c.module,
  };

  bool evaluate(RuleCondition condition, AIContext context) {
    final numericGetter = _numericAccessors[condition.variable];
    if (numericGetter != null) {
      return _evaluateNumeric(numericGetter(context), condition);
    }

    final stringGetter = _stringAccessors[condition.variable];
    if (stringGetter != null) {
      return _evaluateString(stringGetter(context), condition);
    }

    return false; // unknown variable — silently returns false in production
  }

  bool _evaluateNumeric(double value, RuleCondition c) {
    return switch (c.operator) {
      ConditionOperator.gt      => value > (c.threshold as num).toDouble(),
      ConditionOperator.gte     => value >= (c.threshold as num).toDouble(),
      ConditionOperator.lt      => value < (c.threshold as num).toDouble(),
      ConditionOperator.lte     => value <= (c.threshold as num).toDouble(),
      ConditionOperator.eq      => value == (c.threshold as num).toDouble(),
      ConditionOperator.neq     => value != (c.threshold as num).toDouble(),
      ConditionOperator.between => value >= (c.threshold as num).toDouble() && value <= c.thresholdMax!,
      ConditionOperator.inList  => (c.threshold as List).map((e) => (e as num).toDouble()).contains(value),
      ConditionOperator.notIn   => !(c.threshold as List).map((e) => (e as num).toDouble()).contains(value),
    };
  }

  bool _evaluateString(String value, RuleCondition c) {
    return switch (c.operator) {
      ConditionOperator.eq      => value == c.threshold.toString(),
      ConditionOperator.neq     => value != c.threshold.toString(),
      ConditionOperator.inList  => (c.threshold as List).map((e) => e.toString()).contains(value),
      ConditionOperator.notIn   => !(c.threshold as List).map((e) => e.toString()).contains(value),
      _ => false,
    };
  }
}
