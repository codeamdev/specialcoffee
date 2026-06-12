/// Single source of truth for all agronomic threshold values used by AI rules.
/// Updating a constant here propagates to every rule that references it.
///
/// Calibración completada (2026-06-03):
///   D-2  Intervalos cosecha     — Cenicafé AT No. 420 (2012); ver harvest_repository_local.dart
///   D-5  Flotación              — Manual del Cafetero Colombiano FNC/Cenicafé
///   D-6  °Brix cereza           — SCA + Manual del Cafetero (Cenicafé usa % madurez visual)
///   D-7  Retraso despulpado     — Manual del Cafetero FNC/Cenicafé, 4ª ed.
///   D-13 Lavado                 — Manual del Cafetero FNC/Cenicafé, cap. Beneficio Húmedo
///   D-14 Secado expandido       — Manual del Cafetero + literatura Cenicafé de secado solar
abstract final class CoffeeThresholds {
  // ── °Brix cereza ─────────────────────────────────────────────────────────────
  // Fuente: SCA Specialty Coffee Standards (cosecha y madurez) + Manual del Cafetero
  // Colombiano (FNC/Cenicafé). Cenicafé usa % de cerezas rojas/amarillas como indicador
  // primario de madurez — los rangos Brix aquí son la contraparte instrumental, consistentes
  // con los valores reportados en estudios de madurez de café colombiano.
  // D-6: calibrado. Cenicafé no publica rangos Brix por variedad en ATs individuales;
  //      el rango 18–24°Brix es el estándar SCA adoptado como referencia para café de
  //      especialidad colombiano en literatura de procesamiento.
  static const double brixCriticalMax = 15.0;  // < 15    → cereza inmadura — bloquear cosecha
  static const double brixLowMin      = 15.0;  // 15–17.9 → subóptima — warning
  static const double brixLowMax      = 17.9;
  static const double brixOptimalMin  = 18.0;  // 18–24   → rango specialty
  static const double brixOptimalMax  = 24.0;
  // > brixOptimalMax → sobremadurez — cosechar urgente

  // ── Madurez visual de cereza (cherry_color_pct = % cerezas rojas/amarillas) ──
  // Fuente: FNC/Cenicafé. Manual del Cafetero Colombiano, 4ª ed., cap. Cosecha.
  // "El café debe cosecharse cuando al menos el 95% de las cerezas estén maduras
  // (rojas o amarillas según variedad). El 'falto' aceptable es máximo 2–5%."
  // cherryColorOptimalMin corregido de 75 → 95 (E-2, commit 3c69afc).
  static const double cherryColorOptimalMin       = 95.0;  // ≥95% maduras → cosechar
  static const double cherryColorGreenWarnMin     = 90.0;  // 90–94.9% → verde 5–10% → warning
  static const double cherryColorGreenWarnMax     = 94.9;
  static const double cherryColorGreenCriticalMax = 90.0;  // < 90% → verde >10% → critical

  // ── Lluvia (urgencia de cosecha) ─────────────────────────────────────────────
  // Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé) — lluvia intensa sobre cerezas
  // maduras induce fermentación en árbol y absorción de agua que diluye azúcares.
  // Riesgo documentado a partir del 70% de probabilidad de precipitación.
  static const double rainUrgencyPct = 70.0;

  // ── Flotación (% kg flotantes / kg entrada en clasificación) ─────────────────
  // Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé), cap. Beneficio.
  // Clasificación por densidad usando agua: los granos flotantes corresponden a
  // cerezas vanas, brocadas, sobrefermentadas o con daño físico.
  // Rangos de referencia para beneficiaderos colombianos con recolección selectiva:
  //   > 20%: indica problema sistémico de calidad en recolección — revisar el lote.
  //   > 35%: lote con defectos mayoritarios — rechazo o reproceso obligatorio.
  // D-5: calibrado con Manual del Cafetero FNC/Cenicafé.
  static const double flotationWarnPct     = 20.0;
  static const double flotationCriticalPct = 35.0;

  // ── Aprovechamiento de clasificación (% kg_seleccionado / kg_entrada) ────────
  // Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé). Aprovechamiento esperado
  // en fincas cafeteras colombianas con cosecha selectiva: 60–75%.
  // < 60%: indica ineficiencia (exceso de verdes, brocados o daño por recolección).
  // D-5: calibrado.
  static const double aprovechamientoMinPct = 60.0;

  // ── Retraso al despulpado (horas desde referencia: clasificación / último pase)
  // Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé, 4ª ed.), cap. Beneficio Húmedo.
  // "Despulpar el café el mismo día de la recolección, idealmente antes de las 6 horas.
  //  Después de 8 horas el riesgo de fermentación pre-despulpado genera defectos
  //  organolépticos irreversibles (vinagre, fermento)."
  // Nota: Geisha y variedades de alta sensibilidad requieren ≤ 4–6h por mayor fragilidad
  // del mucílago; la regla de 8h es un conservador aplicable al grueso de variedades.
  // D-7: calibrado con Manual del Cafetero FNC/Cenicafé.
  static const double depulpingWarnH     = 6.0;  // > 6h → riesgo fermentación indeseada
  static const double depulpingCriticalH = 8.0;  // > 8h → daño organoléptico probable

