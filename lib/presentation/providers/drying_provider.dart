import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/core/notifications/notification_service.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'drying_provider.g.dart';

// ── Domain ─────────────────────────────────────────────────────────────────

class DryingReading {
  const DryingReading({
    required this.dayNumber,
    required this.moisturePct,
    required this.ambientTempC,
    required this.ambientHumidityPct,
    this.uvIndex = 0.0,
    required this.recordedAt,
  });

  final int dayNumber;
  final double moisturePct;
  final double ambientTempC;
  final double ambientHumidityPct;
  final double uvIndex;
  final DateTime recordedAt;
}

// ── State ──────────────────────────────────────────────────────────────────

class DryingState {
  const DryingState({
    required this.lotId,
    this.sessionId,
    this.sessionStartedAt,
    this.dryingMethod = 'camas_africanas',
    this.readings = const [],
    this.recommendations = const [],
    this.isAnalyzing = false,
    this.error,
  });

  final String lotId;
  final String? sessionId;
  final DateTime? sessionStartedAt;
  final String dryingMethod;
  final List<DryingReading> readings;
  final List<Recommendation> recommendations;
  final bool isAnalyzing;
  final String? error;

  bool get hasReadings => readings.isNotEmpty;
  DryingReading? get lastReading => readings.isEmpty ? null : readings.last;

  bool get isAtTarget {
    if (!hasReadings) return false;
    final m = lastReading!.moisturePct;
    return m >= 10.5 && m <= 12.0;
  }

  bool get isOverDried => hasReadings && lastReading!.moisturePct < 10.0;

  int get nextDayNumber {
    if (sessionStartedAt != null) {
      return (DateTime.now().difference(sessionStartedAt!).inHours / 24)
              .floor() +
          1;
    }
    return readings.length + 1;
  }

  DryingState copyWith({
    String? Function()? sessionId,
    DateTime? Function()? sessionStartedAt,
    String? dryingMethod,
    List<DryingReading>? readings,
    List<Recommendation>? recommendations,
    bool? isAnalyzing,
    String? Function()? error,
  }) =>
      DryingState(
        lotId: lotId,
        sessionId: sessionId != null ? sessionId() : this.sessionId,
        sessionStartedAt: sessionStartedAt != null
            ? sessionStartedAt()
            : this.sessionStartedAt,
        dryingMethod: dryingMethod ?? this.dryingMethod,
        readings: readings ?? this.readings,
        recommendations: recommendations ?? this.recommendations,
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
        error: error != null ? error() : this.error,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

@riverpod
class DryingNotifier extends _$DryingNotifier {
  @override
  DryingState build(String lotId) {
    _loadPersistedSession(lotId);
    return DryingState(lotId: lotId);
  }

  void _loadPersistedSession(String lotId) {
    final repo = ref.read(dryingLocalRepoProvider);
    Future(() async {
      try {
        final session = await repo.getActiveSession(lotId);
        if (session == null) return;
        final records = await repo.getReadings(session.id);
        final readings = records
            .map((r) => DryingReading(
                  dayNumber: r.dayNumber,
                  moisturePct: r.moisturePct,
                  ambientTempC: r.ambientTempC,
                  ambientHumidityPct: r.ambientHumidityPct,
                  uvIndex: r.uvIndex,
                  recordedAt: r.recordedAt,
                ))
            .toList();
        state = DryingState(
          lotId: lotId,
          sessionId: session.id,
          sessionStartedAt: session.startedAt,
          dryingMethod: session.dryingMethod,
          readings: readings,
        );
      } catch (e, st) {
        if (kDebugMode) debugPrint('[DryingProvider] _loadPersistedSession: $e\n$st');
        // Persistence unavailable — start fresh in-memory session
      }
    });
  }

  Future<void> addReading({
    required double moisturePct,
    required double ambientTempC,
    required double ambientHumidityPct,
    double uvIndex = 0.0,
  }) async {
    // 1. Ensure session exists
    final repo = ref.read(dryingLocalRepoProvider);
    String? sessionId = state.sessionId;
    DateTime? sessionStartedAt = state.sessionStartedAt;
    if (sessionId == null) {
      try {
        final session = await repo.createSession(
          lotId: state.lotId,
          dryingMethod: state.dryingMethod,
        );
        sessionId = session.id;
        sessionStartedAt = session.startedAt;
        state = state.copyWith(
          sessionId: () => sessionId,
          sessionStartedAt: () => sessionStartedAt,
        );
      } catch (e, st) {
        if (kDebugMode) debugPrint('[DryingProvider] createSession: $e\n$st');
        state = state.copyWith(error: () => 'No se pudo iniciar la sesión: los datos no se guardarán.');
      }
    }

    final dayNumber = state.nextDayNumber;
    final now = DateTime.now();
    final newReading = DryingReading(
      dayNumber: dayNumber,
      moisturePct: moisturePct,
      ambientTempC: ambientTempC,
      ambientHumidityPct: ambientHumidityPct,
      uvIndex: uvIndex,
      recordedAt: now,
    );
    final updatedReadings = [...state.readings, newReading];

    state = state.copyWith(readings: updatedReadings, isAnalyzing: true);

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
        module: 'drying',
        lotId: state.lotId,
        varietyId: lot?.varietyId ?? 'unknown',
        altitudeMasl: lot?.altitudeMasl ?? 1500,
        region: lot?.region ?? '',
        ambientTempC: ambientTempC,
        ambientHumidityPct: ambientHumidityPct,
        rainProbabilityPct: lot?.rainProbabilityPct ?? 0.0,
        uvIndex: uvIndex,
        processType: state.dryingMethod,
        currentHumidityPct: moisturePct,
        dryingDayNumber: dayNumber,
        userLotsCompleted: 0,
      );

      final engine = await ref.read(aiEngineProvider.future);
      final recs = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);
      state = state.copyWith(recommendations: recs, isAnalyzing: false);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[DryingProvider] AI recommend: $e\n$st');
      state = state.copyWith(isAnalyzing: false, error: () => 'Error al obtener recomendaciones de IA.');
    }

