import 'package:dio/dio.dart';
import 'package:special_coffee/core/config/weather_config.dart';
import 'package:special_coffee/domain/entities/weather_data.dart';

/// Data source para Open-Meteo (https://open-meteo.com).
/// Sin API key — gratuito para uso no comercial.
class WeatherRemoteDataSource {
  WeatherRemoteDataSource()
      : _dio = Dio(BaseOptions(
          baseUrl: WeatherConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;

  Future<WeatherData> fetch({required double lat, required double lng}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'current': 'temperature_2m,relative_humidity_2m,precipitation_probability',
        'hourly': 'uv_index',
        'forecast_hours': 1,
        'timezone': 'auto',
      },
    );

    final data    = response.data!;
    final current = data['current'] as Map<String, dynamic>;

    final temp     = (current['temperature_2m'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num).toDouble();
    final rainPct  = (current['precipitation_probability'] as num? ?? 0).toDouble();

    // UV index — primer valor del array horario (hora actual)
    final uvList = (data['hourly']?['uv_index'] as List<dynamic>?) ?? [];
    final uvIndex = uvList.isNotEmpty ? (uvList.first as num).toDouble() : 0.0;

    return WeatherData(
      ambientTempC:       temp,
      ambientHumidityPct: humidity,
      rainProbabilityPct: rainPct,
      uvIndex:            uvIndex,
      fetchedAt:          DateTime.now(),
    );
  }
}
