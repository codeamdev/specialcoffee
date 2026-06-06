import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:special_coffee/core/config/api_config.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/core/notifications/fcm_service.dart';
import 'package:special_coffee/domain/repositories/auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  final ApiClient _client;

  HttpAuthRepository(this._client);

  // ── Dev bypass ─────────────────────────────────────────────────────────────

  static const _devRoles = {
    'producer', 'coffee_master', 'brand_manager', 'producer_integral', 'barista', 'admin',
    // legacy tokens backward compat
    'farmer', 'processor', 'entrepreneur',
  };

  static AuthResult _devUser(String email) {
    // En devBypass el rol se infiere del prefijo del email:
    //   farmer@...  → farmer  |  barista@... → barista  |  etc.
    // Cualquier otro email usa 'farmer' por defecto.
    final prefix = email.split('@').first.toLowerCase();
    final role   = _devRoles.contains(prefix) ? prefix : 'producer';
    return AuthResult(
      accessToken:  'dev_token',
      refreshToken: 'dev_refresh',
      user: AuthUser(
        userId:      'dev-$role-001',
        email:       email,
        displayName: 'Dev ${role[0].toUpperCase()}${role.substring(1)}',
        role:        role,
        region:      'Huila',
        country:     'CO',
        language:    'es',
      ),
    );
  }

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
    if (ApiConfig.devBypass) {
      await _client.saveTokens(accessToken: email, refreshToken: 'dev_refresh');
      return _devUser(email);
    }

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
    if (ApiConfig.devBypass) {
      await _client.saveTokens(accessToken: email, refreshToken: 'dev_refresh');
      return _devUser(email);
    }

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
      // El email se guardó como access token en login/register (ver devBypass).
      // Si no hay token guardado (primer arranque sin login), retorna null.
      final stored = await _client.getAccessToken();
      if (stored == null || stored.isEmpty) return null;
      return _devUser(stored).user;
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
        role:        (claims['app_role']    as String?) ?? 'producer',
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
  Future<void> registerDevice(String playerId) async {
    if (ApiConfig.devBypass) return;
    try {
      await _client.patch(
        ApiConfig.registerDevice,
        data: {'player_id': playerId},
      );
    } catch (_) {
      // Fire-and-forget — si falla no interrumpimos la sesión del usuario
    }
  }

  @override
  Future<void> registerFcmToken(String token) async {
    if (ApiConfig.devBypass || token.isEmpty) return;
    try {
      await _client.post(ApiConfig.fcmToken, data: {'token': token});
    } catch (_) {
      // Fire-and-forget — si falla no interrumpimos la sesión del usuario
    }
  }

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

    // Sincronizar FCM token con el backend — fire-and-forget, non-blocking.
    // setTokenSyncCallback también dispara el envío inmediato si el token ya
    // está disponible, y lo reenvía en cada rotación de token.
    FcmService.instance.setTokenSyncCallback(registerFcmToken);

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
