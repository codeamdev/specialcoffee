/// Single source of truth for all agronomic threshold values used by AI rules.
/// Updating a constant here propagates to every rule that references it.
///
/// Calibration debts are marked inline — see project memory D-5.
abstract final class CoffeeThresholds {
  // ── °Brix cereza ─────────────────────────────────────────────────────────────
  // Base: conocimiento general SCA / specialty coffee processing.
  // D-6: verificar con publicación específica de Cenicafé (Avances Técnicos).
  static const double brixCriticalMax = 15.0;  // < 15    → bloquear
  static const double brixLowMin      = 15.0;  // 15–17.9 → subóptimo
  static const double brixLowMax      = 17.9;
  static const double brixOptimalMin  = 18.0;  // 18–24   → specialty
  static const double brixOptimalMax  = 24.0;
  // > brixOptimalMax → sobremadurez urgente

  // ── Madurez visual de cereza (cherry_color_pct = % cerezas rojas/amarillas) ──
  // D-3 / Estándar FNC: "falto" máx. 2-5 % → cosechar solo con ≥95 % maduras.
  // cherryColorOptimalMin era 75 — corregido (E-2): 75 % maduro = 25 % verde,
  // incompatible con el estándar de especialidad y causaba HARVEST_NOW simultáneo
  // con STOP_GREEN_HARVEST cuando el verde era 5-25 %.
  static const double cherryColorOptimalMin       = 95.0;  // ≥95% maduras → ≤5% verde → cosechar
  static const double cherryColorGreenWarnMin     = 90.0;  // 90–94.9% → verde 5–10%
  static const double cherryColorGreenWarnMax     = 94.9;
  static const double cherryColorGreenCriticalMax = 90.0;  // < 90%   → verde >10%

  // ── Lluvia (urgencia de cosecha) ─────────────────────────────────────────────
  static const double rainUrgencyPct = 70.0;

  // ── Flotación (% kg flotantes / kg entrada en clasificación) ─────────────────
  // D-5: umbrales estimados de referencia — calibrar con Cenicafé / FNC.
  static const double flotationWarnPct     = 20.0;
  static const double flotationCriticalPct = 35.0;

  // ── Aprovechamiento de clasificación (% kg_seleccionado / kg_entrada) ────────
  // DISTINTO del rendimiento de trilla (kg pergamino seco / kg cereza ≈ 18–22%)
  // que corresponde al Ítem #9. D-5: umbral estimado — calibrar.
  static const double aprovechamientoMinPct = 60.0;

  // ── Retraso al despulpado (horas desde referencia → clasificación o último pase)
  // critical 8h: viene de C-1 (auditoría del proyecto).
  // warning  6h: escalón preventivo añadido; sin respaldo documental propio.
  // D-7: calibrar ambos con Cenicafé — el threshold puede variar por variedad
  //       (ej. Geisha podría requerir 4–6h por mayor sensibilidad a fermentación).
  static const double depulpingWarnH     = 6.0;
  static const double depulpingCriticalH = 8.0;

  // ── Lavado (washing) ──────────────────────────────────────────────────────
  // D-13: todos los umbrales son estimaciones de campo — calibrar con Cenicafé.
  // Temperatura de agua: 15–30°C rango práctico de beneficio húmedo.
  // Cambios de agua: ≥ 2 es el mínimo estándar para café de especialidad.
  // pH efluente: valor > 5.5 sugiere fermentación incompleta (mucílago residual).
  static const double washingWaterTempCMin   = 15.0; // < 15°C → eficiencia reducida
  static const double washingWaterTempCMax   = 30.0; // > 30°C → riesgo de daño al grano
  static const int    washingMinWaterChanges = 2;    // < 2 → lavado incompleto
  static const double washingEffluentPhWarn  = 5.5;  // > 5.5 → fermentación posiblemente incompleta

  // ── Secado — umbrales nuevos (C-1) ──────────────────────────────────────
  // D-14: todos son estimaciones de referencia — calibrar con Cenicafé
  //       Avances Técnicos (publicaciones de secado en cama africana / solar).
  static const double dryingHeatStressTempC    = 35.0; // > 35°C amb → riesgo agrietamiento del grano
  static const double dryingHighAmbHumidityPct = 80.0; // > 80% HR → riesgo hongos (warning)
  static const double dryingCritAmbHumidityPct = 85.0; // > 85% HR → riesgo hongos (high); supersede warning
  static const double dryingTurningMinGrainHum = 40.0; // grano > 40% humedad → voltear necesario
  static const int    dryingTurningStartDay    = 3;    // desde día 3 en adelante → voltear activamente
}
