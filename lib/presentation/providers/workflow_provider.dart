import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/lot_stage_log.dart';

part 'workflow_provider.g.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class WorkflowState {
  const WorkflowState({
    this.completedStages = const [],
    this.activeStage,
    this.isLoading = false,
    this.error,
  });

  final List<LotStageLog> completedStages;
  final LotStageLog?      activeStage;
  final bool              isLoading;
  final String?           error;

  bool get hasActiveStage => activeStage != null;

  WorkflowState copyWith({
    List<LotStageLog>? completedStages,
    LotStageLog?       activeStage,
    bool?              isLoading,
    String?            error,
    bool               clearActive = false,
    bool               clearError  = false,
  }) =>
      WorkflowState(
        completedStages: completedStages ?? this.completedStages,
        activeStage:     clearActive ? null : (activeStage ?? this.activeStage),
        isLoading:       isLoading   ?? this.isLoading,
        error:           clearError  ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

@riverpod
class WorkflowNotifier extends _$WorkflowNotifier {
  @override
  Future<WorkflowState> build(String lotId) async {
    final repo   = ref.watch(lotStageLogLocalRepoProvider);
    final stages = await repo.getByLotId(lotId);
    final completed = stages.where((s) => s.isCompleted).toList();
    final active    = stages.where((s) => !s.isCompleted).firstOrNull;
    return WorkflowState(completedStages: completed, activeStage: active);
  }

  Future<void> startStage(
    String stage, {
    String? processType,
    double? expectedDurationH,
  }) async {
    final prev = state.value ?? const WorkflowState();
    state = const AsyncLoading();
    try {
      final repo = ref.read(lotStageLogLocalRepoProvider);
      final log  = await repo.startStage(
        lotId:             lotId,
        stage:             stage,
        processType:       processType,
        expectedDurationH: expectedDurationH,
      );
      state = AsyncData(prev.copyWith(activeStage: log, clearError: true));
    } catch (e) {
      state = AsyncData(prev.copyWith(error: e.toString()));
    }
  }

  Future<void> completeStage(
    String id, {
    double? phStart,
    double? phEnd,
    double? tempC,
    double? brixValue,
    String? notes,
  }) async {
    final prev = state.value ?? const WorkflowState();
    state = const AsyncLoading();
    try {
      final repo = ref.read(lotStageLogLocalRepoProvider);
      await repo.completeStage(
        id,
        phStart: phStart, phEnd: phEnd,
        tempC: tempC, brixValue: brixValue, notes: notes,
      );
      // Reload to get fresh state
      final stages    = await repo.getByLotId(lotId);
      final completed = stages.where((s) => s.isCompleted).toList();
      final active    = stages.where((s) => !s.isCompleted).firstOrNull;
      state = AsyncData(WorkflowState(
        completedStages: completed, activeStage: active));
    } catch (e) {
      state = AsyncData(prev.copyWith(error: e.toString()));
    }
  }
}