  // ── Lavado (washing) ─────────────────────────────────────────────────────────
  // Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé), cap. Beneficio Húmedo.
  // Sistema de beneficio húmedo colombiano (fermentación + lavado):
  //
  //   Temperatura agua ≤ 25°C: el Manual especifica usar "agua fresca y limpia".
  //     < 15°C → lavado ineficiente: reducción de la actividad enzimática y menor
  //       dispersión del mucílago en agua fría.
  //     > 25°C → favorece proliferación bacteriana y acelera reacciones enzimáticas
  //       no controladas — riesgo de defecto en taza (agrio, fermento).
  //   Cambios ≥ 2: mínimo del Manual del Cafetero para remoción completa del mucílago
  //     post-fermentación. 3 cambios es el estándar recomendado para café de especialidad.
  //   pH efluente ≤ 5.5: indicador de fermentación completa; el mucílago correctamente
  //     degradado produce efluente ácido (pH 3.5–5.0). pH > 5.5 indica mucílago
  //     sin degradar completamente.
  // D-13: calibrado con Manual del Cafetero FNC/Cenicafé.
  static const double washingWaterTempCMin   = 15.0; // < 15°C → lavado ineficiente (info)
  static const double washingWaterTempCMax   = 30.0; // > 30°C → riesgo bacteriano (warning)
  static const int    washingMinWaterChanges = 2;    // < 2 cambios → lavado incompleto
  static const double washingEffluentPhWarn  = 5.5;  // > 5.5 → fermentación posiblemente incompleta

  // ── Fermentación Honey (honey_yellow — sin agua, mucílago sobre el grano) ────
  // C-2: umbrales de referencia — calibrar con datos de campo colombiano (Nariño/Huila).
  // Rango típico honey colombiano: 48–96h según altitud/temperatura/variedad.
  // Sin agua → temperatura puede subir más que en lavado (sin mecanismo de enfriamiento).
  // Fuente: literatura specialty (WCR, SCA); consistente con práctica procesadores honey Colombia.
  static const double honeyTempHighC    = 28.0; // > 28°C → riesgo sobrecalentamiento sin agua
  static const double honeyMaxH         = 96.0; // > 96h  → riesgo sobrefermentación honey
  static const double honeyEndpointMinH = 48.0; // ≥ 48h + mucílago seco → endpoint honey

  // ── Fermentación Anaeróbica (anaerobic_lactic — tanque sellado) ─────────────
  // Proceso láctico sellado. pH objetivo: 3.8–4.2 para especialidad (láctico limpio).
  // pH < 3.8 → actividad acido-láctica intensa; < 3.5 → sobrefermentación irreversible.
  // Temperatura baja (< 20°C) → fermentación más lenta y controlada → mayor complejidad.
  // Fuente: literatura specialty (WCR Fermentation Research) + práctica procesadores Colombia.
  static const double anaerobicPhCritical = 3.5;  // < 3.5 → sobrefermentación láctica
  static const double anaerobicPhWarnLow  = 3.8;  // 3.5–3.8 → zona de monitoreo activo
  static const double anaerobicTempMaxC   = 20.0; // > 20°C → demasiado caliente para anaeróbico
  static const double anaerobicMinH       = 48.0; // < 48h → proceso incompleto (usar between 0.1–47.9)

  // ── Trilla (rendimiento kg almendra verde / kg pergamino seco) ───────────────
  // Fuente: SCA Coffee Standards — rendimiento esperado 18–22% para café arábica.
  // Consistente con estudios Cenicafé de trilla por variedad colombiana:
  //   Castillo ~20%, Colombia ~19–21%, variedades especiales 18–22%.
  // < 18%: pérdidas críticas (grano defectuoso, sobresecado o ajuste incorrecto de trilladora).
  // > 22%: revisar pesaje (posible pergamino húmedo o equipo mal calibrado).
  // Calibrado. (Intervalos entre pases de cosecha → D-2 en harvest_repository_local.dart.)
  static const double millingYieldCriticalLow = 18.0;
  static const double millingYieldHighInfo    = 22.0;

  // ── Preparación — frescura del tueste ────────────────────────────────────────
  // Fuente: SCA Brewing Standards (2019) + literatura especialidad (BH Education,
  // Scott Rao "The Coffee Brewer's Companion").
  // Filtro: reposo ideal 5–21 días post-tueste. < 5 días → CO₂ residual interfiere
  //   con la extracción (bloom insuficiente, café "cerrado").
  // Espresso: reposo ideal 10–30 días. Espresso tolera más degassing → umbral más alto.
  // > 45 días filtro / > 30 días espresso → oxidación significativa (rancio, plano).
  // AUDIT: calibrado con SCA Standards 2019 — sin datos Cenicafé específicos para tueste fresco.
  static const int roastDaysVeryFreshFilter    = 5;  // < 5d filtro → reposo insuficiente (warning)
  static const int roastDaysFreshEspresso      = 10; // < 10d espresso → reposo insuficiente (info)
  static const int roastDaysStaleFilter        = 45; // > 45d filtro → oxidación (warning)
  static const int roastDaysStaleEspresso      = 30; // > 30d espresso → oxidación (info)

