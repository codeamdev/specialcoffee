import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/core/process_completion_analyzer.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/cupping_session.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/providers/lot_summary_provider.dart';

part 'cupping_provider.g.dart';

// ── User statistics ───────────────────────────────────────────────────────────

class UserStats {
  const UserStats({
    required this.lotsCupped,
    required this.avgScaScore,
    required this.specialtyRatePct,
    required this.bestScore,
  });

  final int    lotsCupped;
  final double avgScaScore;
  final double specialtyRatePct;
  final double bestScore;

  // Below 3 cuppings: stats are noise, not signal — engine uses defaults
  bool get isReliable => lotsCupped >= 3;
}

@riverpod
Future<UserStats> userStats(Ref ref, String userId) async {
  final sessions = await ref.read(cuppingLocalRepoProvider).getAllByOwner(userId);
  if (sessions.isEmpty) {
    return const UserStats(
        lotsCupped: 0, avgScaScore: 0, specialtyRatePct: 0, bestScore: 0);
  }
  final scores = sessions.map((s) => s.totalScore).toList();
  final avg    = scores.reduce((a, b) => a + b) / scores.length;
  final specialtyCount = scores.where((s) => s >= 80.0).length;
  final best   = scores.reduce((a, b) => a > b ? a : b);
  return UserStats(
    lotsCupped:       sessions.length,
    avgScaScore:      avg,
    specialtyRatePct: specialtyCount / sessions.length * 100,
    bestScore:        best,
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

class CuppingState {
  const CuppingState({
    required this.lotId,
    this.session,
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
  });

  final String           lotId;
  final CuppingSession?  session;
  final List<Recommendation> recommendations;
  final bool             isLoading;
  final String?          error;

  bool get isComplete => session != null;

  CuppingState copyWith({
    CuppingSession?       session,
    List<Recommendation>? recommendations,
    bool?                 isLoading,
    String?               error,
  }) =>
      CuppingState(
        lotId:           lotId,
        session:         session          ?? this.session,
        recommendations: recommendations  ?? this.recommendations,
        isLoading:       isLoading        ?? this.isLoading,
        error:           error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

@riverpod
class CuppingNotifier extends _$CuppingNotifier {
  @override
  CuppingState build(String lotId) {
    _loadExisting(lotId);
    return CuppingState(lotId: lotId);
  }

  void _loadExisting(String lotId) {
    Future(() async {
      try {
        final session = await ref.read(cuppingLocalRepoProvider).getByLotId(lotId);
        if (session != null) state = state.copyWith(session: session);
      } catch (_) {}
    });
  }

  Future<void> register({
    required double   fragranceAroma,
    required double   flavor,
    required double   aftertaste,
    required double   acidity,
    required String   acidityIntensity,
    required double   body,
    required String   bodyLevel,
    required double   balance,
    required int      uniformityCups,
    required int      cleanCupCups,
    required int      sweetnessCups,
    required double   overall,
    required int      defectsCat1Count,
    required int      defectsCat2Count,
    required DateTime cuppedAt,
    String?           notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final totalScore = CuppingSession.computeScore(
        fragranceAroma:   fragranceAroma,
        flavor:           flavor,
        aftertaste:       aftertaste,
        acidity:          acidity,
        body:             body,
        balance:          balance,
        uniformityCups:   uniformityCups,
        cleanCupCups:     cleanCupCups,
        sweetnessCups:    sweetnessCups,
        overall:          overall,
        defectsCat1Count: defectsCat1Count,
        defectsCat2Count: defectsCat2Count,
      );

      final lot      = await ref.read(lotByIdProvider(state.lotId).future);
      final userId   = ref.read(currentUserIdProvider);
      final roleStr  = ref.read(currentUserProvider)?.role ?? 'producer';
      final userRole = roleFromString(roleStr);

      // Historical stats — passed as 0 when unreliable (n < 3) so engine
      // personalisation rules don't fire on noisy data.
      final stats        = await ref.read(userStatsProvider(userId).future);
      final reliableAvg  = stats.isReliable ? stats.avgScaScore      : 0.0;
      final reliableRate = stats.isReliable ? stats.specialtyRatePct : 0.0;

      final aiContext = AIContext(
        userId:               userId,
        userRole:             userRole,
        module:               'cupping',
        lotId:                state.lotId,
        varietyId:            lot?.varietyId          ?? 'unknown',
        altitudeMasl:         lot?.altitudeMasl       ?? 1500,
        region:               lot?.region             ?? '',
        ambientTempC:         lot?.ambientTempC       ?? 20.0,
        ambientHumidityPct:   lot?.ambientHumidityPct ?? 70.0,
        processType:          lot?.processType,
        scaTotalScore:        totalScore,
        userAvgSca:           reliableAvg,
        userSpecialtyRatePct: reliableRate,
        userLotsCompleted:    ref.read(userLotsProvider).asData?.value.length ?? 0,
      );

      final engine = await ref.read(aiEngineProvider.future);
      final recs   = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);

      final alertLevel   = recs.isEmpty ? 'none' : recs.first.alertLevel.name;
      final alertMessage = recs.isEmpty ? null   : recs.first.explanation;

      final now = DateTime.now();
      final saved = await ref.read(cuppingLocalRepoProvider).save(
        CuppingSession(
          id:               '',
          lotId:            state.lotId,
          ownerId:          userId,
          cuppedAt:         cuppedAt,
          fragranceAroma:   fragranceAroma,
          flavor:           flavor,
          aftertaste:       aftertaste,
          acidity:          acidity,
          acidityIntensity: acidityIntensity,
          body:             body,
          bodyLevel:        bodyLevel,
          balance:          balance,
          uniformityCups:   uniformityCups,
          cleanCupCups:     cleanCupCups,
          sweetnessCups:    sweetnessCups,
          overall:          overall,
          defectsCat1Count: defectsCat1Count,
          defectsCat2Count: defectsCat2Count,
          aiAlertLevel:     alertLevel,
          aiAlertMessage:   alertMessage,
          totalScore:       totalScore,
          notes:            notes,
          createdAt:        now,
        ),
      );

      // Detailed process analysis from stage logs (E4)
      if (totalScore > 0) {
        final stages = await ref.read(lotStageLogLocalRepoProvider).getByLotId(state.lotId);
        final db     = ref.read(appDatabaseProvider);
        await ProcessCompletionAnalyzer(db.batchInsightsDao).analyze(
          lotId:    state.lotId,
          ownerId:  userId,
          stages:   stages,
          scaScore: totalScore,
        );
      }

      // Generate lot insight and persist to batch_insights
      final fermSession = await ref
          .read(appDatabaseProvider)
          .fermentationDao
          .getLatestSession(state.lotId);
      ref.read(lotSummaryProvider.notifier).generateAndSave(
            lotId:        state.lotId,
            scaScore:     totalScore,
            fermentationH: fermSession?.actualDurationH,
            phFinal:       fermSession?.phFinal,
          );

      // Trigger learning cycle: stats recompute on next read
      ref.invalidate(userStatsProvider(userId));
      ref.invalidate(userLotsProvider);

      state = state.copyWith(
        session:         saved,
        recommendations: recs,
        isLoading:       false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
