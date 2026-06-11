import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/classification_session.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'classification_provider.g.dart';

// â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ClassificationState {
  const ClassificationState({
    required this.lotId,
    this.session,
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
  });

  final String                 lotId;
  final ClassificationSession? session;
  final List<Recommendation>   recommendations;
  final bool                   isLoading;
  final String?                error;

  bool get isComplete => session != null;

  ClassificationState copyWith({
    ClassificationSession? session,
    List<Recommendation>?  recommendations,
    bool?                  isLoading,
    String?                error,
  }) =>
      ClassificationState(
        lotId:           lotId,
        session:         session         ?? this.session,
        recommendations: recommendations ?? this.recommendations,
        isLoading:       isLoading       ?? this.isLoading,
        error:           error,
      );
}

// â”€â”€ Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@riverpod
class ClassificationNotifier extends _$ClassificationNotifier {
  @override
  ClassificationState build(String lotId) {
    _loadExisting(lotId);
    return ClassificationState(lotId: lotId);
  }

  void _loadExisting(String lotId) {
    Future(() async {
      try {
        final repo    = ref.read(classificationLocalRepoProvider);
        final session = await repo.getByLotId(lotId);
        if (session != null) {
          state = state.copyWith(session: session);
        }
      } catch (_) {}
    });
  }

  Future<void> classify({
    required double   kgEntrada,
    required double   kgFlotantes,
    required double   kgDescarteManual,
    double?           brixCereza,
    String?           notes,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final lot = await ref.read(lotByIdProvider(state.lotId).future);
      final userId  = ref.read(currentUserIdProvider);
      final roleStr = ref.read(currentUserProvider)?.role ?? 'producer';
      final userRole = roleFromString(roleStr);

      final now = DateTime.now();
      final draft = ClassificationSession(
        id:               '',
        lotId:            state.lotId,
        ownerId:          userId,
        kgEntrada:        kgEntrada,
        brixCereza:       brixCereza,
        kgFlotantes:      kgFlotantes,
        kgDescarteManual: kgDescarteManual,
        notes:            notes,
        classifiedAt:     now,
        createdAt:        now,
      );

      final flotationFloatPct   = kgEntrada > 0 ? (kgFlotantes / kgEntrada * 100) : 0.0;
      final pctAprovechamiento  = draft.pctAprovechamiento;

      final aiContext = AIContext(
        userId:             userId,
        userRole:           userRole,
        module:             'classification',
        lotId:              state.lotId,
        varietyId:          lot?.varietyId           ?? 'unknown',
        altitudeMasl:       lot?.altitudeMasl        ?? 1500,
        region:             lot?.region              ?? '',
        ambientTempC:       lot?.ambientTempC        ?? 20.0,
        ambientHumidityPct: lot?.ambientHumidityPct  ?? 70.0,
        rainProbabilityPct: lot?.rainProbabilityPct  ?? 0.0,
        brixLevel:          brixCereza               ?? 0.0,
        flotationFloatPct:  flotationFloatPct,
        pctAprovechamiento: pctAprovechamiento,
        userLotsCompleted:  ref.read(userLotsProvider).asData?.value.length ?? 0,
      );

      final engine = await ref.read(aiEngineProvider.future);
      final recs   = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);

      final alertLevel   = recs.isEmpty ? 'none' : recs.first.alertLevel.name;
      final alertMessage = recs.isEmpty ? null   : recs.first.explanation;

      final saved = await ref.read(classificationLocalRepoProvider).save(
        ClassificationSession(
          id:               '',
          lotId:            state.lotId,
          ownerId:          userId,
          kgEntrada:        kgEntrada,
          brixCereza:       brixCereza,
          kgFlotantes:      kgFlotantes,
          kgDescarteManual: kgDescarteManual,
          aiAlertLevel:     alertLevel,
          aiAlertMessage:   alertMessage,
          notes:            notes,
          classifiedAt:     now,
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
      state = state.copyWith(
        isLoading: false,
        error:     e.toString(),
      );
    }
  }
}
