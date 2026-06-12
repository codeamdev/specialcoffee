class WeatherData {
  const WeatherData({
    this.ambientTempC,
    this.ambientHumidityPct,
    this.rainProbabilityPct,
    this.uvIndex,
    required this.fetchedAt,
    this.isManual = false,
  });

  final double?   ambientTempC;
  final double?   ambientHumidityPct;
  final double?   rainProbabilityPct;
  final double?   uvIndex;
  final DateTime  fetchedAt;
  final bool      isManual;

  bool get isFresh =>
      DateTime.now().difference(fetchedAt).inHours < 2;

  bool get isStale => !isFresh;

  Map<String, dynamic> toMap() => {
        'ambientTempC':       ambientTempC,
        'ambientHumidityPct': ambientHumidityPct,
        'rainProbabilityPct': rainProbabilityPct,
        'uvIndex':            uvIndex,
        'fetchedAt':          fetchedAt.millisecondsSinceEpoch,
        'isManual':           isManual,
      };

  factory WeatherData.fromMap(Map<String, dynamic> m) => WeatherData(
        ambientTempC:       (m['ambientTempC']       as num?)?.toDouble(),
        ambientHumidityPct: (m['ambientHumidityPct'] as num?)?.toDouble(),
        rainProbabilityPct: (m['rainProbabilityPct'] as num?)?.toDouble(),
        uvIndex:            (m['uvIndex']            as num?)?.toDouble(),
        fetchedAt:          DateTime.fromMillisecondsSinceEpoch(m['fetchedAt'] as int),
        isManual:           (m['isManual'] as bool?) ?? false,
      );
}

class WeatherApiKeyNotConfiguredException implements Exception {
  const WeatherApiKeyNotConfiguredException();
  @override
  String toString() => 'WeatherApiKeyNotConfiguredException: '
      "Configura la API key de OpenWeatherMap en Ajustes → Clima.";
}
