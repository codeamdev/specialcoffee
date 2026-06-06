import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/presentation/screens/auth/login_screen.dart';
import 'package:special_coffee/presentation/screens/auth/onboarding_screen.dart';
import 'package:special_coffee/presentation/screens/auth/splash_screen.dart';
import 'package:special_coffee/presentation/screens/barista/barista_home_screen.dart';
import 'package:special_coffee/presentation/screens/barista/brew_session_wizard.dart';
import 'package:special_coffee/presentation/screens/brewing/brew_diagnosis_screen.dart';
import 'package:special_coffee/presentation/screens/brewing/brew_recipe_screen.dart';
import 'package:special_coffee/presentation/screens/brewing/brew_screen.dart';
import 'package:special_coffee/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:special_coffee/presentation/screens/drying/drying_screen.dart';
import 'package:special_coffee/presentation/screens/fermentation/fermentation_screen.dart';
import 'package:special_coffee/presentation/screens/classification/classification_screen.dart';
import 'package:special_coffee/presentation/screens/cupping/cupping_screen.dart';
import 'package:special_coffee/presentation/screens/depulping/depulping_screen.dart';
import 'package:special_coffee/presentation/screens/harvest/harvest_screen.dart';
import 'package:special_coffee/presentation/screens/milling/milling_screen.dart';
import 'package:special_coffee/presentation/screens/washing/washing_screen.dart';
import 'package:special_coffee/presentation/screens/lot/lot_create_screen.dart';
import 'package:special_coffee/presentation/screens/lot/lot_detail_screen.dart';
import 'package:special_coffee/presentation/screens/lot/lot_list_screen.dart';
import 'package:special_coffee/presentation/screens/admin/admin_screen.dart';
import 'package:special_coffee/presentation/screens/profile/profile_screen.dart';
import 'package:special_coffee/presentation/screens/shell/main_shell.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

part 'app_router.g.dart';

// Bridges Riverpod auth state to GoRouter's refreshListenable.
// Avoids recreating the GoRouter on every auth state change — without this,
// a rapid AsyncLoading→AsyncData transition disposes userLotsProvider mid-flight
// and the unhandled DioException escapes the zone, killing the process.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.onDispose(dispose);
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).value != null;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.onboarding;

      if (isSplash) return null;
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && isAuthRoute) return AppRoutes.home;

      // Guard: /admin is restricted to role 'admin'
      if (state.matchedLocation == AppRoutes.admin) {
        final user = ref.read(authProvider).value;
        if (user == null || user.role != 'admin') return AppRoutes.home;
      }

      // Redirect barista from generic /home to their dedicated screen
      if (state.matchedLocation == AppRoutes.home) {
        final user = ref.read(authProvider).value;
        if (user?.role == 'barista') return AppRoutes.baristaHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _noTransitionPage(
              const DashboardScreen(),
              state,
            ),
          ),
          GoRoute(
            path: AppRoutes.lots,
            pageBuilder: (context, state) => _noTransitionPage(
              const LotListScreen(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const LotCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => LotDetailScreen(
                  lotId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'fermentation',
                    builder: (context, state) => FermentationScreen(
                      lotId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'drying',
                    builder: (context, state) => DryingScreen(
                      lotId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'harvest',
                    builder: (context, state) => HarvestScreen(
                      lotId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'classification',
                    builder: (context, state) => ClassificationScreen(
                      lotId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'depulping',
                    builder: (context, state) => DepulpingScreen(
                      lotId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'washing',
                    builder: (context, state) => WashingScreen(
                      lotId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'milling',
                    builder: (context, state) => MillingScreen(
                      lotId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'cupping',
                    builder: (context, state) => CuppingScreen(
                      lotId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.baristaHome,
            pageBuilder: (context, state) => _noTransitionPage(
              const BaristaHomeScreen(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'wizard',
                builder: (context, state) => const BrewSessionWizard(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.brew,
            pageBuilder: (context, state) => _noTransitionPage(
              const BrewScreen(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'recipe',
                builder: (context, state) => BrewRecipeScreen(
                  params: state.extra as Map<String, dynamic>? ?? {},
                ),
              ),
              GoRoute(
                path: 'diagnosis',
                builder: (context, state) => BrewDiagnosisScreen(
                  params: state.extra as Map<String, dynamic>? ?? {},
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _noTransitionPage(
              const ProfileScreen(),
              state,
            ),
          ),
          GoRoute(
            path: AppRoutes.admin,
            builder: (context, state) => const AdminScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

CustomTransitionPage<void> _noTransitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    transitionsBuilder: (_, __, ___, child) => child,
  );
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Ruta no encontrada\n${error?.toString() ?? ''}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
