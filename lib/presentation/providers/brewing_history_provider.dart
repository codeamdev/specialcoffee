import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/brewing_session.dart';

part 'brewing_history_provider.g.dart';

@riverpod
Future<List<BrewingSession>> recentBrewingSessions(Ref ref) =>
    ref.read(appDatabaseProvider).brewingSessionDao.getRecent(limit: 5);

// ── Preference model ──────────────────────────────────────────────────────

class BrewingTdsPrefs {
  const BrewingTdsPrefs({
    required this.tdsMin,
    required this.tdsMax,
    required this.sessionCount,
  });

  final double tdsMin;
  final double tdsMax;
  final int    sessionCount;

  bool get hasEnoughData => sessionCount >= 5;

  static const defaults = BrewingTdsPrefs(
    tdsMin: 1.30, tdsMax: 1.38, sessionCount: 0,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────

@riverpod
Future<BrewingTdsPrefs> brewingTdsPrefs(Ref ref, String userId) async {
  final dao      = ref.read(appDatabaseProvider).brewingSessionDao;
  final sessions = await dao.getByOwner(userId);
  final withTds  = sessions.where((s) => (s.tdsPct ?? 0) > 0).toList();

  if (withTds.length < 5) return BrewingTdsPrefs.defaults;

  final values = withTds.map((s) => s.tdsPct!).toList()..sort();
  // 10th–90th percentile to avoid outliers
  final p10 = values[(values.length * 0.10).floor()];
  final p90 = values[((values.length * 0.90).ceil() - 1).clamp(0, values.length - 1)];

  return BrewingTdsPrefs(
    tdsMin:       double.parse(p10.toStringAsFixed(2)),
    tdsMax:       double.parse(p90.toStringAsFixed(2)),
    sessionCount: withTds.length,
  );
}
