import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/core/notifications/notification_service.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'fermentation_provider.g.dart';

// â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class FermentationState {
  final String lotId;
  final String? sessionId;
  final String processType;
  final DateTime? sessionStartedAt;
  final List<FermentationReading> readings;
  final List<Alert> activeAlerts;
  final List<Recommendation> recommendations;
  final double? projectedHoursRemaining;
  final bool isAnalyzing;
  final String? error;

  const FermentationState({
    required this.lotId,
    this.sessionId,
    required this.processType,
    this.sessionStartedAt,
    this.readings = const [],
    this.activeAlerts = const [],
    this.recommendations = const [],
    this.projectedHoursRemaining,
    this.isAnalyzing = false,
    this.error,
  });

  bool get hasCriticalAlert =>
      activeAlerts.any((a) => a.level == AlertLevel.critical);
  bool get hasReadings => readings.isNotEmpty;
  FermentationReading? get lastReading =>
      readings.isEmpty ? null : readings.last;

  FermentationState copyWith({
    String? Function()? sessionId,
    String? processType,
    DateTime? Function()? sessionStartedAt,
    List<FermentationReading>? readings,
    List<Alert>? activeAlerts,
    List<Recommendation>? recommendations,
    double? Function()? projectedHoursRemaining,
    bool? isAnalyzing,
    String? Function()? error,
  }) =>
      FermentationState(
        lotId: lotId,
        sessionId: sessionId != null ? sessionId() : this.sessionId,
        processType: processType ?? this.processType,
        sessionStartedAt: sessionStartedAt != null ? sessionStartedAt() : this.sessionStartedAt,
        readings: readings ?? this.readings,
        activeAlerts: activeAlerts ?? this.activeAlerts,
        recommendations: recommendations ?? this.recommendations,
        projectedHoursRemaining: projectedHoursRemaining != null
            ? projectedHoursRemaining()
            : this.projectedHoursRemaining,
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
        error: error != null ? error() : this.error,
      );
}

// â”€â”€ Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          sessionStartedAt: session.createdAt,
          readings: aiReadings,
        );
      } catch (e, st) {
        if (kDebugMode) debugPrint('[FermentationProvider] _loadPersistedSession: $e\n$st');
        // Persistence unavailable â€” start fresh in-memory session
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
        state = state.copyWith(
          sessionId: () => sessionId,
          sessionStartedAt: () => session.createdAt,
        );
      } catch (e, st) {
        if (kDebugMode) debugPrint('[FermentationProvider] createSession: $e\n$st');
        state = state.copyWith(error: () => 'No se pudo iniciar la sesiÃ³n: los datos no se guardarÃ¡n.');
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

    // AlertEngine â€” immediate threshold check, always first
    final alerts = engine.checkFermentationReading(
      ph: ph,
      mucilagoTemp: tempC,
      processType: state.processType,
      lotId: state.lotId,
    );

    // Linear regression projection (requires â‰¥ 2 readings)
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

    // Fire notification for actionable alerts
    _fireAlertNotification(alerts, state.lotId);
    // Schedule next reading reminder (4 h from now)
    NotificationService.instance
        .scheduleFermentationReminder(lotId: state.lotId);

    // Full RuleEngine evaluation with complete context
    try {
      final userId = ref.read(currentUserIdProvider);
      final roleStr = ref.read(currentUserProvider)?.role ?? 'producer';
      final userRole = roleFromString(roleStr);
      final lot = await ref.read(lotByIdProvider(state.lotId).future);
      final userAvgH  = await repo.getAvgCompletedDurationH();
      final lastLotH  = await repo.getLastCompletedDurationH();

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
        userLotsCompleted:    0,
        userAvgFermentationH: userAvgH,
        lastLotFermentationH: lastLotH,
      );

      final recs = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);
      state = state.copyWith(recommendations: recs, isAnalyzing: false);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FermentationProvider] AI recommend: $e\n$st');
      state = state.copyWith(isAnalyzing: false, error: () => 'Error al obtener recomendaciones de IA.');
    }

    // Persist reading to Drift (after AI analysis â€” fire and track errors silently)
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
        // Sync to backend in background â€” never awaited, never blocks UI
        ref.read(syncServiceProvider).syncPendingReadings().ignore();
      } catch (e, st) {
        if (kDebugMode) debugPrint('[FermentationProvider] addReading persist: $e\n$st');
        state = state.copyWith(error: () => 'Lectura no guardada localmente. Revisa el almacenamiento.');
      }
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

  void _fireAlertNotification(List<Alert> alerts, String lotId) {
    if (alerts.isEmpty) return;
    final ns = NotificationService.instance;
    final worst = alerts.reduce(
      (a, b) => a.level.index > b.level.index ? a : b,
    );
    final msg =
        'pH ${worst.triggerValue.toStringAsFixed(2)} â€” umbral ${worst.threshold.toStringAsFixed(2)}. '
        'Proceso: ${state.processType}.';
    if (worst.level == AlertLevel.critical) {
      ns.showFermentationCriticalAlert(lotId: lotId, message: msg);
    } else if (worst.level.index >= AlertLevel.warning.index) {
      ns.showFermentationWarning(lotId: lotId, message: msg);
    }
  }
}
