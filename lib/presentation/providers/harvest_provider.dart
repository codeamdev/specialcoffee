import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/core/notifications/notification_service.dart';
import 'package:special_coffee/data/repositories/harvest_repository_local.dart';
import 'package:special_coffee/domain/entities/harvest_session.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'harvest_provider.g.dart';

// ── State ──────────────────────────────────────────────────────────────────

class HarvestState {
  const HarvestState({
    required this.lotId,
    this.sessionId,
    this.sessionStartedAt,
    this.varietyId = 'unknown',
    this.altitudeMasl = 1500.0,
    this.passes = const [],
    this.recommendations = const [],
    this.isAnalyzing = false,
  });

  final String lotId;
  final String? sessionId;
  final DateTime? sessionStartedAt;
  final String varietyId;
  final double altitudeMasl;
  final List<HarvestPass> passes;
  final List<Recommendation> recommendations;
  final bool isAnalyzing;

  bool get hasPasses => passes.isNotEmpty;
  HarvestPass? get lastPass => passes.isEmpty ? null : passes.last;
  int get nextPassNumber => passes.length + 1;

  int get nextIntervalDays =>
      HarvestLocalRepository.nextPassIntervalDays(varietyId, altitudeMasl);

  HarvestState copyWith({
    String? Function()? sessionId,
    DateTime? Function()? sessionStartedAt,
    String? varietyId,
    double? altitudeMasl,
    List<HarvestPass>? passes,
    List<Recommendation>? recommendations,
    bool? isAnalyzing,
  }) =>
      HarvestState(
        lotId: lotId,
        sessionId: sessionId != null ? sessionId() : this.sessionId,
        sessionStartedAt: sessionStartedAt != null
            ? sessionStartedAt()
            : this.sessionStartedAt,
        varietyId: varietyId ?? this.varietyId,
        altitudeMasl: altitudeMasl ?? this.altitudeMasl,
        passes: passes ?? this.passes,
        recommendations: recommendations ?? this.recommendations,
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

@riverpod
class HarvestNotifier extends _$HarvestNotifier {
  @override
  HarvestState build(String lotId) {
    _loadPersistedSession(lotId);
    return HarvestState(lotId: lotId);
  }

  void _loadPersistedSession(String lotId) {
    final repo = ref.read(harvestLocalRepoProvider);
    Future(() async {
      try {
        final session = await repo.getActiveSession(lotId);
        if (session == null) return;
        final passes = await repo.getPasses(session.id);
        state = HarvestState(
          lotId: lotId,
          sessionId: session.id,
          sessionStartedAt: session.startedAt,
          varietyId: session.varietyId,
          altitudeMasl: session.altitudeMasl,
          passes: passes,
        );
      } catch (_) {
        // Persistence unavailable — start fresh in-memory session
      }
    });
  }

  Future<void> addPass({
    required double kgCollected,
    required int pickerCount,
    required DateTime passDate,
    double? ripenessRipePct,
    double? ripenessGreenPct,
    double? ripenessOverripePct,
    double? ripenesDryPct,
    double? brixDegrees,
    String? notes,
  }) async {
    // 1. Ensure session exists
    final repo = ref.read(harvestLocalRepoProvider);
    String? sessionId = state.sessionId;
    DateTime? sessionStartedAt = state.sessionStartedAt;
    String varietyId = state.varietyId;
    double altitudeMasl = state.altitudeMasl;

    if (sessionId == null) {
      try {
        final lot = await ref.read(lotByIdProvider(state.lotId).future);
        varietyId = lot?.varietyId ?? 'unknown';
        altitudeMasl = lot?.altitudeMasl.toDouble() ?? 1500.0;
        final session = await repo.createSession(
          lotId: state.lotId,
          varietyId: varietyId,
          altitudeMasl: altitudeMasl,
        );
        sessionId = session.id;
        sessionStartedAt = session.startedAt;
        state = state.copyWith(
          sessionId: () => sessionId,
          sessionStartedAt: () => sessionStartedAt,
          varietyId: varietyId,
          altitudeMasl: altitudeMasl,
        );
      } catch (_) {
        // Proceed without persistence
      }
    }

    final passNumber = state.nextPassNumber;
    final now = DateTime.now();
    final lot = await ref.read(lotByIdProvider(state.lotId).future);
    final rainProbabilityPct = lot?.rainProbabilityPct ?? 0.0;

    final newPass = HarvestPass(
      id: 'temp_${now.millisecondsSinceEpoch}',
      sessionId: sessionId ?? '',
      lotId: state.lotId,
      ownerId: ref.read(currentUserIdProvider),
      passNumber: passNumber,
      passDate: passDate,
      kgCollected: kgCollected,
      pickerCount: pickerCount,
      ripenessRipePct: ripenessRipePct,
      ripenessGreenPct: ripenessGreenPct,
      ripenessOverripePct: ripenessOverripePct,
      ripenesDryPct: ripenesDryPct,
      brixDegrees: brixDegrees,
      rainProbabilityPct: rainProbabilityPct,
      recordedAt: now,
    );

    final updatedPasses = [...state.passes, newPass];
    state = state.copyWith(passes: updatedPasses, isAnalyzing: true);

    // 2. Run AI analysis
    try {
      final userId = ref.read(currentUserIdProvider);
      final roleStr = ref.read(currentUserProvider)?.role ?? 'farmer';
      final userRole = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.farmer,
      );

      // cherry_color_pct = ripe % when ripeness data available, else 100 (neutral)
      final cherryColorPct = ripenessRipePct != null
          ? ripenessRipePct.round()
          : 100;

      final aiContext = AIContext(
        userId: userId,
        userRole: userRole,
        module: 'harvest',
        lotId: state.lotId,
        varietyId: state.varietyId,
        altitudeMasl: lot?.altitudeMasl ?? 1500,
        region: lot?.region ?? '',
        ambientTempC: lot?.ambientTempC ?? 20.0,
        ambientHumidityPct: lot?.ambientHumidityPct ?? 70.0,
        rainProbabilityPct: rainProbabilityPct,
        brixLevel: brixDegrees ?? 0.0,
        cherryColorPct: cherryColorPct,
        userLotsCompleted: 0,
      );

      final engine = await ref.read(aiEngineProvider.future);
      final recs = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);
      state = state.copyWith(recommendations: recs, isAnalyzing: false);
    } catch (_) {
      state = state.copyWith(isAnalyzing: false);
    }

    // 3. Persist to Drift
    if (sessionId != null) {
      try {
        final saved = await repo.addPass(
          sessionId: sessionId,
          lotId: state.lotId,
          passNumber: passNumber,
          passDate: passDate,
          kgCollected: kgCollected,
          pickerCount: pickerCount,
          ripenessRipePct: ripenessRipePct,
          ripenessGreenPct: ripenessGreenPct,
          ripenessOverripePct: ripenessOverripePct,
          ripenesDryPct: ripenesDryPct,
          brixDegrees: brixDegrees,
          rainProbabilityPct: rainProbabilityPct,
          aiAlertLevel: state.recommendations.isEmpty
              ? 'none'
              : state.recommendations.first.alertLevel.name,
          aiAlertMessage: state.recommendations.isEmpty
              ? null
              : state.recommendations.first.explanation,
          notes: notes,
        );
        // Replace temp pass with persisted one
        final persistedPasses = [
          ...state.passes.where((p) => p.id != newPass.id),
          saved,
        ]..sort((a, b) => a.passNumber.compareTo(b.passNumber));
        state = state.copyWith(passes: persistedPasses);
      } catch (_) {}
    }

    // 4. Schedule next-pass reminder
    NotificationService.instance.scheduleHarvestPassReminder(
      lotId: state.lotId,
      intervalDays: state.nextIntervalDays,
    );
  }

  Future<void> completeSession() async {
    final sessionId = state.sessionId;
    if (sessionId != null) {
      try {
        await ref.read(harvestLocalRepoProvider).closeSession(sessionId);
      } catch (_) {}
    }
    state = HarvestState(lotId: state.lotId);
  }
}
