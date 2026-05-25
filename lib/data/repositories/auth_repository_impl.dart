import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:special_coffee/core/config/api_config.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/domain/repositories/auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  final ApiClient _client;

  HttpAuthRepository(this._client);

  // ── Dev bypass ─────────────────────────────────────────────────────────────

  static AuthResult _devUser(String email) => AuthResult(
        accessToken: 'dev_token',
        refreshToken: 'dev_refresh',
        user: AuthUser(
          userId: 'dev-user-001',
          email: email,
          displayName: 'Dev User',
          role: 'farmer',
          region: 'Huila',
          country: 'CO',
          language: 'es',
        ),
      );

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String role     = 'farmer',
    String region   = '',
    String country  = 'CO',
    String language = 'es',
  }) async {
    if (ApiConfig.devBypass) return _devUser(email);

    final response = await _client.post(ApiConfig.register, data: {
      'email':        email,
      'password':     password,
      'display_name': displayName,
      'role':         role,
      'region':       region,
      'country':      country,
      'language':     language,
    });

    return _parseTokenResponse(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (ApiConfig.devBypass) return _devUser(email);

    final response = await _client.post(ApiConfig.login, data: {
      'email':    email,
      'password': password,
    });

    return _parseTokenResponse(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthResult> refresh() async {
    final refreshToken = await _client.getRefreshToken();
    if (refreshToken == null) throw Exception('No hay refresh token guardado');

    final response = await _client.post(ApiConfig.refresh, data: {
      'refresh_token': refreshToken,
    });

    return _parseTokenResponse(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthUser?> currentUser() async {
    if (ApiConfig.devBypass) {
      // En modo dev siempre hay un usuario activo (simula sesión persistida)
      return _devUser('dev@specialcoffee.app').user;
    }

    final token = await _client.getAccessToken();
    if (token == null) return null;

    try {
      if (JwtDecoder.isExpired(token)) {
        final result = await refresh();
        return result.user;
      }

      // Decodifica el usuario desde las claims del JWT sin llamada de red.
      // El token fue firmado por el servidor, así que los datos son confiables.
      final claims = JwtDecoder.decode(token);
      return AuthUser(
        userId:      claims['sub']          as String,
        email:       claims['email']        as String,
        displayName: (claims['display_name'] as String?) ?? '',
        role:        (claims['app_role']    as String?) ?? 'farmer',
        region:      (claims['region']      as String?) ?? '',
        country:     (claims['country']     as String?) ?? 'CO',
        language:    (claims['language']    as String?) ?? 'es',
      );
    } catch (_) {
      await _client.clearTokens();
      return null;
    }
  }

  @override
  Future<void> logout() => _client.clearTokens();

  @override
  bool get isLoggedIn {
    // Sincrónico — solo verifica si hay token en memoria
    // Para verificar expiración usa currentUser()
    return false; // el provider lo resuelve con currentUser() async
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<AuthResult> _parseTokenResponse(Map<String, dynamic> data) async {
    final accessToken  = data['access_token']  as String;
    final refreshToken = data['refresh_token'] as String;

    await _client.saveTokens(
      accessToken:  accessToken,
      refreshToken: refreshToken,
    );

    final user = AuthUser(
      userId:      data['user_id']      as String,
      email:       data['email']        as String,
      displayName: data['display_name'] as String,
      role:        data['role']         as String,
    );

    return AuthResult(
      user:         user,
      accessToken:  accessToken,
      refreshToken: refreshToken,
    );
  }
}
