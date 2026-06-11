import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:special_coffee/core/config/api_config.dart';

/// Cliente HTTP base. Inyecta el JWT en cada request a PostgREST y al auth
/// service. Renueva el access token automáticamente cuando expira.
class ApiClient {
  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  late final Dio _dio;

  // In-memory cache: flutter_secure_storage on web (Web Crypto API) can fail
  // to decrypt data stored in the same session when the key lifecycle is
  // inconsistent.  Caching in memory guarantees the token is always available
  // within the same Riverpod provider lifetime without repeated storage reads.
  String? _accessToken;
  String? _refreshToken;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  /// Constructs an ApiClient with a pre-loaded token — no platform channels needed.
  /// The in-memory token is returned by [getAccessToken] without touching storage.
  @visibleForTesting
  ApiClient.withToken(String token)
      : _storage = const FlutterSecureStorage() {
    _accessToken = token;
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  // ── Token storage ────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    if (_accessToken != null) return _accessToken;
    try {
      final t = await _storage.read(key: _accessKey);
      _accessToken = t;
      return t;
    } catch (_) {
      await _storage.deleteAll();
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_refreshToken != null) return _refreshToken;
    try {
      final t = await _storage.read(key: _refreshKey);
      _refreshToken = t;
      return t;
    } catch (_) {
      await _storage.deleteAll();
      return null;
    }
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }

  // ── Interceptors ─────────────────────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) return handler.next(err);

    // No intentar renovar si el request que falló ES el de refresh (evita bucle)
    if (err.requestOptions.path.contains('/auth/refresh') ||
        err.requestOptions.path.contains('/auth/login') ||
        err.requestOptions.path.contains('/auth/register')) {
      return handler.next(err);
    }

    // Intentar renovar el token una vez
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return handler.next(err);

    try {
      final response = await Dio().post(
        ApiConfig.refresh,
        data: {'refresh_token': refreshToken},
      );
      final newAccess  = response.data['access_token']  as String;
      final newRefresh = response.data['refresh_token'] as String;
      await saveTokens(accessToken: newAccess, refreshToken: newRefresh);

      // Reintentar la request original con el nuevo token
      final retryOptions = err.requestOptions.copyWith(
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer $newAccess',
        },
      );
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await clearTokens();
      handler.next(err);
    }
  }

  // ── HTTP helpers ─────────────────────────────────────────────────────────

  Future<Response<T>> get<T>(String url, {Map<String, dynamic>? params}) =>
      _dio.get<T>(url, queryParameters: params);

  Future<Response<T>> post<T>(String url, {Object? data, Map<String, dynamic>? headers}) =>
      _dio.post<T>(url, data: data,
          options: headers != null ? Options(headers: headers) : null);

  Future<Response<T>> patch<T>(String url, {Object? data}) =>
      _dio.patch<T>(url, data: data);

  Future<Response<T>> delete<T>(String url, {Map<String, dynamic>? params}) =>
      _dio.delete<T>(url, queryParameters: params);

  /// Convierte DioException en un mensaje legible.
  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'];
      if (data is Map && data['detail']  != null) return data['detail'];
      return e.message ?? 'Error de red';
    }
    return e.toString();
  }
}
