import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';
import 'package:special_coffee/domain/repositories/coffee_reference_repository.dart';
import 'package:special_coffee/presentation/providers/coffee_reference_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── In-memory fake ──────────────────────────────────────────────────────────

  CoffeeReference _ref({String id = '', String name = 'Test Café'}) =>
      CoffeeReference(
        id:         id,
        ownerId:    'owner-1',
        name:       name,
        roastLevel: 'medium',
        createdAt:  DateTime(2025),
        updatedAt:  DateTime(2025),
      );

  // ── Provider test ───────────────────────────────────────────────────────────

  ProviderContainer _container({CoffeeReferenceRepository? repo}) =>
      ProviderContainer(
        overrides: [
          coffeeReferenceLocalRepoProvider.overrideWith((ref) => repo ?? _FakeRepo()),
        ],
      );

  group('CoffeeReferenceNotifier', () {
    test('initial state: isLoading=false, isSaved=false, error=null', () {
      final c = _container();
      addTearDown(c.dispose);

      final state = c.read(coffeeReferenceProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSaved, isFalse);
      expect(state.error, isNull);
    });

    test('save: calls repo and sets isSaved=true', () async {
      final c = _container();
      addTearDown(c.dispose);

      await c.read(coffeeReferenceProvider.notifier).save(_ref());

      final state = c.read(coffeeReferenceProvider);
      expect(state.isSaved, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('save: persistence error sets error field', () async {
      final c = _container(repo: _FakeRepo(throwOnSave: true));
      addTearDown(c.dispose);

      await c.read(coffeeReferenceProvider.notifier).save(_ref());

      final state = c.read(coffeeReferenceProvider);
      expect(state.error, isNotNull);
      expect(state.isSaved, isFalse);
    });

    test('updateStatus: sets isSaved=true on success', () async {
      final c = _container();
      addTearDown(c.dispose);

      await c.read(coffeeReferenceProvider.notifier).updateStatus('id-1', 'depleted');

      expect(c.read(coffeeReferenceProvider).isSaved, isTrue);
    });

    test('updateStatus: persistence error sets error field', () async {
      final c = _container(repo: _FakeRepo(throwOnSave: true));
      addTearDown(c.dispose);

      await c
          .read(coffeeReferenceProvider.notifier)
          .updateStatus('id-1', 'depleted');

      expect(c.read(coffeeReferenceProvider).error, isNotNull);
    });
  });
}

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeRepo implements CoffeeReferenceRepository {
  _FakeRepo({this.throwOnSave = false});

  final bool throwOnSave;
  CoffeeReference? _stored;

  @override
  Future<List<CoffeeReference>> getAll() async =>
      _stored != null ? [_stored!] : [];

  @override
  Stream<List<CoffeeReference>> watchAll() =>
      Stream.value(_stored != null ? [_stored!] : []);

  @override
  Future<CoffeeReference?> getById(String id) async =>
      _stored?.id == id ? _stored : null;

  @override
  Future<CoffeeReference> save(CoffeeReference reference) async {
    if (throwOnSave) throw Exception('DB error');
    _stored = CoffeeReference(
      id:           reference.id.isEmpty ? 'fake-id' : reference.id,
      ownerId:      reference.ownerId,
      name:         reference.name,
      origin:       reference.origin,
      roastLevel:   reference.roastLevel,
      roastDate:    reference.roastDate,
      packagedDate: reference.packagedDate,
      grindNotes:   reference.grindNotes,
      tasteNotes:   reference.tasteNotes,
      status:       reference.status,
      createdAt:    reference.createdAt,
      updatedAt:    reference.updatedAt,
    );
    return _stored!;
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    if (throwOnSave) throw Exception('DB error');
  }
}
