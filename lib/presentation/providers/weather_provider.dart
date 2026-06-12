import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/services/gps_service.dart';
import 'package:special_coffee/data/repositories/weather_repository_impl.dart';
import 'package:special_coffee/domain/entities/weather_data.dart';
import 'package:special_coffee/domain/repositories/weather_repository.dart';

part 'weather_provider.g.dart';

// ── Infraestructura ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
GpsService gpsService(Ref ref) => GpsService();

@Riverpod(keepAlive: true)
Future<WeatherRepository> weatherRepository(Ref ref) =>
    WeatherRepositoryImpl.open();

// ── Estado del clima ─────────────────────────────────────────────────────────

@riverpod
class WeatherNotifier extends _$WeatherNotifier {
  @override
  AsyncValue<WeatherData?> build() => const AsyncData(null);

  /// Intenta obtener clima para [lat]/[lng].
  /// Si falla (sin red, sin key), devuelve el dato cacheado (puede ser null).
  /// La UI decide si muestra entrada manual basándose en el resultado.
  Future<WeatherData?> fetchForLocation({
    required double lat,
    required double lng,
  }) async {
    state = const AsyncLoading();
    final repo = await ref.read(weatherRepositoryProvider.future);
    try {
      final data = await repo.getWeather(lat: lat, lng: lng);
      state = AsyncData(data);
      return data;
    } catch (_) {
      final cached = await repo.getCached();
      state = AsyncData(cached);
      return cached;
    }
  }

  Future<void> saveManual(WeatherData data) async {
    final repo = await ref.read(weatherRepositoryProvider.future);
    await repo.saveManual(data);
    state = AsyncData(data);
  }
}

// ── GPS ──────────────────────────────────────────────────────────────────────

@riverpod
Future<GpsResult?> currentGpsPosition(Ref ref) async {
  try {
    return await ref.read(gpsServiceProvider).getCurrentPosition();
  } on GpsPermissionDeniedException {
    return null;
  } on GpsUnavailableException {
    return null;
  }
}
