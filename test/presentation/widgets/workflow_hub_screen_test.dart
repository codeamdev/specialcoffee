import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/domain/entities/lot_stage_log.dart';
import 'package:special_coffee/domain/repositories/lot_stage_log_repository.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/providers/workflow_provider.dart';
import 'package:special_coffee/presentation/screens/lot/workflow_hub_screen.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeRepo implements LotStageLogRepository {
  @override Future<List<LotStageLog>> getByLotId(String lotId) async => [];
  @override Future<LotStageLog?> getActiveStage(String lotId) async => null;
  @override Future<LotStageLog> startStage({
    required String lotId, required String stage,
    String? processType, double? expectedDurationH,
  }) async => LotStageLog(
    id: 'log-1', lotId: lotId, stage: stage,
    startedAt: DateTime.now(),
  );
  @override Future<void> completeStage(String id, {
    DateTime? completedAt, double? phStart, double? phEnd,
    double? tempC, double? brixValue, String? notes, String? aiNotes,
  }) async {}
}

Lot _fakeLot(String id) => Lot(
  id:                 id,
  userId:             'u1',
  varietyId:          'v1',
  varietyName:        'Caturra',
  region:             'Huila',
  altitudeMasl:       1800,
  processType:        'lavado',
  ambientTempC:       20.0,
  ambientHumidityPct: 70.0,
  rainProbabilityPct: 10.0,
  status:             'fermenting',
  createdAt:          DateTime(2026, 1, 1),
);

// ── Test widget builder ───────────────────────────────────────────────────────

Widget _buildTestApp(String lotId) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => WorkflowHubScreen(lotId: lotId),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      lotStageLogLocalRepoProvider.overrideWithValue(_FakeRepo()),
      lotByIdProvider(lotId).overrideWith((_) async => _fakeLot(lotId)),
      workflowProvider(lotId).overrideWith(
        () => WorkflowNotifier(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WorkflowHubScreen shows stage list for lavado lot', (tester) async {
    await tester.pumpWidget(_buildTestApp('lot-123'));
    await tester.pumpAndSettle();

    // Should show the screen title
    expect(find.text('Seguimiento de lote'), findsOneWidget);

    // lavado stages: fermentation, washing, drying, milling
    // At minimum the first stage label must appear
    expect(find.textContaining('Fermentación'), findsWidgets);
  });

  testWidgets('WorkflowHubScreen shows Iniciar etapa when no active stage', (tester) async {
    await tester.pumpWidget(_buildTestApp('lot-456'));
    await tester.pumpAndSettle();

    // With no active stage, the first pending stage should show "Iniciar etapa"
    expect(find.text('Iniciar etapa'), findsAtLeastNWidgets(1));
  });
}
