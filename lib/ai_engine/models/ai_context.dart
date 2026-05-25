import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_context.freezed.dart';
part 'ai_context.g.dart';

enum UserRole { farmer, processor, barista, entrepreneur }

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
    // Horas desde el punto de referencia (clasificación → último pase → 0 si ninguno).
    // 0.0 significa "sin referencia" — las reglas DEPU-RETRASO-* no disparan.
    @Default(0.0) double hoursSinceClassification,

    // ── PREPARACIÓN ───────────────────────────────────────────────
    String? brewMethod,               // 'v60'|'espresso'|'chemex'|'aeropress'|'french_press'
    @Default('') String roastLevel,   // 'light'|'medium'|'dark'
    @Default(0) int roastDays,
    @Default(0.0) double waterHardnessPpm,
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

    // ── HISTORIAL (personalización) ───────────────────────────────
    @Default(0.0) double userAvgSca,
    @Default(0.0) double userAvgFermentationH,
    @Default(0) int userLotsCompleted,

    // ── CATACIÓN ──────────────────────────────────────────────────
    @Default(0.0) double scaTotalScore,
    @Default(0.0) double userSpecialtyRatePct,
  }) = _AIContext;

  factory AIContext.fromJson(Map<String, dynamic> json) =>
      _$AIContextFromJson(json);
}
