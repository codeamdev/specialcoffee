abstract final class AppConstants {
  // App info
  static const String appName = 'SpecialCoffee AI';
  static const String appVersion = '1.0.0';

  // SCA quality threshold
  static const double scaMinScore = 80.0;
  static const double scaSpecialtyThreshold = 85.0;

  // AI Engine
  static const int ruleEngineTimeoutMs = 5;
  static const double lowConfidenceThreshold = 0.75;
  static const int alertEngineIntervalSeconds = 30;

  // Fermentation thresholds (base — overridden per process in AlertEngine)
  static const double phCriticalLow = 3.5;
  static const double phOptimalLow = 4.0;
  static const double phOptimalHigh = 4.5;
  static const double tempCriticalHigh = 30.0;
  static const double tempOptimalHigh = 25.0;

  // Harvest — use CoffeeThresholds for rule thresholds; these are kept for
  // any UI display that needs them independently of the AI engine.
  static const double brixOptimalLow = 18.0;
  static const double brixOptimalHigh = 24.0;
  static const int cherryColorPctMinimal = 75;

  // Brewing
  static const double tdsTargetLow = 1.15;
  static const double tdsTargetHigh = 1.45;
  static const double extractionYieldLow = 18.0;
  static const double extractionYieldHigh = 22.0;

  // Sync
  static const int syncRetryMaxAttempts = 3;
  static const int syncRetryDelaySeconds = 30;
  static const int offlineQueueMaxSize = 500;

  // Remote Config keys
  static const String rcKeyRulesVersion = 'ai_rules_version';
  static const String rcKeyRulesJson = 'ai_rules_json';
  static const String rcKeyMinAppVersion = 'min_app_version';

  // Hive boxes
  static const String hiveBoxRules = 'ai_rules';
  static const String hiveBoxPreferences = 'user_preferences';
  static const String hiveBoxCache = 'general_cache';

  // Notification channels
  static const String notifChannelCritical = 'critical_alerts';
  static const String notifChannelWarning = 'warning_alerts';
  static const String notifChannelInfo = 'info_updates';
}

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String lots = '/lots';
  static const String lotDetail = '/lots/:id';
  static const String lotCreate = '/lots/create';
  static const String fermentation = '/lots/:id/fermentation';
  static const String washing      = '/lots/:id/washing';
  static const String drying = '/lots/:id/drying';
  static const String harvest        = '/lots/:id/harvest';
  static const String classification = '/lots/:id/classification';
  static const String depulping      = '/lots/:id/depulping';
  static const String cupping        = '/lots/:id/cupping';
  static const String milling        = '/lots/:id/milling';
  static const String baristaHome = '/barista';
  static const String baristaWizard = '/barista/wizard';
  static const String brew = '/brew';
  static const String brewRecipe = '/brew/recipe';
  static const String brewDiagnosis = '/brew/diagnosis';
  static const String brewHistory = '/brew/history';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String admin = '/admin';
}
