import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/water_profile.dart';

part 'water_profile_provider.g.dart';

@riverpod
Stream<List<WaterProfile>> waterProfiles(Ref ref) =>
    ref.watch(waterProfileLocalRepoProvider).watchAll();

// ── Mutation state ─────────────────────────────────────────────────────────

class WaterProfileState {
  const WaterProfileState({
    this.isLoading = false,
    this.isSaved = false,
    this.error,
  });

  final bool    isLoading;
  final bool    isSaved;
  final Object? error;

  WaterProfileState copyWith({
    bool?    isLoading,
    bool?    isSaved,
    Object?  error,
  }) =>
      WaterProfileState(
        isLoading: isLoading ?? this.isLoading,
        isSaved:   isSaved   ?? this.isSaved,
        error:     error,
      );
}

@riverpod
class WaterProfileNotifier extends _$WaterProfileNotifier {
  @override
  WaterProfileState build() => const WaterProfileState();

  Future<void> save(WaterProfile profile) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(waterProfileLocalRepoProvider).save(profile);
      state = const WaterProfileState(isSaved: true);
    } catch (e) {
      state = WaterProfileState(error: e);
    }
  }
}
