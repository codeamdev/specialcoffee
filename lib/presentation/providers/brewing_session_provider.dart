import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/brewing_session.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

part 'brewing_session_provider.g.dart';

// ── State ──────────────────────────────────────────────────────────────────

class BrewingSessionState {
  const BrewingSessionState({
    this.isLoading = false,
    this.isSaved   = false,
    this.error,
  });

  final bool    isLoading;
  final bool    isSaved;
  final String? error;

  BrewingSessionState copyWith({
    bool?             isLoading,
    bool?             isSaved,
    String? Function()? error,
  }) =>
      BrewingSessionState(
        isLoading: isLoading ?? this.isLoading,
        isSaved:   isSaved   ?? this.isSaved,
        error:     error     != null ? error() : this.error,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

@riverpod
class BrewingSessionNotifier extends _$BrewingSessionNotifier {
  @override
  BrewingSessionState build() => const BrewingSessionState();

  Future<void> save({
    required String   method,
    required double   doseG,
    required double   waterG,
    required double   waterTempC,
    int?              actualTimeSec,
    double?           tdsPct,
    double?           yieldG,
    String?           notes,
    required DateTime brewedAt,
  }) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final repo = ref.read(brewingSessionLocalRepoProvider);
      final userId = ref.read(currentUserIdProvider);
      await repo.save(BrewingSession(
        id:            '',
        ownerId:       userId,
        method:        method,
        doseG:         doseG,
        waterG:        waterG,
        waterTempC:    waterTempC,
        actualTimeSec: actualTimeSec,
        tdsPct:        tdsPct,
        yieldG:        yieldG,
        notes:         notes,
        brewedAt:      brewedAt,
        createdAt:     DateTime.now(),
      ));
      state = state.copyWith(isLoading: false, isSaved: true);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[BrewingSessionProvider] save: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        error: () => 'No se pudo guardar la sesión de preparación.',
      );
    }
  }
}
