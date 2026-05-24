import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/presentation/screens/auth/login_screen.dart';
import 'package:special_coffee/presentation/screens/auth/onboarding_screen.dart';
import 'package:special_coffee/presentation/screens/auth/splash_screen.dart';
import 'package:special_coffee/presentation/screens/brewing/brew_diagnosis_screen.dart';
import 'package:special_coffee/presentation/screens/brewing/brew_recipe_screen.dart';
import 'package:special_coffee/presentation/screens/brewing/brew_screen.dart';
import 'package:special_coffee/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:special_coffee/presentation/screens/drying/drying_screen.dart';
import 'package:special_coffee/presentation/screens/fermentation/fermentation_screen.dart';
import 'package:special_coffee/presentation/screens/lot/lot_create_screen.dart';
import 'package:special_coffee/presentation/screens/lot/lot_detail_screen.dart';
import 'package:special_coffee/presentation/screens/lot/lot_list_screen.dart';
import 'package:special_coffee/presentation/screens/profile/profile_screen.dart';
import 'package:special_coffee/presentation/screens/shell/main_shell.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.onboarding;

      if (isSplash) return null;
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && isAuthRoute) return AppRoutes.home;
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
                ],
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
                builder: (context, state) => const BrewDiagnosisScreen(),
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
