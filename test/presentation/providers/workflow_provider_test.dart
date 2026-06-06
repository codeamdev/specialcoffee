import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/lot_stage_log.dart';
import 'package:special_coffee/domain/repositories/lot_stage_log_repository.dart';
import 'package:special_coffee/presentation/providers/workflow_provider.dart';

// ── In-memory fake ────────────────────────────────────────────────────────────

class _FakeRepo implements LotStageLogRepository {
  final List<LotStageLog> _logs = [];
  bool throwOnStart = false;

  @override
  Future<List<LotStageLog>> getByLotId(String lotId) async =>
      _logs.where((l) => l.lotId == lotId).toList();

  @override
  Future<LotStageLog?> getActiveStage(String lotId) async =>
      _logs.where((l) => l.lotId == lotId && !l.isCompleted).firstOrNull;

  @override
  Future<LotStageLog> startStage({
    required String lotId,
    required String stage,
    String? processType,
    double? expectedDurationH,
  }) async {
    if (throwOnStart) throw Exception('DB error');
    final log = LotStageLog(
      id:                'log-$stage',
      lotId:             lotId,
      stage:             stage,
      processType:       processType,
      startedAt:         DateTime.now(),
      expectedDurationH: expectedDurationH,
    );
    _logs.add(log);
    return log;
  }

  @override
  Future<void> completeStage(
    String id, {
    DateTime? completedAt,
    double? phStart,
    double? phEnd,
    double? tempC,
    double? brixValue,
    String? notes,
    String? aiNotes,
  }) async {
    final idx = _logs.indexWhere((l) => l.id == id);
    if (idx < 0) return;
    final old = _logs[idx];
    _logs[idx] = LotStageLog(
      id:                old.id,
      lotId:             old.lotId,
      stage:             old.stage,
      processType:       old.processType,
      startedAt:         old.startedAt,
      expectedDurationH: old.expectedDurationH,
      completedAt:       completedAt ?? DateTime.now(),
      phStart:           phStart,
      phEnd:             phEnd,
      tempC:             tempC,
      brixValue:         brixValue,
      notes:             notes,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _container(_FakeRepo repo) {
  return ProviderContainer(overrides: [
    lotStageLogLocalRepoProvider.overrideWithValue(repo),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkflowNotifier', () {
    test('build returns empty state when no logs', () async {
      final c = _container(_FakeRepo());
      addTearDown(c.dispose);

      final wf = await c.read(workflowProvider('lot-1').future);
      expect(wf.activeStage, isNull);
      expect(wf.completedStages, isEmpty);
      expect(wf.hasActiveStage, isFalse);
    });

    test('startStage adds active stage to state', () async {
      final repo = _FakeRepo();
      final c    = _container(repo);
      addTearDown(c.dispose);

      await c.read(workflowProvider('lot-1').future);
      await c.read(workflowProvider('lot-1').notifier).startStage(
        'fermentation',
        processType:       'lavado',
        expectedDurationH: 27.0,
      );

      final wf = c.read(workflowProvider('lot-1')).value!;
      expect(wf.hasActiveStage, isTrue);
      expect(wf.activeStage!.stage, 'fermentation');
      expect(wf.activeStage!.expectedDurationH, 27.0);
    });

    test('completeStage moves active to completed', () async {
      final repo = _FakeRepo();
      final c    = _container(repo);
      addTearDown(c.dispose);

      await c.read(workflowProvider('lot-1').future);
      await c.read(workflowProvider('lot-1').notifier).startStage('washing');

      final logId = c.read(workflowProvider('lot-1')).value!.activeStage!.id;
      await c.read(workflowProvider('lot-1').notifier).completeStage(
        logId, phEnd: 4.2,
      );

      final wf = c.read(workflowProvider('lot-1')).value!;
      expect(wf.hasActiveStage, isFalse);
      expect(wf.completedStages.length, 1);
      expect(wf.completedStages.first.stage, 'washing');
    });

    test('startStage persistence error sets error in state', () async {
      final repo = _FakeRepo()..throwOnStart = true;
      final c    = _container(repo);
      addTearDown(c.dispose);

      await c.read(workflowProvider('lot-1').future);
      await c.read(workflowProvider('lot-1').notifier).startStage('fermentation');

      final wf = c.read(workflowProvider('lot-1')).value!;
      expect(wf.error, isNotNull);
      expect(wf.hasActiveStage, isFalse);
    });
  });
}
