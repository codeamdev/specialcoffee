import 'package:special_coffee/domain/entities/weather_data.dart';

abstract interface class WeatherRepository {
  /// Datos del clima para [lat]/[lng].
  /// Devuelve caché si es fresca (< 2h).
  /// Lanza [WeatherNetworkException] si sin red.
  /// Lanza [WeatherApiKeyNotConfiguredException] si sin API key.
  Future<WeatherData> getWeather({required double lat, required double lng});

  /// Guarda datos ingresados manualmente.
  Future<void> saveManual(WeatherData data);

  /// Último dato guardado (puede ser stale o manual). Null si nunca hubo dato.
  Future<WeatherData?> getCached();
}

class WeatherNetworkException implements Exception {
  const WeatherNetworkException(this.message);
  final String message;
  @override
  String toString() => 'WeatherNetworkException: $message';
}
