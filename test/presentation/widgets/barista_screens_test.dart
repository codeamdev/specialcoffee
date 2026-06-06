import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';
import 'package:special_coffee/domain/entities/water_profile.dart';
import 'package:special_coffee/domain/repositories/coffee_reference_repository.dart';
import 'package:special_coffee/domain/repositories/water_profile_repository.dart';
import 'package:special_coffee/presentation/screens/barista/barista_home_screen.dart';
import 'package:special_coffee/presentation/screens/barista/brew_session_wizard.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeCoffeeRepo implements CoffeeReferenceRepository {
  _FakeCoffeeRepo([this._items = const []]);

  final List<CoffeeReference> _items;

  @override Future<List<CoffeeReference>> getAll() async => _items;
  @override Stream<List<CoffeeReference>> watchAll() => Stream.value(_items);
  @override Future<CoffeeReference?> getById(String id) async => null;
  @override Future<CoffeeReference> save(CoffeeReference r) async => r;
  @override Future<void> updateStatus(String id, String status) async {}
}

class _FakeWaterRepo implements WaterProfileRepository {
  @override Future<List<WaterProfile>> getAll() async => const [];
  @override Stream<List<WaterProfile>> watchAll() => Stream.value(const []);
  @override Future<WaterProfile?> getById(String id) async => null;
  @override Future<WaterProfile> save(WaterProfile p) async => p;
}

// ── Widget wrapper (no GoRouter — avoids navigation in unit-level tests) ──────

Widget _wrap(Widget child, {
  CoffeeReferenceRepository? coffeeRepo,
  WaterProfileRepository?    waterRepo,
}) =>
    ProviderScope(
      overrides: [
        coffeeReferenceLocalRepoProvider
            .overrideWith((ref) => coffeeRepo ?? _FakeCoffeeRepo()),
        waterProfileLocalRepoProvider
            .overrideWith((ref) => waterRepo ?? _FakeWaterRepo()),
      ],
      child: MaterialApp(home: child),
    );

// ── BaristaHomeScreen ─────────────────────────────────────────────────────────

void main() {
  group('BaristaHomeScreen', () {
    testWidgets('shows empty state when no coffee references', (tester) async {
      await tester.pumpWidget(_wrap(const BaristaHomeScreen()));
      await tester.pump();

      expect(find.text('Sin referencias de café'), findsOneWidget);
      expect(find.text('Agregar café'), findsWidgets);
    });

    testWidgets('shows coffee reference card when list is non-empty',
        (tester) async {
      final ref = CoffeeReference(
        id:         'r1',
        ownerId:    'u1',
        name:       'Huila Especial',
        roastLevel: 'light',
        createdAt:  DateTime(2025),
        updatedAt:  DateTime(2025),
      );
      await tester.pumpWidget(
        _wrap(const BaristaHomeScreen(), coffeeRepo: _FakeCoffeeRepo([ref])),
      );
      await tester.pump();

      expect(find.text('Huila Especial'), findsOneWidget);
      expect(find.text('Mis cafés'), findsOneWidget);
    });

    testWidgets('shows roast level chip for each reference', (tester) async {
      final ref = CoffeeReference(
        id:         'r2',
        ownerId:    'u1',
        name:       'Nariño Dark',
        roastLevel: 'dark',
        createdAt:  DateTime(2025),
        updatedAt:  DateTime(2025),
      );
      await tester.pumpWidget(
        _wrap(const BaristaHomeScreen(), coffeeRepo: _FakeCoffeeRepo([ref])),
      );
      await tester.pump();

      expect(find.text('Oscuro'), findsOneWidget);
    });
  });

  // ── BrewSessionWizard ───────────────────────────────────────────────────────

  group('BrewSessionWizard', () {
    testWidgets('renders step 0 (Café) initially', (tester) async {
      await tester.pumpWidget(_wrap(const BrewSessionWizard()));
      await tester.pump();

      // Stepper may render step label in multiple subtrees — use findsWidgets
      expect(find.text('Café'), findsWidgets);
      expect(find.text('Nueva preparación'), findsOneWidget);
    });

    testWidgets('step 0 shows empty hint when no coffee references',
        (tester) async {
      await tester.pumpWidget(_wrap(const BrewSessionWizard()));
      await tester.pump();

      expect(find.textContaining('Sin cafés'), findsOneWidget);
    });

    testWidgets('Siguiente advances to step 1 (Perfil de agua)', (tester) async {
      await tester.pumpWidget(_wrap(const BrewSessionWizard()));
      await tester.pump();

      // Stepper renders controls for each step — tap the first Siguiente
      await tester.tap(find.text('Siguiente').first);
      await tester.pumpAndSettle();

      expect(find.text('Perfil de agua'), findsWidgets);
    });

    testWidgets('Atrás returns to previous step', (tester) async {
      await tester.pumpWidget(_wrap(const BrewSessionWizard()));
      await tester.pump();

      await tester.tap(find.text('Siguiente').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atrás').first);
      await tester.pumpAndSettle();

      expect(find.text('Café'), findsWidgets);
    });

    testWidgets('shows coffee reference tile when list has items', (tester) async {
      final ref = CoffeeReference(
        id:         'r1',
        ownerId:    'u1',
        name:       'Geisha Especial',
        roastLevel: 'light',
        createdAt:  DateTime(2025),
        updatedAt:  DateTime(2025),
      );
      await tester.pumpWidget(
        _wrap(const BrewSessionWizard(), coffeeRepo: _FakeCoffeeRepo([ref])),
      );
      await tester.pump();

      expect(find.text('Geisha Especial'), findsOneWidget);
    });
  });
}
