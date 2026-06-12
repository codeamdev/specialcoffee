import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/fermentation_session.dart';
import 'package:special_coffee/domain/repositories/fermentation_repository.dart';
import 'package:special_coffee/presentation/providers/settings_provider.dart';
import 'package:special_coffee/presentation/screens/fermentation/fermentation_screen.dart';

// ── Fake repo ─────────────────────────────────────────────────────────────────

class _FakeRepo implements FermentationRepository {
  @override
  Future<FermentationSession> createSession({
    required String lotId,
    required String processType,
  }) async => FermentationSession(
        id: 'sid',
        lotId: lotId,
        ownerId: 'u1',
        processType: processType,
        createdAt: DateTime.now(),
      );

  @override
  Future<FermentationSession?> getActiveSession(String lotId) async => null;

  @override
  Future<FermentationReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int    readingNumber,
    required double hoursElapsed,
    required double phValue,
    required double mucilagoTempC,
    String  mucilageState  = 'liquid',
    double? ambientTempC,
    String  aiAlertLevel   = 'none',
    String? aiAlertRuleId,
    double? aiProjectedEndH,
  }) async => FermentationReadingRecord(
        id: 'rid',
        sessionId: sessionId,
        lotId: lotId,
        ownerId: 'u1',
        readingNumber: readingNumber,
        hoursElapsed: hoursElapsed,
        phValue: phValue,
        mucilagoTempC: mucilagoTempC,
        recordedAt: DateTime.now(),
      );

  @override
  Future<List<FermentationReadingRecord>> getReadings(String sessionId) async => [];

  @override
  Future<void> closeSession({
    required String sessionId,
    required String endReason,
    required double actualDurationH,
    required double phFinal,
  }) async {}

  @override
  Future<double> getAvgCompletedDurationH() async => 0.0;

  @override
  Future<double> getLastCompletedDurationH() async => 0.0;
}

// ── Widget wrapper ────────────────────────────────────────────────────────────

Widget _buildScreen(String lotId) => ProviderScope(
      overrides: [
        fermentationLocalRepoProvider.overrideWithValue(_FakeRepo()),
        // learningModeProvider depends on settingsProvider → Hive; bypass in tests
        learningModeProvider.overrideWithValue(false),
      ],
      child: MaterialApp(home: FermentationScreen(lotId: lotId)),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FermentationScreen', () {
    testWidgets('shows "Fermentación activa" in app bar', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildScreen('lot-1'));
        await tester.pumpAndSettle();
      });
      expect(find.text('Fermentación activa'), findsOneWidget);
    });

    testWidgets('shows process type label in app bar subtitle', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildScreen('lot-abc'));
        await tester.pumpAndSettle();
      });
      expect(find.textContaining('Proceso Lavado'), findsWidgets);
    });

    testWidgets('shows current process type badge', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildScreen('lot-2'));
        await tester.pumpAndSettle();
      });
      // Locked badge shows process type (lavado is default)
      expect(find.textContaining('Proceso Lavado'), findsWidgets);
    });
  });
}
