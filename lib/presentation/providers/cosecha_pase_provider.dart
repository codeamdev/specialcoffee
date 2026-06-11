import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/cosecha_pase.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

part 'cosecha_pase_provider.g.dart';

// â”€â”€ Pases por lote â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@riverpod
Future<List<CosechaPase>> pasesByLot(Ref ref, String lotId) =>
    ref.watch(cosechaPaseLocalRepoProvider).getPasesByLot(lotId);

@riverpod
Future<CosechaPase?> paseById(Ref ref, String paseId) =>
    ref.watch(cosechaPaseLocalRepoProvider).getById(paseId);

// â”€â”€ Pases activos del usuario â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@riverpod
Future<List<CosechaPase>> activePases(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(cosechaPaseLocalRepoProvider).getActivePases(userId);
}

@riverpod
Future<List<CosechaPase>> completedPases(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(cosechaPaseLocalRepoProvider).getCompletedPases(userId);
}

// â”€â”€ Notifier para crear/avanzar pases â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@riverpod
class CosechaPaseNotifier extends _$CosechaPaseNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<CosechaPase> crear({
    required String lotId,
    required DateTime fechaRecoleccion,
    required double pesoCerezaKg,
    required String tipoProceso,
    DateTime? horaInicio,
    DateTime? horaFin,
    int? numOperarios,
    double? brixPromedio,
    double? pctMadurezVisual,
    String? notas,
  }) async {
    state = const AsyncValue.loading();
    final repo   = ref.read(cosechaPaseLocalRepoProvider);
    final userId = ref.read(currentUserIdProvider);
    late CosechaPase result;
    try {
      result = await repo.create(
        lotId:            lotId,
        createdBy:        userId,
        fechaRecoleccion: fechaRecoleccion,
        pesoCerezaKg:     pesoCerezaKg,
        tipoProceso:      tipoProceso,
        horaInicio:       horaInicio,
        horaFin:          horaFin,
        numOperarios:     numOperarios,
        brixPromedio:     brixPromedio,
        pctMadurezVisual: pctMadurezVisual,
        notas:            notas,
      );
      state = const AsyncValue.data(null);
      ref.read(syncServiceProvider).syncPendingReadings().ignore();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
    ref.invalidate(pasesByLotProvider(lotId));
    ref.invalidate(activePasesProvider);
    return result;
  }

  Future<void> avanzarEtapa(CosechaPase pase, String nuevaEtapa) async {
    state = const AsyncValue.loading();
    final repo = ref.read(cosechaPaseLocalRepoProvider);
    state = await AsyncValue.guard(() => repo.advanceEtapa(pase.id, nuevaEtapa));
    ref.invalidate(paseByIdProvider(pase.id));
    ref.invalidate(pasesByLotProvider(pase.lotId));
  }

  Future<void> completar(CosechaPase pase) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(cosechaPaseLocalRepoProvider).completar(pase.id),
    );
    ref.invalidate(paseByIdProvider(pase.id));
    ref.invalidate(pasesByLotProvider(pase.lotId));
  }
}
