import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

/// Ajusta la confianza base de una regla según la calidad y riqueza
/// de los datos disponibles en el AIContext.
class ConfidenceAdjuster {
  double adjust({
    required double baseConfidence,
    required AIRule rule,
    required AIContext context,
  }) {
    double delta = 0.0;

    // ── Bonificaciones por datos de instrumento (vs estimación visual) ────────
    if (rule.tags.contains('ph') && context.currentPh > 0) {
      delta += 0.03; // pH medido con instrumento
    }
    if (rule.tags.contains('brix') && context.brixLevel > 0) {
      delta += 0.03; // Brix medido con refractómetro
    }

    // ── Bonificaciones por historial del usuario ───────────────────────────────
    if (context.userLotsCompleted > 5) delta += 0.02;
    if (context.userLotsCompleted > 20) delta += 0.02;

    // ── Bonificación por datos climáticos reales ───────────────────────────────
    if (context.rainProbabilityPct > 0) delta += 0.01;

    // ── Penalización por datos faltantes críticos ──────────────────────────────
    if (context.brixLevel == 0 && rule.tags.contains('harvest')) {
      delta -= 0.08; // recomendar cosecha sin Brix es arriesgado
    }
    if (context.ambientTempC == 20.0 && rule.tags.contains('fermentation')) {
      delta -= 0.05; // 20°C es el default — posiblemente no fue medido
    }
    if (context.varietyId == 'var_unknown') {
      delta -= 0.10; // variedad desconocida reduce confianza general
    }

    return (baseConfidence + delta).clamp(0.30, 0.99);
  }
}
