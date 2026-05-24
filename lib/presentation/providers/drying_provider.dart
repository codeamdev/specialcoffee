import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';

part 'drying_provider.g.dart';

// ── Domain ─────────────────────────────────────────────────────────────────

class DryingReading {
  const DryingReading({
    required this.dayNumber,
    required this.moisturePct,
    required this.ambientTempC,
    required this.ambientHumidityPct,
    this.uvIndex = 0.0,
    required this.recordedAt,
  });

  final int      dayNumber;
  final double   moisturePct;
  final double   ambientTempC;
  final double   ambientHumidityPct;
  final double   uvIndex;
  final DateTime recordedAt;
}

// ── State ──────────────────────────────────────────────────────────────────

class DryingState {
  const DryingState({
    required this.lotId,
    this.dryingMethod = 'camas_africanas',
    this.readings = const [],
    this.recommendations = const [],
    this.isAnalyzing = false,
  });

  final String               lotId;
  final String               dryingMethod;
  final List<DryingReading>  readings;
  final List<Recommendation> recommendations;
  final bool                 isAnalyzing;

  bool get hasReadings  => readings.isNotEmpty;
  DryingReading? get lastReading => readings.isEmpty ? null : readings.last;

  bool get isAtTarget {
    if (!hasReadings) return false;
    final m = lastReading!.moisturePct;
    return m >= 10.5 && m <= 12.0;
  }

  bool get isOverDried => hasReadings && lastReading!.moisturePct < 10.0;

  DryingState copyWith({
    String? dryingMethod,
    List<DryingReading>? readings,
    List<Recommendation>? recommendations,
    bool? isAnalyzing,
  }) =>
      DryingState(
        lotId: lotId,
        dryingMethod: dryingMethod ?? this.dryingMethod,
        readings: readings ?? this.readings,
        recommendations: recommendations ?? this.recommendations,
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

@riverpod
class DryingNotifier extends _$DryingNotifier {
  @override
  DryingState build(String lotId) => DryingState(lotId: lotId);

  Future<void> addReading({
    required double moisturePct,
    required double ambientTempC,
    required double ambientHumidityPct,
    double uvIndex = 0.0,
  }) async {
    final dayNumber = state.readings.length + 1;
    final newReading = DryingReading(
      dayNumber: dayNumber,
      moisturePct: moisturePct,
      ambientTempC: ambientTempC,
      ambientHumidityPct: ambientHumidityPct,
      uvIndex: uvIndex,
      recordedAt: DateTime.now(),
    );
    final updatedReadings = [...state.readings, newReading];

    state = state.copyWith(readings: updatedReadings, isAnalyzing: true);

    try {
      final userId  = ref.read(currentUserIdProvider);
      final roleStr = ref.read(currentUserProvider)?.role ?? 'farmer';
      final userRole = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.farmer,
      );
      final lot = await ref.read(lotByIdProvider(state.lotId).future);

      final aiContext = AIContext(
        userId: userId,
        userRole: userRole,
        module: 'drying',
        lotId: state.lotId,
        varietyId: lot?.varietyId ?? 'unknown',
        altitudeMasl: lot?.altitudeMasl ?? 1500,
        region: lot?.region ?? '',
        ambientTempC: ambientTempC,
        ambientHumidityPct: ambientHumidityPct,
        rainProbabilityPct: lot?.rainProbabilityPct ?? 0.0,
        uvIndex: uvIndex,
        processType: state.dryingMethod,
        currentHumidityPct: moisturePct,
        dryingDayNumber: dayNumber,
        userLotsCompleted: 0,
      );

      final engine = await ref.read(aiEngineProvider.future);
      final recs   = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);
      state = state.copyWith(recommendations: recs, isAnalyzing: false);
    } catch (_) {
      state = state.copyWith(isAnalyzing: false);
    }
  }

  void changeDryingMethod(String method) {
    if (state.hasReadings) return;
    state = DryingState(lotId: state.lotId, dryingMethod: method);
  }

  void reset() =>
      state = DryingState(lotId: state.lotId, dryingMethod: state.dryingMethod);
}
