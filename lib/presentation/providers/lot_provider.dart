import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/data/repositories/lot_repository_impl.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/domain/repositories/lot_repository.dart';
import 'package:special_coffee/presentation/providers/ai_engine_provider.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

part 'lot_provider.g.dart';

@Riverpod(keepAlive: true)
LotRepository lotRepository(Ref ref) =>
    PostgRESTLotRepository(ref.read(apiClientProvider));

// ── List providers ─────────────────────────────────────────────────────────

/// All lots for the authenticated user, ordered by newest first.
@riverpod
Future<List<Lot>> userLots(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId.isEmpty) return [];
  return ref.read(lotRepositoryProvider).getLots(userId);
}

@riverpod
Future<Lot?> lotById(Ref ref, String id) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId.isEmpty) return null;
  return ref.read(lotRepositoryProvider).getLotById(id, userId);
}

@riverpod
class LotCreateNotifier extends _$LotCreateNotifier {
  @override
  AsyncValue<List<Recommendation>> build() => const AsyncData([]);

  Future<void> createLot({
    required Lot lot,
    required AIContext aiContext,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(lotRepositoryProvider).saveLot(lot);
      ref.invalidate(userLotsProvider);
      final engine = await ref.read(aiEngineProvider.future);
      final recs = await engine.recommend(aiContext);
      ref.invalidate(geminiStatusProvider);
      return recs;
    });
  }

  void reset() => state = const AsyncData([]);
}
