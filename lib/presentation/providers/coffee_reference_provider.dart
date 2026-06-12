import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';

part 'coffee_reference_provider.g.dart';

@riverpod
Stream<List<CoffeeReference>> coffeeReferences(Ref ref) =>
    ref.watch(coffeeReferenceLocalRepoProvider).watchAll();

// ── Mutation state ─────────────────────────────────────────────────────────

class CoffeeReferenceState {
  const CoffeeReferenceState({
    this.isLoading = false,
    this.isSaved   = false,
    this.saved,
    this.error,
  });

  final bool               isLoading;
  final bool               isSaved;
  final CoffeeReference?   saved;
  final Object?            error;

  CoffeeReferenceState copyWith({
    bool?              isLoading,
    bool?              isSaved,
    CoffeeReference?   saved,
    Object?            error,
  }) =>
      CoffeeReferenceState(
        isLoading: isLoading ?? this.isLoading,
        isSaved:   isSaved   ?? this.isSaved,
        saved:     saved     ?? this.saved,
        error:     error,
      );
}

@riverpod
class CoffeeReferenceNotifier extends _$CoffeeReferenceNotifier {
  @override
  CoffeeReferenceState build() => const CoffeeReferenceState();

  Future<void> save(CoffeeReference reference) async {
    state = state.copyWith(isLoading: true);
    try {
      final saved = await ref.read(coffeeReferenceLocalRepoProvider).save(reference);
      state = CoffeeReferenceState(isSaved: true, saved: saved);
    } catch (e) {
      state = CoffeeReferenceState(error: e);
    }
  }

  void reset() => state = const CoffeeReferenceState();

  Future<void> updateStatus(String id, String status) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(coffeeReferenceLocalRepoProvider).updateStatus(id, status);
      state = const CoffeeReferenceState(isSaved: true);
    } catch (e) {
      state = CoffeeReferenceState(error: e);
    }
  }
}