    // Persist to Drift
    if (sessionId != null) {
      try {
        await repo.addReading(
          sessionId: sessionId,
          lotId: state.lotId,
          dayNumber: dayNumber,
          moisturePct: moisturePct,
          ambientTempC: ambientTempC,
          ambientHumidityPct: ambientHumidityPct,
          uvIndex: uvIndex,
        );
      } catch (e, st) {
        if (kDebugMode) debugPrint('[DryingProvider] addReading persist: $e\n$st');
        state = state.copyWith(error: () => 'Lectura no guardada localmente. Revisa el almacenamiento.');
      }
    }

    // Fire moisture notifications and schedule next daily reminder
    _fireDryingNotification(moisturePct, state.lotId);
    NotificationService.instance.scheduleDryingReminder(lotId: state.lotId);
  }

  void _fireDryingNotification(double moisturePct, String lotId) {
    final ns = NotificationService.instance;
    if (moisturePct < 10.0) {
      ns.showDryingOverDried(lotId: lotId, moisturePct: moisturePct);
    } else if (moisturePct >= 10.5 && moisturePct <= 12.0) {
      ns.showDryingTargetReached(lotId: lotId, moisturePct: moisturePct);
    }
  }

  void changeDryingMethod(String method) {
    if (state.hasReadings) return;
    state = DryingState(lotId: state.lotId, dryingMethod: method);
  }

  void reset() {
    final sessionId = state.sessionId;
    if (sessionId != null) {
      final repo = ref.read(dryingLocalRepoProvider);
      final finalMoisture =
          state.readings.isEmpty ? 0.0 : state.readings.last.moisturePct;
      Future(() => repo.closeSession(
            sessionId: sessionId,
            finalMoisturePct: finalMoisture,
          ));
    }
    state = DryingState(
        lotId: state.lotId, dryingMethod: state.dryingMethod);
  }
}
