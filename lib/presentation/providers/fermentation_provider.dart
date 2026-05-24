import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/models/alert.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'fermentation_provider.g.dart';

// ── State ─────────────────────────────────────────────────────────────────

class FermentationState {
  final String lotId;
  final String processType;
  final List<FermentationReading> readings;
  final List<Alert> activeAlerts;
  final List<Recommendation> recommendations;
  final double? projectedHoursRemaining;
  final bool isAnalyzing;

  const FermentationState({
    required this.lotId,
    required this.processType,
    this.readings = const [],
    this.activeAlerts = const [],
    this.recommendations = const [],
    this.projectedHoursRemaining,
    this.isAnalyzing = false,
  });

  bool get hasCriticalAlert =>
      activeAlerts.any((a) => a.level == AlertLevel.critical);
  bool get hasReadings => readings.isNotEmpty;
  FermentationReading? get lastReading =>
      readings.isEmpty ? null : readings.last;

  /// Use `projectedHoursRemaining: () => null` to explicitly clear the field.
  FermentationState copyWith({
    String? processType,
    List<FermentationReading>? readings,
    List<Alert>? activeAlerts,
    List<Recommendation>? recommendations,
    double? Function()? projectedHoursRemaining,
    bool? isAnalyzing,
  }) =>
      FermentationState(
        lotId: lotId,
        processType: processType ?? this.processType,
        readings: readings ?? this.readings,
        activeAlerts: activeAlerts ?? this.activeAlerts,
        recommendations: recommendations ?? this.recommendations,
        projectedHoursRemaining: projectedHoursRemaining != null
            ? projectedHoursRemaining()
            : this.projectedHoursRemaining,
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────

@riverpod
class FermentationNotifier extends _$FermentationNotifier {
  @override
  FermentationState build(String lotId) =>
      FermentationState(lotId: lotId, processType: 'lavado');

  Future<void> addReading({
    required double ph,
    required double tempC,
    required double hoursElapsed,
    String mucilageState = '',
  }) async {
    final newReading = FermentationReading(
      hoursElapsed: hoursElapsed,
      phValue: ph,
      tempC: tempC,
    );
    final updatedReadings = [...state.readings, newReading];

    final engine = await ref.read(aiEngineProvider.future);

    // AlertEngine — immediate threshold check (<1ms), always first
    final alerts = engine.checkFermentationReading(
      ph: ph,
      mucilagoTemp: tempC,
      processType: state.processType,
      lotId: state.lotId,
    );

    // Linear regression projection (requires ≥ 2 readings)
    final projection = updatedReadings.length >= 2
        ? engine.projectFermentationEnd(
            readings: updatedReadings,
            processType: state.processType,
          )
        : null;

    // Publish alerts + readings immediately before full analysis
    state = state.copyWith(
      readings: updatedReadings,
      activeAlerts: alerts,
      projectedHoursRemaining: () => projection,
      isAnalyzing: true,
    );

    // Full RuleEngine evaluation with complete context
    try {
      final userId  = ref.read(currentUserIdProvider);
      final roleStr = ref.read(currentUserProvider)?.role ?? 'farmer';
      final userRole = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.farmer,
      );
      final lot = await ref.read(lotByIdProvider(state.lotId).future);

      final aiContext = AIContext(
        userId: userId,
        userRole: userRole,
        module: 'fermentation',
        lotId: state.lotId,
        varietyId: lot?.varietyId ?? 'unknown',
        altitudeMasl: lot?.altitudeMasl ?? 1500,
        region: lot?.region ?? '',
        ambientTempC: lot?.ambientTempC ?? tempC,
        ambientHumidityPct: lot?.ambientHumidityPct ?? 75.0,
        processType: state.processType,
        fermentationStatus: 'active',
        fermentationHoursElapsed: hoursElapsed,
        currentPh: ph,
        mucilagoTempC: tempC,
        mucilageState: mucilageState,
        userLotsCompleted: 0,
      );

      final recs = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);
      state = state.copyWith(recommendations: recs, isAnalyzing: false);
    } catch (_) {
      state = state.copyWith(isAnalyzing: false);
    }
  }

  /// Process type can only be changed before the first reading is registered.
  void changeProcessType(String processType) {
    if (state.hasReadings) return;
    state = FermentationState(lotId: state.lotId, processType: processType);
  }

  void reset() =>
      state = FermentationState(lotId: state.lotId, processType: state.processType);
}
