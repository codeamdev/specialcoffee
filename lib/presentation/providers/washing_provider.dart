import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/washing_session.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'washing_provider.g.dart';

// ── State ──────────────────────────────────────────────────────────────────

class WashingState {
  const WashingState({
    required this.lotId,
    this.session,
    this.fermentationSessionId,
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
  });

  final String               lotId;
  final WashingSession?      session;
  final String?              fermentationSessionId;
  final List<Recommendation> recommendations;
  final bool                 isLoading;
  final String?              error;

  bool get isComplete => session != null;

  WashingState copyWith({
    WashingSession?       session,
    String?               fermentationSessionId,
    List<Recommendation>? recommendations,
    bool?                 isLoading,
    String?               error,
  }) =>
      WashingState(
        lotId:                 lotId,
        session:               session               ?? this.session,
        fermentationSessionId: fermentationSessionId ?? this.fermentationSessionId,
        recommendations:       recommendations       ?? this.recommendations,
        isLoading:             isLoading             ?? this.isLoading,
        error:                 error,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

@riverpod
class WashingNotifier extends _$WashingNotifier {
  @override
  WashingState build(String lotId) {
    _init(lotId);
    return WashingState(lotId: lotId);
  }

  void _init(String lotId) {
    Future(() async {
      try {
        final existing = await ref
            .read(washingLocalRepoProvider)
            .getByLotId(lotId);

        final fermSession = await ref
            .read(appDatabaseProvider)
            .fermentationDao
            .getLatestSession(lotId);

        state = state.copyWith(
          session:               existing,
          fermentationSessionId: fermSession?.id,
        );
      } catch (_) {}
    });
  }

  Future<void> register({
    required double   waterTempC,
    required int      waterChanges,
    required double   effluentPhFinal,
    required double   durationH,
    required DateTime washedAt,
    String?           notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final lot      = await ref.read(lotByIdProvider(state.lotId).future);
      final userId   = ref.read(currentUserIdProvider);
      final roleStr  = ref.read(currentUserProvider)?.role ?? 'producer';
      final userRole = roleFromString(roleStr);

      final aiContext = AIContext(
        userId:              userId,
        userRole:            userRole,
        module:              'washing',
        lotId:               state.lotId,
        varietyId:           lot?.varietyId          ?? 'unknown',
        altitudeMasl:        lot?.altitudeMasl       ?? 1500,
        region:              lot?.region             ?? '',
        ambientTempC:        lot?.ambientTempC       ?? 20.0,
        ambientHumidityPct:  lot?.ambientHumidityPct ?? 70.0,
        washingWaterTempC:   waterTempC,
        washingWaterChanges: waterChanges,
        washingEffluentPh:   effluentPhFinal,
        userLotsCompleted:   ref.read(userLotsProvider).asData?.value.length ?? 0,
      );

      final engine = await ref.read(aiEngineProvider.future);
      final recs   = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);

      final alertLevel   = recs.isEmpty ? 'none' : recs.first.alertLevel.name;
      final alertMessage = recs.isEmpty ? null   : recs.first.explanation;

      final now   = DateTime.now();
      final saved = await ref.read(washingLocalRepoProvider).save(
        WashingSession(
          id:                    '',
          lotId:                 state.lotId,
          ownerId:               userId,
          fermentationSessionId: state.fermentationSessionId,
          waterTempC:            waterTempC,
          waterChanges:          waterChanges,
          effluentPhFinal:       effluentPhFinal,
          durationH:             durationH,
          washedAt:              washedAt,
          aiAlertLevel:          alertLevel,
          aiAlertMessage:        alertMessage,
          notes:                 notes,
          createdAt:             now,
        ),
      );

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
