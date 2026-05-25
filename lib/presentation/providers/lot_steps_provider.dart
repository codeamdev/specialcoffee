import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'lot_steps_provider.g.dart';

// ── Step status ─────────────────────────────────────────────────────────────

enum StepStatus {
  done,    // record exists and process is closed
  active,  // record exists but process still open (endedAt IS NULL)
  next,    // first pending step in sequence — "recommended next"
  pending, // not yet started
}

// ── Step data ────────────────────────────────────────────────────────────────

class LotStep {
  const LotStep({
    required this.id,
    required this.label,
    required this.route,
    required this.status,
  });

  final String     id;
  final String     label;
  final String     route;   // already has :id replaced with the real lotId
  final StepStatus status;
}

class LotStepsState {
  const LotStepsState({required this.steps});
  final List<LotStep> steps;
}

// ── Provider ─────────────────────────────────────────────────────────────────

@riverpod
Future<LotStepsState> lotSteps(Ref ref, String lotId) async {
  final db = ref.read(appDatabaseProvider);

  // All 5 DAO reads in parallel — consistent pattern: all via DAO.
  // Fermentation/drying use getLatestSession (any session, active or closed).
  // active = latestSession.endedAt == null.
  // Limitation (acknowledged): endedAt can lag if the session was never
  // explicitly closed in the UI. Worst case: active renders as done. Cosmetic.
  final (
    harvestSession,
    classifRecord,
    depulpRecord,
    fermSession,
    drySession,
    cuppingRecord,
    lot,
  ) = await (
    db.harvestDao.getLatestSession(lotId),
    ref.read(classificationLocalRepoProvider).getByLotId(lotId),
    ref.read(depulpingLocalRepoProvider).getByLotId(lotId),
    db.fermentationDao.getLatestSession(lotId),
    db.dryingDao.getLatestSession(lotId),
    ref.read(cuppingLocalRepoProvider).getByLotId(lotId),
    ref.read(lotByIdProvider(lotId).future),
  ).wait;

  final processType = lot?.processType ?? 'lavado';

  // Compute per-step done/active booleans
  final harvestDone  = harvestSession != null;
  final classifDone  = classifRecord  != null;
  final depulpDone   = depulpRecord   != null;
  final fermDone     = fermSession != null && fermSession.endedAt != null;
  final fermActive   = fermSession != null && fermSession.endedAt == null;
  final dryDone      = drySession != null && drySession.endedAt != null;
  final dryActive    = drySession != null && drySession.endedAt == null;
  final cuppingDone  = cuppingRecord != null;

  // Step definitions per sequence
  // Natural:      Cosecha → Clasificación → Secado → Catación       (4 steps)
  // Non-natural:  Cosecha → Clasificación → Despulpado → Fermentación → Secado → Catación (6)
  final rawSteps = processType == 'natural'
      ? [
          (id: 'harvest',        label: 'Cosecha',        route: AppRoutes.harvest,        done: harvestDone, active: false),
          (id: 'classification', label: 'Clasificación',  route: AppRoutes.classification, done: classifDone, active: false),
          (id: 'drying',         label: 'Secado natural', route: AppRoutes.drying,         done: dryDone,     active: dryActive),
          (id: 'cupping',        label: 'Catación',       route: AppRoutes.cupping,        done: cuppingDone, active: false),
        ]
      : [
          (id: 'harvest',        label: 'Cosecha',        route: AppRoutes.harvest,        done: harvestDone, active: false),
          (id: 'classification', label: 'Clasificación',  route: AppRoutes.classification, done: classifDone, active: false),
          (id: 'depulping',      label: 'Despulpado',     route: AppRoutes.depulping,      done: depulpDone,  active: false),
          (id: 'fermentation',   label: 'Fermentación',   route: AppRoutes.fermentation,   done: fermDone,    active: fermActive),
          (id: 'drying',         label: 'Secado',         route: AppRoutes.drying,         done: dryDone,     active: dryActive),
          (id: 'cupping',        label: 'Catación',       route: AppRoutes.cupping,        done: cuppingDone, active: false),
        ];

  // Assign StepStatus; first pending step in sequence gets 'next'
  bool nextAssigned = false;
  final steps = rawSteps.map((s) {
    final StepStatus status;
    if (s.done) {
      status = StepStatus.done;
    } else if (s.active) {
      status = StepStatus.active;
    } else if (!nextAssigned) {
      status = StepStatus.next;
      nextAssigned = true;
    } else {
      status = StepStatus.pending;
    }
    return LotStep(
      id:     s.id,
      label:  s.label,
      route:  s.route.replaceFirst(':id', lotId),
      status: status,
    );
  }).toList();

  return LotStepsState(steps: steps);
}
