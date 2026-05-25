class CuppingSession {
  const CuppingSession({
    required this.id,
    required this.lotId,
    required this.ownerId,
    required this.cuppedAt,
    required this.fragranceAroma,
    required this.flavor,
    required this.aftertaste,
    required this.acidity,
    this.acidityIntensity = 'medium',
    required this.body,
    this.bodyLevel = 'medium',
    required this.balance,
    this.uniformityCups = 5,
    this.cleanCupCups = 5,
    this.sweetnessCups = 5,
    required this.overall,
    this.defectsCat1Count = 0,
    this.defectsCat2Count = 0,
    this.aiAlertLevel = 'none',
    this.aiAlertMessage,
    required this.totalScore,
    this.notes,
    required this.createdAt,
  });

  final String   id;
  final String   lotId;
  final String   ownerId;
  final DateTime cuppedAt;

  // ── 10 SCA attributes ─────────────────────────────────────────────────────
  final double fragranceAroma;
  final double flavor;
  final double aftertaste;
  final double acidity;
  final String acidityIntensity;  // 'low'|'medium'|'high'
  final double body;
  final String bodyLevel;          // 'light'|'medium'|'heavy'
  final double balance;
  final int    uniformityCups;    // 0–5 cups; score = cups × 2
  final int    cleanCupCups;
  final int    sweetnessCups;
  final double overall;

  // ── Defects ───────────────────────────────────────────────────────────────
  final int defectsCat1Count;     // penaliza × 4 pts
  final int defectsCat2Count;     // penaliza × 2 pts

  final String  aiAlertLevel;
  final String? aiAlertMessage;
  final double  totalScore;       // stored — authoritative for queries
  final String? notes;
  final DateTime createdAt;

  // ── Computed getters ──────────────────────────────────────────────────────
  double get uniformityScore => uniformityCups * 2.0;
  double get cleanCupScore   => cleanCupCups   * 2.0;
  double get sweetnessScore  => sweetnessCups  * 2.0;

  bool   get isSpecialty => totalScore >= 80.0;

  String get scaCategory => totalScore >= 90 ? 'Outstanding'
      : totalScore >= 85 ? 'Excellent'
      : totalScore >= 80 ? 'Very Good'
      : totalScore >= 70 ? 'Good'
      : 'Comercial';

  // ── Static score computation (used before persisting) ─────────────────────
  static double computeScore({
    required double fragranceAroma,
    required double flavor,
    required double aftertaste,
    required double acidity,
    required double body,
    required double balance,
    required int    uniformityCups,
    required int    cleanCupCups,
    required int    sweetnessCups,
    required double overall,
    required int    defectsCat1Count,
    required int    defectsCat2Count,
  }) {
    final raw = fragranceAroma + flavor + aftertaste + acidity + body + balance +
        (uniformityCups * 2.0) + (cleanCupCups * 2.0) + (sweetnessCups * 2.0) + overall;
    final penalty = defectsCat1Count * 4.0 + defectsCat2Count * 2.0;
    return (raw - penalty).clamp(0.0, 100.0);
  }
}
