import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_context.freezed.dart';
part 'ai_context.g.dart';

/// Roles del sistema. Los tokens JWT viejos pueden enviar 'farmer'|'processor'|'entrepreneur';
/// usar [roleFromString] para mapearlos — nunca leer .name del backend directamente.
enum UserRole { producer, coffeeMaster, brandManager, producerIntegral, barista, admin }

/// Mapeo backward-compatible: backend viejos → enum nuevo.
UserRole roleFromString(String s) => switch (s) {
  'farmer' || 'processor'    => UserRole.producer,
  'coffee_master'            => UserRole.coffeeMaster,
  'brand_manager'            => UserRole.brandManager,
  'producer_integral'        => UserRole.producerIntegral,
  'barista'                  => UserRole.barista,
  'admin'                    => UserRole.admin,
  _                          => UserRole.producer,
};

@freezed
abstract class AIContext with _$AIContext {
  const factory AIContext({
    // ── IDENTIDAD ────────────────────────────────────────────────
    required String userId,
    required UserRole userRole,
    required String module, // 'harvest'|'fermentation'|'drying'|'brewing'|'process_selection'

    // ── FINCA ────────────────────────────────────────────────────
    String? lotId,
    String? plotId,
    required String varietyId,       // 'var_castillo' | 'var_geisha' | ...
    required int altitudeMasl,
    required String region,

    // ── AMBIENTE ─────────────────────────────────────────────────
    required double ambientTempC,
    required double ambientHumidityPct,
    @Default(0.0) double rainProbabilityPct,
    @Default(0.0) double uvIndex,

    // ── PROCESO ACTIVO ────────────────────────────────────────────
    String? processType,              // 'lavado'|'natural'|'honey_yellow'|'anaerobic_lactic'
    @Default('') String fermentationStatus, // 'active'|'completed'|''
    @Default(0.0) double fermentationHoursElapsed,
    @Default(0.0) double currentPh,
    @Default(0.0) double mucilagoTempC,
    @Default('') String mucilageState, // 'liquid'|'viscous'|'gelatinous'|'dry'
    @Default(0.0) double currentHumidityPct,
    @Default(0) int dryingDayNumber,
    @Default('patio') String dryingMethod, // 'patio'|'camas_africanas'|'mecanico'

    // ── COSECHA ───────────────────────────────────────────────────
    @Default(0.0) double brixLevel,
    @Default(0) int cherryColorPct,

    // ── CLASIFICACIÓN ─────────────────────────────────────────────
    // flotationFloatPct: % kg flotantes / kg entrada (para CLAS-FLOAT-* rules)
    // pctAprovechamiento: % kg_seleccionado / kg_entrada (para CLAS-APROVECH-* rules)
    // DISTINTO del rendimiento de trilla (Ítem #9).
    @Default(0.0) double flotationFloatPct,
    @Default(0.0) double pctAprovechamiento,

    // ── DESPULPADO ────────────────────────────────────────────────
    // Horas desde el punto de referencia (classification | harvest_pass | none).
    // 0.0 significa "sin referencia" — las reglas DEPU-RETRASO-* no disparan.
    @Default(0.0) double hoursFromDepulpingReference,

    // ── PREPARACIÓN ───────────────────────────────────────────────
    String? brewMethod,               // 'v60'|'espresso'|'chemex'|'aeropress'|'french_press'
    @Default('') String roastLevel,   // 'light'|'medium'|'dark'
    @Default(0) int roastDays,
    @Default(0.0) double waterHardnessPpm,
    // Estándares SCA Water 2018: TDS óptimo 75–250 ppm, pH óptimo 6.5–7.5.
    // 0.0 = no medido; reglas BREW-WATER-* usan between 0.1–X para evitar falsos positivos.
    @Default(0.0) double waterTds,
    @Default(0.0) double waterPh,
    @Default(0.0) double measuredTdsPct,
    @Default(0.0) double measuredYieldPct,

    // ── PERFIL APRENDIDO DEL USUARIO ─────────────────────────────
    @Default(1.30) double userPreferredTdsMin,
    @Default(1.38) double userPreferredTdsMax,
    @Default(0.5) double userSweetnessWeight,
    @Default(0.5) double userAcidityWeight,
    @Default(0.78) double userAiTrustScore,

    // ── VARIEDAD (enriquecida desde catálogo) ────────────────────
    @Default('medium') String varietyFermentationSpeed, // 'slow'|'medium'|'fast'
    @Default('medium') String varietySensitivity,       // 'low'|'medium'|'high'|'very_high'
    @Default(85.0) double varietyScaPotential,

    // ── TRILLA ────────────────────────────────────────────────────
    // 0.0 = no registrado; reglas MILL-* usan between para evitar falsos positivos.
    @Default(0.0) double millingYieldPct,

    // ── HISTORIAL (personalización) ───────────────────────────────
    @Default(0.0) double userAvgSca,
    @Default(0.0) double userAvgFermentationH,
    // Duración del último lote completado; 0.0 = sin historial.
    @Default(0.0) double lastLotFermentationH,
    @Default(0) int userLotsCompleted,

    // ── LAVADO ────────────────────────────────────────────────────
    // 0.0 en washingWaterTempC y washingEffluentPh significa "no registrado".
    // Las reglas WASH-TEMP-LOW y WASH-EFFLUENT usan between/gt para evitar
    // falsos positivos con el valor por defecto.
    @Default(0.0) double washingWaterTempC,
    @Default(0)   int    washingWaterChanges,
    @Default(0.0) double washingEffluentPh,

    // ── CATACIÓN ──────────────────────────────────────────────────
    @Default(0.0) double scaTotalScore,
    @Default(0.0) double userSpecialtyRatePct,
  }) = _AIContext;

  factory AIContext.fromJson(Map<String, dynamic> json) =>
      _$AIContextFromJson(json);
}
