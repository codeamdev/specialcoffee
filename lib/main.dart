import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/core/notifications/notification_service.dart';
import 'package:special_coffee/core/router/app_router.dart';
import 'package:special_coffee/core/theme/app_theme.dart';
import 'package:special_coffee/core/utils/riverpod_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch async errors that escape Flutter's frame zone (e.g. a Riverpod
  // FutureProvider failing after its last watcher is disposed).
  // Without this, unhandled zone errors kill the process on desktop/Android.
  //
  // Routes through FlutterError.reportError so the error is:
  //   - debug:   printed to console + visible in DevTools Logging tab
  //   - release: written to system log (logcat/system console) AND forwarded to
  //              any crash reporter registered on FlutterError.onError (e.g.
  //              Crashlytics), making this hook forward-compatible.
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'SpecialCoffee',
      context: ErrorDescription('async error caught by PlatformDispatcher'),
    ));
    return true; // handled — prevents process death
  };

  _configureSystemUI();
  await NotificationService.instance.init();

  runApp(
    ProviderScope(
      observers: [RiverpodLogger()],
      child: const SpecialCoffeeApp(),
    ),
  );
}

void _configureSystemUI() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
}

class SpecialCoffeeApp extends ConsumerWidget {
  const SpecialCoffeeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
