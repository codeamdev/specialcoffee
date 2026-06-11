import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/milling_session.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'milling_provider.g.dart';

// â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class MillingState {
  const MillingState({
    required this.lotId,
    this.session,
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
  });

  final String               lotId;
  final MillingSession?      session;
  final List<Recommendation> recommendations;
  final bool                 isLoading;
  final String?              error;

  bool get isComplete => session != null;

  MillingState copyWith({
    MillingSession?       session,
    List<Recommendation>? recommendations,
    bool?                 isLoading,
    String?               error,
  }) =>
      MillingState(
        lotId:           lotId,
        session:         session          ?? this.session,
        recommendations: recommendations  ?? this.recommendations,
        isLoading:       isLoading        ?? this.isLoading,
        error:           error,
      );
}

// â”€â”€ Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@riverpod
class MillingNotifier extends _$MillingNotifier {
  @override
  MillingState build(String lotId) {
    _init(lotId);
    return MillingState(lotId: lotId);
  }

  void _init(String lotId) {
    Future(() async {
      try {
        final existing = await ref
            .read(millingLocalRepoProvider)
            .getByLotId(lotId);
        if (existing != null) state = state.copyWith(session: existing);
      } catch (_) {}
    });
  }

  Future<void> register({
    required double inputKgParchment,
    required double outputKgGreen,
    String?         notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final yieldPct = (outputKgGreen / inputKgParchment) * 100.0;

      final lot      = await ref.read(lotByIdProvider(state.lotId).future);
      final userId   = ref.read(currentUserIdProvider);
      final roleStr  = ref.read(currentUserProvider)?.role ?? 'producer';
      final userRole = roleFromString(roleStr);

      final aiContext = AIContext(
        userId:             userId,
        userRole:           userRole,
        module:             'milling',
        lotId:              state.lotId,
        varietyId:          lot?.varietyId          ?? 'unknown',
        altitudeMasl:       lot?.altitudeMasl       ?? 1500,
        region:             lot?.region             ?? '',
        ambientTempC:       lot?.ambientTempC       ?? 20.0,
        ambientHumidityPct: lot?.ambientHumidityPct ?? 70.0,
        millingYieldPct:    yieldPct,
        userLotsCompleted:  ref.read(userLotsProvider).asData?.value.length ?? 0,
      );

      final engine = await ref.read(aiEngineProvider.future);
      final recs   = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);

      final alertLevel   = recs.isEmpty ? 'none' : recs.first.alertLevel.name;
      final alertMessage = recs.isEmpty ? null   : recs.first.explanation;

      final now   = DateTime.now();
      final saved = await ref.read(millingLocalRepoProvider).save(
        MillingSession(
          id:               '',
          lotId:            state.lotId,
          ownerId:          userId,
          inputKgParchment: inputKgParchment,
          outputKgGreen:    outputKgGreen,
          yieldPct:         yieldPct,
          aiAlertLevel:     alertLevel,
          aiAlertMessage:   alertMessage,
          notes:            notes,
          createdAt:        now,
        ),
      );

      state = state.copyWith(
        session:         saved,
        recommendations: recs,
        isLoading:       false,
      );
      ref.read(syncServiceProvider).syncPendingReadings().ignore();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
