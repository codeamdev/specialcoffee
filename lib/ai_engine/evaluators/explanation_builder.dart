import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

/// Toma la plantilla de texto de la regla y la personaliza con los
/// valores reales del AIContext actual.
class ExplanationBuilder {
  String build({
    required AIRule rule,
    required AIContext context,
    required double confidence,
  }) {
    final roleKey = context.userRole.name;
    final template = rule.outcome.explanationByRole[roleKey]
        ?? rule.outcome.explanationByRole['processor']
        ?? rule.outcome.explanationByRole.values.first;

    // Calcular valor derivado de bloom para la plantilla
    final bloomSec = _calcBloomSeconds(context);
    final boilingPoint = (100 - context.altitudeMasl / 300).toStringAsFixed(1);

    var text = template
        .replaceAll('{altitude_masl}',          context.altitudeMasl.toString())
        .replaceAll('{ambient_temp_c}',          context.ambientTempC.toString())
        .replaceAll('{ambient_humidity_pct}',    context.ambientHumidityPct.toStringAsFixed(1))
        .replaceAll('{rain_probability_pct}',    context.rainProbabilityPct.toString())
        .replaceAll('{current_ph}',              context.currentPh.toStringAsFixed(1))
        .replaceAll('{mucilago_temp_c}',         context.mucilagoTempC.toString())
        .replaceAll('{brix_level}',              context.brixLevel.toString())
        .replaceAll('{cherry_color_pct}',        context.cherryColorPct.toString())
        .replaceAll('{current_humidity_pct}',    context.currentHumidityPct.toStringAsFixed(1))
        .replaceAll('{drying_day_number}',       context.dryingDayNumber.toString())
        .replaceAll('{fermentation_hours_elapsed}', context.fermentationHoursElapsed.toStringAsFixed(1))
        .replaceAll('{variety_id}',              _prettyVariety(context.varietyId))
        .replaceAll('{variety_sca_potential}',   context.varietyScaPotential.toString())
        .replaceAll('{process_type}',            _prettyProcess(context.processType ?? ''))
        .replaceAll('{measured_tds_pct}',        context.measuredTdsPct.toStringAsFixed(2))
        .replaceAll('{measured_yield_pct}',      context.measuredYieldPct.toStringAsFixed(1))
        .replaceAll('{user_preferred_tds_min}',  context.userPreferredTdsMin.toString())
        .replaceAll('{user_preferred_tds_max}',  context.userPreferredTdsMax.toString())
        .replaceAll('{user_sweetness_weight}',   context.userSweetnessWeight.toStringAsFixed(1))
        .replaceAll('{roast_days}',              context.roastDays.toString())
        .replaceAll('{bloom_seconds}',           bloomSec.toString())
        .replaceAll('{boiling_point}',           boilingPoint);

    // Advertencia de baja confianza — solo para roles técnicos
    if (confidence < 0.75 && context.userRole != UserRole.farmer) {
      text += '\n(Confianza: ${(confidence * 100).round()}% — '
          'algunos datos no fueron medidos directamente)';
    }

    return text;
  }

  String _prettyVariety(String id) => switch (id) {
    'var_geisha'   => 'Geisha',
    'var_castillo' => 'Castillo',
    'var_caturra'  => 'Caturra',
    'var_bourbon'  => 'Bourbon',
    'var_typica'   => 'Typica',
    'var_pink_bourbon' => 'Pink Bourbon',
    _              => id.replaceAll('var_', ''),
  };

  String _prettyProcess(String id) => switch (id) {
    'lavado'           => 'Lavado',
    'natural'          => 'Natural',
    'anaerobic_lactic' => 'Anaeróbico láctico',
    'honey_yellow'     => 'Honey amarillo',
    'honey_red'        => 'Honey rojo',
    _                  => id,
  };

  int _calcBloomSeconds(AIContext ctx) {
    int base = 35;
    if (ctx.roastDays <= 7) {
      base += 20;
    } else if (ctx.roastDays <= 14) {
      base += 10;
    } else if (ctx.roastDays > 45) {
      base = (base * 0.75).round();
    }
    return base;
  }
}
