import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/network/api_client.dart';
import 'package:special_coffee/data/repositories/auth_repository_impl.dart';
import 'package:special_coffee/domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// ── Infraestructura ────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient();

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    HttpAuthRepository(ref.read(apiClientProvider));

// ── Estado de sesión ───────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthUser?> build() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      return await repo.currentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      return result.user;
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    String role    = 'farmer',
    String region  = '',
    String country = 'CO',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).register(
            email:       email,
            password:    password,
            displayName: displayName,
            role:        role,
            region:      region,
            country:     country,
          );
      return result.user;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

// ── Accesores rápidos ──────────────────────────────────────────────────────

@riverpod
AuthUser? currentUser(Ref ref) =>
    ref.watch(authProvider).value;

@riverpod
String currentUserId(Ref ref) =>
    ref.watch(currentUserProvider)?.userId ?? '';
