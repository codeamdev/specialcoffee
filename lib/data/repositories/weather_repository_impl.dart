import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:special_coffee/core/constants/app_constants.dart';
import 'package:special_coffee/data/datasources/weather_remote_data_source.dart';
import 'package:special_coffee/domain/entities/weather_data.dart';
import 'package:special_coffee/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl({
    required WeatherRemoteDataSource remote,
    required Box<dynamic> box,
  })  : _remote = remote,
        _box = box;

  static const _key = 'weather_latest';

  final WeatherRemoteDataSource _remote;
  final Box<dynamic> _box;

  @override
  Future<WeatherData?> getCached() async {
    final raw = _box.get(_key);
    if (raw == null) return null;
    return WeatherData.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<WeatherData> getWeather({
    required double lat,
    required double lng,
  }) async {
    final cached = await getCached();
    if (cached != null && cached.isFresh) return cached;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw const WeatherNetworkException('Sin conexión a internet');
    }

    final data = await _remote.fetch(lat: lat, lng: lng);
    await _box.put(_key, data.toMap());
    return data;
  }

  @override
  Future<void> saveManual(WeatherData data) =>
      _box.put(_key, data.toMap());

  static Future<WeatherRepositoryImpl> open() async {
    final box = await Hive.openBox<dynamic>(AppConstants.hiveBoxCache);
    return WeatherRepositoryImpl(
      remote: WeatherRemoteDataSource(),
      box: box,
    );
  }
}
