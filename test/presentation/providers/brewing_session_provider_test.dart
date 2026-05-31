import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/brewing_session.dart';
import 'package:special_coffee/domain/repositories/brewing_session_repository.dart';
import 'package:special_coffee/presentation/providers/brewing_session_provider.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeRepo implements BrewingSessionRepository {
  final List<BrewingSession> _saved = [];

  @override
  Future<BrewingSession> save(BrewingSession session) async {
    final saved = BrewingSession(
      id:            session.id.isEmpty ? 'fake-brew-id' : session.id,
      ownerId:       session.ownerId,
      method:        session.method,
      doseG:         session.doseG,
      waterG:        session.waterG,
      waterTempC:    session.waterTempC,
      actualTimeSec: session.actualTimeSec,
      tdsPct:        session.tdsPct,
      yieldG:        session.yieldG,
      notes:         session.notes,
      brewedAt:      session.brewedAt,
      createdAt:     session.createdAt,
    );
    _saved.add(saved);
    return saved;
  }

  @override
  Future<List<BrewingSession>> getRecent({int limit = 20}) async =>
      _saved.reversed.take(limit).toList();
}

class _ThrowingRepo implements BrewingSessionRepository {
  @override
  Future<BrewingSession> save(BrewingSession session) async =>
      throw Exception('disco lleno');

  @override
  Future<List<BrewingSession>> getRecent({int limit = 20}) async => const [];
}

// ── Container factory ─────────────────────────────────────────────────────────

ProviderContainer _container({BrewingSessionRepository? repo}) =>
    ProviderContainer(
      overrides: [
        brewingSessionLocalRepoProvider.overrideWith(
            (ref) => repo ?? _FakeRepo()),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Estado inicial ────────────────────────────────────────────────────────

  group('BrewingSessionNotifier — estado inicial', () {
    test('isLoading false, isSaved false, error null', () {
      final container = _container();
      addTearDown(container.dispose);

      final state = container.read(brewingSessionProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSaved,   isFalse);
      expect(state.error,     isNull);
    });
  });

  // ── save — happy path ─────────────────────────────────────────────────────

  group('BrewingSessionNotifier.save — happy path', () {
    test('isSaved becomes true, no error', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(brewingSessionProvider.notifier).save(
            method: 'v60', doseG: 15.0, waterG: 250.0, waterTempC: 93.0,
            brewedAt: DateTime.now(),
          );

      final state = container.read(brewingSessionProvider);
      expect(state.isSaved,   isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error,     isNull);
    });

    test('save with all optional fields', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(brewingSessionProvider.notifier).save(
            method:        'chemex',
            doseG:         20.0,
            waterG:        300.0,
            waterTempC:    94.0,
            actualTimeSec: 240,
            tdsPct:        1.35,
            yieldG:        36.0,
            notes:         'Floral, ácido brillante',
            brewedAt:      DateTime(2026, 5, 27, 9, 0),
          );

      expect(container.read(brewingSessionProvider).isSaved, isTrue);
    });

    test('isLoading returns to false after save', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(brewingSessionProvider.notifier).save(
            method: 'aeropress', doseG: 18.0, waterG: 200.0,
            waterTempC: 85.0, brewedAt: DateTime.now(),
          );

      expect(container.read(brewingSessionProvider).isLoading, isFalse);
    });
  });

  // ── save — error de persistencia ─────────────────────────────────────────

  group('BrewingSessionNotifier.save — error de persistencia', () {
    test('repo.save lanza → error no es null, isSaved false', () async {
      final container = _container(repo: _ThrowingRepo());
      addTearDown(container.dispose);

      await container.read(brewingSessionProvider.notifier).save(
            method: 'espresso', doseG: 18.0, waterG: 36.0,
            waterTempC: 93.0, brewedAt: DateTime.now(),
          );

      final state = container.read(brewingSessionProvider);
      expect(state.error,     isNotNull);
      expect(state.isSaved,   isFalse);
      expect(state.isLoading, isFalse);
    });
  });
}
