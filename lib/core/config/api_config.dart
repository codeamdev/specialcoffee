class ApiConfig {
  // ── Cambiar a false para producción ──────────────────────────────────────
  static const bool _local = true;

  // ── Dev bypass: poner en true si el backend no está corriendo ────────────
  // LOCAL TESTING ONLY — no commitear con true
  static const bool devBypass = false;

  // En local: dos puertos distintos (sin Nginx)
  // En prod:  un solo dominio con Nginx como proxy
  static const String _authBase = _local
      ? 'http://127.0.0.1:8000'      // FastAPI directo
      : 'https://TU_DOMINIO';        // Nginx → /auth/ → puerto 8000

  static const String _pgrstBase = _local
      ? 'http://127.0.0.1:3001'      // PostgREST directo
      : 'https://TU_DOMINIO/api';    // Nginx → /api/ → puerto 3000 (strip prefix)

  // ── Auth endpoints (FastAPI) ──────────────────────────────────────────────
  static const String register = '$_authBase/auth/register';
  static const String login    = '$_authBase/auth/login';
  static const String refresh  = '$_authBase/auth/refresh';
  static const String me       = '$_authBase/auth/me';

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
}
