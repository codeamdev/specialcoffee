import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/brewing_session.dart';
import 'package:special_coffee/domain/repositories/brewing_session_repository.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/brew_provider.dart';
import 'package:special_coffee/presentation/screens/brewing/brew_diagnosis_screen.dart';
import 'package:special_coffee/presentation/screens/brewing/brew_recipe_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FakeAdapter extends InferenceAdapter {
  @override Future<void> initialize() async {}
  @override bool get isReady => true;
  @override String get version => 'fake';
  @override Future<List<Recommendation>> infer(context) async => const [];
}

class _FakeBrewingRepo implements BrewingSessionRepository {
  @override
  Future<BrewingSession> save(BrewingSession s) async => BrewingSession(
        id: 'fake', ownerId: '', method: s.method, doseG: s.doseG,
        waterG: s.waterG, waterTempC: s.waterTempC,
        brewedAt: s.brewedAt, createdAt: s.createdAt,
      );
  @override
  Future<List<BrewingSession>> getRecent({int limit = 20}) async => const [];
}

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        aiEngineProvider.overrideWith(
            (ref) async => AIEngine.withAdapter(adapter: _FakeAdapter())),
        brewingSessionLocalRepoProvider
            .overrideWith((ref) => _FakeBrewingRepo()),
      ],
      child: MaterialApp(home: child),
    );

// ── BrewRecipeScreen ──────────────────────────────────────────────────────────

void main() {
  group('BrewRecipeScreen', () {
    testWidgets('shows fallback when no recipe in state', (tester) async {
      await tester.pumpWidget(_wrap(const BrewRecipeScreen(params: {})));
      await tester.pumpAndSettle();

      expect(find.textContaining('No hay receta activa'), findsOneWidget);
    });

    testWidgets('shows recipe params when recipe is set', (tester) async {
      final recipe = BrewRecipe(
        method: 'v60', doseG: 15, waterG: 250, ratio: 16.7,
        waterTempC: 93, bloomG: 30, bloomSeconds: 30,
        tdsTargetMin: 1.15, tdsTargetMax: 1.45,
        yieldTargetMin: 18, yieldTargetMax: 22,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiEngineProvider.overrideWith(
                (ref) async => AIEngine.withAdapter(adapter: _FakeAdapter())),
            brewProvider.overrideWith(
                () => _FakeBrewNotifier(recipe: recipe)),
          ],
          child: MaterialApp(home: BrewRecipeScreen(params: const {})),
        ),
      );
      await tester.pumpAndSettle();

      // AppBar visible + fallback text NOT shown = recipe rendered
      expect(find.text('Receta generada'),            findsOneWidget);
      expect(find.textContaining('No hay receta'),    findsNothing);
    });
  });

  // ── BrewDiagnosisScreen ─────────────────────────────────────────────────────

  group('BrewDiagnosisScreen', () {
    testWidgets('renders form fields', (tester) async {
      await tester.pumpWidget(
        _wrap(BrewDiagnosisScreen(params: const {
          'method': 'v60', 'doseG': 15.0, 'waterG': 250.0, 'waterTempC': 93.0,
        })),
      );
      await tester.pump();

      expect(find.text('Diagnóstico post-extracción'), findsOneWidget);
      expect(find.text('Tiempo real (seg)'),           findsOneWidget);
      expect(find.text('TDS medido (%)'),               findsOneWidget);
      expect(find.text('Rendimiento (g)'),              findsOneWidget);
      expect(find.text('Notas de cata'),                findsOneWidget);
      expect(find.text('Guardar y volver'),             findsOneWidget);
    });

    testWidgets('shows recipe summary chip row', (tester) async {
      await tester.pumpWidget(
        _wrap(BrewDiagnosisScreen(params: const {
          'method': 'chemex', 'doseG': 20.0, 'waterG': 300.0, 'waterTempC': 94.0,
        })),
      );
      await tester.pump();

      // method chip shows in summary bar
      expect(find.text('chemex'), findsOneWidget);
    });
  });
}

// ── FakeBrewNotifier para inyectar receta en el provider ─────────────────────

class _FakeBrewNotifier extends BrewNotifier {
  _FakeBrewNotifier({required BrewRecipe recipe}) : _recipe = recipe;
  final BrewRecipe _recipe;

  @override
  BrewState build() => BrewState(recipe: _recipe);
}