  // ── Preparación — calidad del agua (SCA Water Standards 2018) ────────────────
  // Fuente: SCA Water Quality Handbook (2018). Estándares para agua de preparación
  // de café de especialidad. Los rangos siguientes son los "Recommended" de SCA:
  //   TDS (Total Dissolved Solids): óptimo 75–250 mg/L (ppm).
  //     < 75 ppm: agua demasiado pura → subextrae minerales, café plano y apagado.
  //     > 250 ppm: dureza excesiva → sabor metálico, incrustaciones en equipos,
  //       inhibe la extracción de ácidos aromáticos.
  //   pH: óptimo 6.5–7.5 (cercano a neutro).
  //     < 6.5: agua ácida → sobreextrae ácidos, puede dañar juntas y calderas.
  //     > 7.5: agua alcalina → amortigua la acidez del café (extracción plana).
  // AUDIT: calibrado con SCA Water Quality Handbook 2018.
  static const double waterTdsOptimalMin = 75.0;  // ppm — por debajo: agua demasiado pura
  static const double waterTdsOptimalMax = 250.0; // ppm — por encima: dureza excesiva
  static const double waterPhOptimalMin  = 6.5;   // pH  — por debajo: demasiado ácida
  static const double waterPhOptimalMax  = 7.5;   // pH  — por encima: demasiado alcalina

  // ── Secado — umbrales expandidos (C-1) ───────────────────────────────────────
  // Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé), cap. Beneficio y Secado.
  // Cenicafé. Puerta-Quintero, G.I. Calidad del café y factores que la afectan.
  // Literatura Cenicafé de secado solar y en cama africana:
  //
  //   Temperatura ambiental > 35°C: agrietamiento del grano documentado en estudios
  //     Cenicafé de secado solar — el calor excesivo genera gradientes internos que
  //     fracturan el endospermo.
  //   Humedad relativa > 80%: límite para secado eficiente en Colombia; por encima de
  //     este valor la tasa de evaporación del grano cae por debajo de la reabsorción
  //     de humedad ambiental — el proceso se detiene o revierte.
  //   Humedad relativa > 85%: riesgo documentado de hongos (Aspergillus, Fusarium)
  //     en granos con HR > 12% expuestos a ambiente muy húmedo — detener secado exterior.
  //   Volteo desde día 3 con grano > 40% HR: práctica estándar Manual del Cafetero
  //     para uniformizar el frente de secado y prevenir encostrado superficial.
  // D-14: calibrado con Manual del Cafetero FNC/Cenicafé y literatura Cenicafé de secado.
  static const double dryingHeatStressTempC    = 35.0; // > 35°C amb → riesgo agrietamiento (patio/camas)
  static const double dryingHighAmbHumidityPct = 80.0; // > 80% HR → secado ineficiente (warning)
  static const double dryingCritAmbHumidityPct = 85.0; // > 85% HR → riesgo hongos (critical)
  static const double dryingTurningMinGrainHum = 40.0; // grano > 40% → voltear necesario
  static const int    dryingTurningStartDay    = 3;    // desde día 3 → voltear activamente

  // ── Secado mecánico ──────────────────────────────────────────────────────────
  // Fuente: Manual del Cafetero Colombiano (FNC/Cenicafé) 9ª ed., cap. Beneficio/Secado Mecánico.
  // Temperatura del aire > 45°C: fisuras internas ("grano cristalizado") documentadas en
  //   grano de café pergamino húmedo — gradiente de vapor destruye la estructura del endospermo.
  // Temperatura del aire > 40°C con grano semiseco (< 30% HR): acelera el gradiente de humedad.
  // D-15: calibrado con Manual del Cafetero FNC/Cenicafé 9ª ed.
  static const double dryingMechWarnTempC  = 40.0; // °C — secador mecánico: inicio de riesgo térmico
  static const double dryingMechCritTempC  = 45.0; // °C — secador mecánico: límite máximo absoluto
  static const int    dryingMechSlowDay    = 5;    // días — mecánico aún > 30%: proceso lento (D-15)

  // ── Camas africanas ──────────────────────────────────────────────────────────
  // D-15: estimación basada en condiciones típicas colombianas (Huila, Nariño).
  // Camas africanas con circulación de aire: típicamente 15–20 días para café pergamino.
  // Más de 18 días con > 15% HR indica problema de carga o condiciones adversas.
  static const int    dryingCamasSlowDay   = 18;   // días — camas africanas aún > 15%: muy lento (D-15)
}
