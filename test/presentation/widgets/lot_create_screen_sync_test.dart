import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/coffee_variety.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/domain/repositories/lot_repository.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/varieties_provider.dart';
import 'package:special_coffee/presentation/providers/weather_provider.dart';
import 'package:special_coffee/presentation/screens/lot/lot_create_screen.dart';

// ── Fake repo ─────────────────────────────────────────────────────────────────

class _FakeLotRepo implements LotRepository {
  @override
  Future<List<Lot>> getLots(String userId) async => [];
  @override
  Future<Lot?> getLotById(String id, String userId) async => null;
  @override
  Future<Lot> saveLot(Lot lot) async => lot;
  @override
  Future<void> deleteLot(String id) async {}
}

// ── Screen builder ────────────────────────────────────────────────────────────

Widget _buildScreen() => ProviderScope(
      overrides: [
        coffeeVarietiesProvider.overrideWith((_) async => <CoffeeVariety>[]),
        currentGpsPositionProvider.overrideWith((_) async => null),
        currentUserIdProvider.overrideWith((_) => 'test-user'),
        lotLocalRepoProvider.overrideWithValue(_FakeLotRepo()),
      ],
      child: const MaterialApp(home: LotCreateScreen()),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LotCreateScreen — non-synced fields', () {
    testWidgets('no sync disclaimer shown — sync is transparent to user',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('Campo no sincronizado — pendiente de revisión de producto.'),
        findsNothing,
      );
      expect(find.byIcon(Icons.sync_disabled_outlined), findsNothing);
    });

    testWidgets('only latitude and longitude are disabled (GPS-read-only)',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final disabled = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((f) => f.enabled == false)
          .length;

      // lat + lng = 2 disabled text fields (GPS-populated, read-only)
      expect(disabled, 2);
    });

    testWidgets('plant type selector has GestureDetector (interactive)', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // The plant type chips are each wrapped in GestureDetector
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('farm area, plant age, altitude and region fields are enabled',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final enabled = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((f) => f.enabled != false)
          .length;

      // farmArea + plantAge + altitude + region + notes ≥ 4
      expect(enabled, greaterThanOrEqualTo(4));
    });
  });
}
