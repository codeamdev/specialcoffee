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

    testWidgets('latitude, longitude, farm area and plant age fields are disabled',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final disabled = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((f) => f.enabled == false)
          .length;

      // lat + lng + farmArea + plantAge = 4 disabled text fields
      expect(disabled, 4);
    });

    testWidgets('plant type selector is wrapped in IgnorePointer', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final ignorePointers = tester
          .widgetList<IgnorePointer>(find.byType(IgnorePointer))
          .where((w) => w.ignoring)
          .toList();

      expect(ignorePointers, isNotEmpty);
    });

    testWidgets('altitude and region fields remain enabled', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final enabled = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((f) => f.enabled != false)
          .length;

      // altitude + region = 2 enabled text fields (notes also enabled = 3)
      expect(enabled, greaterThanOrEqualTo(2));
    });
  });
}
