import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/depulping_session.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'depulping_provider.g.dart';

// ── State ──────────────────────────────────────────────────────────────────

class DepulpingState {
  const DepulpingState({
    required this.lotId,
    this.session,
    this.kgPreFilled,
    this.referenceTime,
    this.referenceSource = 'none',
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
  });

  final String               lotId;
  final DepulpingSession?    session;
  final double?              kgPreFilled;    // from classification.kgSeleccionado
  final DateTime?            referenceTime;  // for live elapsed display in UI
  final String               referenceSource; // 'classification'|'harvest_pass'|'none'
  final List<Recommendation> recommendations;
  final bool                 isLoading;
  final String?              error;

  bool get isComplete    => session != null;
  bool get hasReference  => referenceTime != null;

  double get hoursElapsed => referenceTime != null
      ? DateTime.now().difference(referenceTime!).inMinutes / 60.0
      : 0.0;

  DepulpingState copyWith({
    DepulpingSession?    session,
    double?              kgPreFilled,
    DateTime?            referenceTime,
    String?              referenceSource,
    List<Recommendation>? recommendations,
    bool?                isLoading,
    String?              error,
  }) =>
      DepulpingState(
        lotId:           lotId,
        session:         session          ?? this.session,
        kgPreFilled:     kgPreFilled      ?? this.kgPreFilled,
        referenceTime:   referenceTime    ?? this.referenceTime,
        referenceSource: referenceSource  ?? this.referenceSource,
        recommendations: recommendations  ?? this.recommendations,
        isLoading:       isLoading        ?? this.isLoading,
        error:           error,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

@riverpod
class DepulpingNotifier extends _$DepulpingNotifier {
  @override
  DepulpingState build(String lotId) {
    _init(lotId);
    return DepulpingState(lotId: lotId);
  }

  void _init(String lotId) {
    Future(() async {
      try {
        // 1. Load existing depulping session
        final existing = await ref
            .read(depulpingLocalRepoProvider)
            .getByLotId(lotId);

        // 2. Cascading reference for elapsed time
        final (refTime, refSource) = await _referenceTime(lotId);

        // 3. Pre-fill kg from classification if available
        final classif = await ref
            .read(classificationLocalRepoProvider)
            .getByLotId(lotId);

        state = DepulpingState(
          lotId:           lotId,
          session:         existing,
          kgPreFilled:     classif?.kgSeleccionado,
          referenceTime:   refTime,
          referenceSource: refSource,
        );
      } catch (_) {}
    });
  }

  /// Cascade: classification → last harvest pass → null
  Future<(DateTime?, String)> _referenceTime(String lotId) async {
    // 1. Classification
    final classif = await ref
        .read(classificationLocalRepoProvider)
        .getByLotId(lotId);
    if (classif != null) return (classif.classifiedAt, 'classification');

    // 2. Last harvest pass (MAX pass_date across any session for this lot)
    final db = ref.read(appDatabaseProvider);
    final session = await db.harvestDao.getLatestSession(lotId);
    if (session != null) {
      final passes = await db.harvestDao.getPasses(session.id);
      if (passes.isNotEmpty) {
        final latest = passes
            .map((p) => p.passDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        return (latest, 'harvest_pass');
      }
    }

    // 3. No reference available
    return (null, 'none');
  }

  Future<void> register({
    required double   kgDepulped,
    required DateTime depulpedAt,
    String?           notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final lot     = await ref.read(lotByIdProvider(state.lotId).future);
      final userId  = ref.read(currentUserIdProvider);
      final roleStr = ref.read(currentUserProvider)?.role ?? 'farmer';
      final userRole = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.farmer,
      );

      final hoursElapsed = state.referenceTime != null
          ? depulpedAt.difference(state.referenceTime!).inMinutes / 60.0
          : 0.0;

      final aiContext = AIContext(
        userId:                   userId,
        userRole:                 userRole,
        module:                   'depulping',
        lotId:                    state.lotId,
        varietyId:                lot?.varietyId           ?? 'unknown',
        altitudeMasl:             lot?.altitudeMasl        ?? 1500,
        region:                   lot?.region              ?? '',
        ambientTempC:             lot?.ambientTempC        ?? 20.0,
        ambientHumidityPct:       lot?.ambientHumidityPct  ?? 70.0,
        hoursFromDepulpingReference: hoursElapsed,
        userLotsCompleted:        ref.read(userLotsProvider).asData?.value.length ?? 0,
      );

      final engine = await ref.read(aiEngineProvider.future);
      final recs   = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);

      final alertLevel   = recs.isEmpty ? 'none' : recs.first.alertLevel.name;
      final alertMessage = recs.isEmpty ? null   : recs.first.explanation;

      // Retrieve classificationSessionId for FK
      final classif = await ref
          .read(classificationLocalRepoProvider)
          .getByLotId(state.lotId);

      final now  = DateTime.now();
      final saved = await ref.read(depulpingLocalRepoProvider).save(
        DepulpingSession(
          id:                      '',
          lotId:                   state.lotId,
          ownerId:                 userId,
          classificationSessionId: classif?.id,
          kgDepulped:              kgDepulped,
          depulpedAt:              depulpedAt,
          referenceSource:         state.referenceSource,
          hoursFromReference:      state.referenceTime != null ? hoursElapsed : null,
          aiAlertLevel:            alertLevel,
          aiAlertMessage:          alertMessage,
          notes:                   notes,
          createdAt:               now,
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
