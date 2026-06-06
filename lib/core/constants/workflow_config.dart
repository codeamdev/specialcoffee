/// Expected stage durations for the workflow tracker.
/// Midpoints of the documented ranges — used to calculate isOverdue and
/// schedule stage-end notifications.
///
/// Source: PLAN_EJECUCION.md E1 (based on Manual del Cafetero FNC/Cenicafé
/// and specialty processing literature).
abstract final class WorkflowConfig {
  // Expected fermentation hours by process type.
  // honey_yellow/natural = 0 → no tank fermentation, not tracked.
  static double fermentationExpectedH(String processType) => switch (processType) {
    'lavado'           => 27.0,  // 18–36h midpoint
    'anaerobic_lactic' => 72.0,  // 48–96h midpoint
    _                  => 0.0,   // honey/natural: skip
  };

  // Washing: 1–4h → midpoint 2.5h
  static const double washingExpectedH = 2.5;

  // Drying by process type
  static double dryingExpectedH(String processType) => switch (processType) {
    'lavado' => 360.0,  // 12–18 days × 24h/day = 288–432h → mid 360h
    _        => 480.0,  // natural/honey: 15–25 days → mid 480h
  };

  // Milling: 4–8h → midpoint 6h
  static const double millingExpectedH = 6.0;

  /// Returns expected hours for a given stage + processType, or 0 if not tracked.
  static double expectedH(String stage, String processType) => switch (stage) {
    'fermentation' => fermentationExpectedH(processType),
    'washing'      => washingExpectedH,
    'drying'       => dryingExpectedH(processType),
    'milling'      => millingExpectedH,
    _              => 0.0,
  };

  // All stages in order per process type
  static List<String> stagesFor(String processType) => processType == 'natural'
      ? ['harvest', 'classification', 'drying', 'milling', 'cupping']
      : [
          'harvest', 'classification', 'depulping',
          'fermentation', 'washing', 'drying', 'milling', 'cupping',
        ];

  static String stageLabel(String stage) => switch (stage) {
    'harvest'        => 'Cosecha',
    'classification' => 'Clasificación',
    'depulping'      => 'Despulpado',
    'fermentation'   => 'Fermentación',
    'washing'        => 'Lavado',
    'drying'         => 'Secado',
    'milling'        => 'Trilla',
    'cupping'        => 'Catación',
    _                => stage,
  };
}
