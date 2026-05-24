import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'fermentation_provider.g.dart';

// ── State ─────────────────────────────────────────────────────────────────

class FermentationState {
  final String lotId;
  final String? sessionId;
  final String processType;
  final List<FermentationReading> readings;
  final List<Alert> activeAlerts;
  final List<Recommendation> recommendations;
  final double? projectedHoursRemaining;
  final bool isAnalyzing;

  const FermentationState({
    required this.lotId,
    this.sessionId,
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

  FermentationState copyWith({
    String? Function()? sessionId,
    String? processType,
    List<FermentationReading>? readings,
    List<Alert>? activeAlerts,
    List<Recommendation>? recommendations,
    double? Function()? projectedHoursRemaining,
    bool? isAnalyzing,
  }) =>
      FermentationState(
        lotId: lotId,
        sessionId: sessionId != null ? sessionId() : this.sessionId,
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
  FermentationState build(String lotId) {
    _loadPersistedSession(lotId);
    return FermentationState(lotId: lotId, processType: 'lavado');
  }

  void _loadPersistedSession(String lotId) {
    final repo = ref.read(fermentationLocalRepoProvider);
    Future(() async {
      try {
        final session = await repo.getActiveSession(lotId);
        if (session == null) return;
        final records = await repo.getReadings(session.id);
        final aiReadings = records
            .map((r) => FermentationReading(
                  hoursElapsed: r.hoursElapsed,
                  phValue: r.phValue,
                  tempC: r.mucilagoTempC,
                ))
            .toList();
        state = FermentationState(
          lotId: lotId,
          sessionId: session.id,
          processType: session.processType,
          readings: aiReadings,
        );
      } catch (_) {
        // Persistence unavailable — start fresh in-memory session
      }
    });
  }

  Future<void> addReading({
    required double ph,
    required double tempC,
    required double hoursElapsed,
    String mucilageState = '',
  }) async {
    // 1. Ensure session exists before doing any work
    final repo = ref.read(fermentationLocalRepoProvider);
    String? sessionId = state.sessionId;
    if (sessionId == null) {
      try {
        final session = await repo.createSession(
          lotId: state.lotId,
          processType: state.processType,
        );
        sessionId = session.id;
        state = state.copyWith(sessionId: () => sessionId);
      } catch (_) {
        // Proceed without persistence if DB is unavailable
      }
    }

    final readingNumber = state.readings.length + 1;
    final newReading = FermentationReading(
      hoursElapsed: hoursElapsed,
      phValue: ph,
      tempC: tempC,
    );
    final updatedReadings = [...state.readings, newReading];

    final engine = await ref.read(aiEngineProvider.future);

    // AlertEngine — immediate threshold check, always first
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

    state = state.copyWith(
      readings: updatedReadings,
      activeAlerts: alerts,
      projectedHoursRemaining: () => projection,
      isAnalyzing: true,
    );

    // Full RuleEngine evaluation with complete context
    try {
      final userId = ref.read(currentUserIdProvider);
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

    // Persist reading to Drift (after AI analysis — fire and track errors silently)
    if (sessionId != null) {
      try {
        final alertLevel =
            alerts.isEmpty ? 'none' : alerts.first.level.name;
        final alertRuleId = alerts.isEmpty ? null : alerts.first.ruleId;
        await repo.addReading(
          sessionId: sessionId,
          lotId: state.lotId,
          readingNumber: readingNumber,
          hoursElapsed: hoursElapsed,
          phValue: ph,
          mucilagoTempC: tempC,
          mucilageState: mucilageState.isEmpty ? 'liquid' : mucilageState,
          aiAlertLevel: alertLevel,
          aiAlertRuleId: alertRuleId,
          aiProjectedEndH: projection,
        );
      } catch (_) {}
    }
  }

  /// Process type can only change before the first reading.
  void changeProcessType(String processType) {
    if (state.hasReadings) return;
    state = FermentationState(lotId: state.lotId, processType: processType);
  }

  void reset() {
    final sessionId = state.sessionId;
    if (sessionId != null) {
      final repo = ref.read(fermentationLocalRepoProvider);
      final phFinal =
          state.readings.isEmpty ? 0.0 : state.readings.last.phValue;
      final durationH =
          state.readings.isEmpty ? 0.0 : state.readings.last.hoursElapsed;
      Future(() => repo.closeSession(
            sessionId: sessionId,
            endReason: 'reset',
            actualDurationH: durationH,
            phFinal: phFinal,
          ));
    }
    state = FermentationState(lotId: state.lotId, processType: state.processType);
  }
}
