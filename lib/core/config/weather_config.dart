/// Configuración del cliente Open-Meteo (https://open-meteo.com).
/// Gratuito, sin API key, sin rate limits para uso no comercial moderado.
abstract final class WeatherConfig {
  static const String baseUrl = 'https://api.open-meteo.com/v1';

  /// TTL de caché — debe coincidir con WeatherData.isFresh (2 horas).
  static const int cacheTtlHours = 2;
}
