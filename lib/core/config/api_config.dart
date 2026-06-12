class ApiConfig {
  // Inyectado en build time con --dart-define=DEV_MODE=true.
  // Por defecto false → apunta a producción (specialcoffee.app).
  // Ver docs/build/dart-define-guide.md para comandos exactos.
  static const bool _local =
      bool.fromEnvironment('DEV_MODE', defaultValue: false);

  // ── Dev bypass: poner en true si el backend no está corriendo ────────────
  // LOCAL TESTING ONLY — no commitear con true
  // Para desarrollo local: usa email barista@x.com / processor@x.com / farmer@x.com
  static const bool devBypass = false;

  // Siempre a través de Nginx — misma estructura local y producción.
  // Local:  http://127.0.0.1:3001  (Docker Compose)
  // Prod:   https://api.vermicatalogo.com  (nginx + Let's Encrypt)
  static const String _base = _local
      ? 'http://127.0.0.1:3001'
      : 'https://api.vermicatalogo.com';

  static const String _authBase = _base;          // → /auth/*
  static const String _pgrstBase = '$_base/api';  // → /api/* (nginx strip prefix)

  // ── Auth endpoints (FastAPI) ──────────────────────────────────────────────
  static const String register       = '$_authBase/auth/register';
  static const String login          = '$_authBase/auth/login';
  static const String refresh        = '$_authBase/auth/refresh';
  static const String me             = '$_authBase/auth/me';
  static const String registerDevice = '$_authBase/auth/device';
  static const String fcmToken       = '$_authBase/users/fcm-token';

  // ── PostgREST endpoints ───────────────────────────────────────────────────
  static const String lots                 = '$_pgrstBase/lots';
  static const String farmPlots            = '$_pgrstBase/farm_plots';
  static const String fermentationSessions = '$_pgrstBase/fermentation_sessions';
  static const String fermentationReadings = '$_pgrstBase/fermentation_readings';
  static const String dryingSessions       = '$_pgrstBase/drying_sessions';
  static const String dryingReadings       = '$_pgrstBase/drying_readings';
  static const String brewSessions         = '$_pgrstBase/brew_sessions';
  static const String aiRecommendations    = '$_pgrstBase/ai_recommendations';
  static const String alertEvents          = '$_pgrstBase/alert_events';
  static const String varieties            = '$_pgrstBase/coffee_varieties_catalog';
  static const String aiUserProfiles       = '$_pgrstBase/ai_user_profiles';

  // ── Sync endpoints (nuevas tablas) ────────────────────────────────────────
  static const String cosechaPases           = '$_pgrstBase/cosecha_pases';
  static const String washingSessions        = '$_pgrstBase/washing_sessions';
  static const String millingSessions        = '$_pgrstBase/milling_sessions';
  static const String classificationSessions = '$_pgrstBase/classification_sessions';
}
