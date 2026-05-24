abstract class AuthRepository {
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String role    = 'farmer',
    String region  = '',
    String country = 'CO',
    String language = 'es',
  });

  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> refresh();

  Future<AuthUser?> currentUser();

  Future<void> logout();

  bool get isLoggedIn;
}

class AuthResult {
  final AuthUser user;
  final String   accessToken;
  final String   refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthUser {
  final String userId;
  final String email;
  final String displayName;
  final String role;
  final String region;
  final String country;
  final String language;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    this.region   = '',
    this.country  = 'CO',
    this.language = 'es',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        userId:      json['user_id'] as String,
        email:       json['email']        as String,
        displayName: json['display_name'] as String,
        role:        json['role']         as String,
        region:      (json['region']   ?? '') as String,
        country:     (json['country']  ?? 'CO') as String,
        language:    (json['language'] ?? 'es') as String,
      );
}
