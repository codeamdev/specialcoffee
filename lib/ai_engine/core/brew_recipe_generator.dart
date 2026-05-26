import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/brew_recipe.dart';

/// Genera recetas de preparación algorítmicamente (no usa el RuleEngine).
/// Aplica 6 ajustes secuenciales sobre una receta base por método.
///
/// Orden de ajustes (la temperatura puede ser limitada por múltiples factores):
///   1. Altitud → punto de ebullición (límite físico absoluto)
///   2. Nivel de tueste → temperatura
///   3. Días de tueste → bloom
///   4. Proceso del café → temperatura
///   5. Preferencias del usuario → ratio
///   6. Dureza del agua → temperatura
class BrewRecipeGenerator {
  static const Map<String, _BaseRecipe> _baseRecipes = {
    'v60':          _BaseRecipe(ratio: 15.5, tempC: 91.0, bloomRatio: 2.5, bloomSeconds: 35),
    'chemex':       _BaseRecipe(ratio: 16.5, tempC: 92.0, bloomRatio: 2.5, bloomSeconds: 40),
    'aeropress':    _BaseRecipe(ratio: 13.0, tempC: 85.0, bloomRatio: 3.0, bloomSeconds: 30),
    'french_press': _BaseRecipe(ratio: 15.0, tempC: 93.0, bloomRatio: 0,   bloomSeconds: 0),
    'espresso':     _BaseRecipe(ratio: 2.0,  tempC: 93.0, bloomRatio: 0,   bloomSeconds: 0),
    'moka':         _BaseRecipe(ratio: 7.5,  tempC: 0,    bloomRatio: 0,   bloomSeconds: 0),
    // Cold brew: concentrado 1:8, agua fría (4 °C), maceración 16 h (rango 12-24 h).
    // TDS objetivo para concentrado: 2.5–3.5 % (no aplica rango Golden Cup de filtro).
    // Los ajustes de temperatura y bloom se saltan en generate().
    'cold_brew':    _BaseRecipe(ratio: 8.0,  tempC: 4.0,  bloomRatio: 0,   bloomSeconds: 0, steepHours: 16),
  };

  static const double _defaultDoseG = 20.0;

  BrewRecipe generate(AIContext context) {
    final method = context.brewMethod ?? 'v60';
    final base = _baseRecipes[method] ?? _baseRecipes['v60']!;
    final isColdBrew = method == 'cold_brew';

    double tempC = base.tempC;
    double ratio = base.ratio;
    int bloomSeconds = base.bloomSeconds;
    final adjustments = <String>[];

    // Cold brew: temperatura y bloom no aplican — saltar ajustes 1-4 y 6.
    if (isColdBrew) {
      adjustments.add('Maceración en frío ${base.steepHours}h a ${tempC.toInt()}°C — '
          'sin calor, extracción lenta por tiempo');
      adjustments.add('Ratio 1:${ratio.toInt()} (concentrado) — diluir 1:1 con agua o leche para servir');
    }

    // ── Ajuste 1: Altitud → punto de ebullición (límite físico) ──────────────
    if (!isColdBrew && context.altitudeMasl > 1500 && base.tempC > 0) {
      final boilingPoint = 100 - (context.altitudeMasl / 300);
      final maxUsable = boilingPoint - 2.0;
      if (tempC > maxUsable) {
        tempC = maxUsable;
        adjustments.add(
          'Temperatura limitada a ${tempC.toStringAsFixed(1)}°C '
          '(ebullición a ${boilingPoint.toStringAsFixed(1)}°C a ${context.altitudeMasl} msnm)',
        );
      }
    }

    // ── Ajuste 2: Nivel de tueste → temperatura ───────────────────────────────
    if (!isColdBrew && base.tempC > 0) {
      final roastDelta = switch (context.roastLevel) {
        'light' => 1.0,
        'dark'  => -2.0,
        _       => 0.0,
      };
      if (roastDelta != 0) {
        final candidate = tempC + roastDelta;
        final boilingMax = (100 - context.altitudeMasl / 300) - 2.0;
        tempC = candidate.clamp(60.0, boilingMax);
        if (roastDelta > 0) adjustments.add('Temperatura subida +${roastDelta}°C por tueste claro');
        if (roastDelta < 0) adjustments.add('Temperatura bajada ${roastDelta}°C por tueste oscuro');
      }
    }

    // ── Ajuste 3: Días de tueste → bloom ──────────────────────────────────────
    if (base.bloomSeconds > 0) {
      if (context.roastDays <= 7) {
        bloomSeconds += 20;
        adjustments.add('Bloom +20s — café muy fresco (${context.roastDays} días de tueste, alto CO₂)');
      } else if (context.roastDays <= 14) {
        bloomSeconds += 10;
        adjustments.add('Bloom +10s — café fresco (${context.roastDays} días de tueste)');
      } else if (context.roastDays > 45) {
        bloomSeconds = (bloomSeconds * 0.75).round();
        adjustments.add('Bloom reducido — café añejo (${context.roastDays} días, poco CO₂)');
      }
    }

    // ── Ajuste 4: Proceso del café → temperatura ──────────────────────────────
    if (!isColdBrew && base.tempC > 0 && context.processType != null) {
      final processDelta = switch (context.processType!) {
        'anaerobic_lactic' => -1.0,
        'natural'          => -0.5,
        _                  => 0.0,
      };
      if (processDelta != 0) {
        tempC += processDelta;
        adjustments.add(
          'Temperatura ${processDelta}°C por proceso ${context.processType} '
          '(más delicado)',
        );
      }
    }

    // ── Ajuste 5: Preferencias del usuario → ratio ────────────────────────────
    if (context.userSweetnessWeight > 0.7) {
      ratio -= 0.5;
      adjustments.add(
        'Ratio más concentrado (1:${ratio.toStringAsFixed(1)}) — '
        'preferencia de dulzor del usuario',
      );
    } else if (context.userAcidityWeight > 0.7) {
      ratio += 0.5;
      adjustments.add(
        'Ratio más diluido (1:${ratio.toStringAsFixed(1)}) — '
        'preferencia de acidez brillante',
      );
    }

    // ── Ajuste 6: Dureza del agua → temperatura ───────────────────────────────
    if (!isColdBrew && base.tempC > 0) {
      if (context.waterHardnessPpm > 200) {
        tempC -= 1.0;
        adjustments.add('Temperatura -1°C — agua muy dura (${context.waterHardnessPpm.toInt()} ppm)');
      } else if (context.waterHardnessPpm > 0 && context.waterHardnessPpm < 50) {
        tempC += 0.5;
        adjustments.add('Temperatura +0.5°C — agua muy suave (${context.waterHardnessPpm.toInt()} ppm)');
      }
    }

    // ── Parámetros derivados ───────────────────────────────────────────────────
    final waterG = _defaultDoseG * ratio;
    final bloomG = base.bloomRatio > 0 ? _defaultDoseG * base.bloomRatio : 0.0;

    return BrewRecipe(
      method: method,
      doseG: _defaultDoseG,
      waterG: waterG,
      ratio: ratio,
      waterTempC: tempC,
      bloomG: bloomG,
      bloomSeconds: bloomSeconds,
      // Cold brew usa rango TDS de concentrado (2.5–3.5 %), no Golden Cup filtro.
      tdsTargetMin: isColdBrew ? 2.5 : context.userPreferredTdsMin,
      tdsTargetMax: isColdBrew ? 3.5 : context.userPreferredTdsMax,
      yieldTargetMin: 18.0,
      yieldTargetMax: 22.0,
      steepHours: base.steepHours,
      adjustmentsApplied: adjustments,
    );
  }
}

class _BaseRecipe {
  final double ratio;
  final double tempC;
  final double bloomRatio;
  final int bloomSeconds;
  final int steepHours;

  const _BaseRecipe({
    required this.ratio,
    required this.tempC,
    required this.bloomRatio,
    required this.bloomSeconds,
    this.steepHours = 0,
  });
}
