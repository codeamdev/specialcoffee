import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/coffee_reference_dao.dart';
import 'package:special_coffee/domain/entities/coffee_reference.dart';
import 'package:special_coffee/domain/repositories/coffee_reference_repository.dart';
import 'package:uuid/uuid.dart';

class CoffeeReferenceLocalRepository implements CoffeeReferenceRepository {
  CoffeeReferenceLocalRepository(this._dao, this._ownerId);

  final CoffeeReferenceDao _dao;
  final String             _ownerId;
  static const _uuid = Uuid();

  @override
  Future<List<CoffeeReference>> getAll() async {
    final rows = await _dao.getByOwner(_ownerId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<CoffeeReference>> watchAll() =>
      _dao.watchByOwner(_ownerId).map((rows) => rows.map(_fromRow).toList());

  @override
  Future<CoffeeReference?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<CoffeeReference> save(CoffeeReference reference) async {
    final now = DateTime.now();
    final id  = reference.id.isEmpty ? _uuid.v4() : reference.id;
    await _dao.upsert(CoffeeReferencesCompanion(
      id:           Value(id),
      ownerId:      Value(_ownerId),
      name:         Value(reference.name),
      origin:       Value(reference.origin),
      farmer:       Value(reference.farmer),
      processType:  Value(reference.processType),
      roastLevel:   Value(reference.roastLevel),
      roastDate:    Value(reference.roastDate),
      packagedDate: Value(reference.packagedDate),
      grindNotes:   Value(reference.grindNotes),
      tasteNotes:   Value(reference.tasteNotes),
      status:       Value(reference.status),
      createdAt:    Value(reference.createdAt),
      updatedAt:    Value(now),
    ));
    return CoffeeReference(
      id:           id,
      ownerId:      _ownerId,
      name:         reference.name,
      origin:       reference.origin,
      farmer:       reference.farmer,
      processType:  reference.processType,
      roastLevel:   reference.roastLevel,
      roastDate:    reference.roastDate,
      packagedDate: reference.packagedDate,
      grindNotes:   reference.grindNotes,
      tasteNotes:   reference.tasteNotes,
      status:       reference.status,
      createdAt:    reference.createdAt,
      updatedAt:    now,
    );
  }

  @override
  Future<void> updateStatus(String id, String status) =>
      _dao.updateStatus(id, status);

  CoffeeReference _fromRow(DbCoffeeReference r) => CoffeeReference(
        id:           r.id,
        ownerId:      r.ownerId,
        name:         r.name,
        origin:       r.origin,
        farmer:       r.farmer,
        processType:  r.processType,
        roastLevel:   r.roastLevel,
        roastDate:    r.roastDate,
        packagedDate: r.packagedDate,
        grindNotes:   r.grindNotes,
        tasteNotes:   r.tasteNotes,
        status:       r.status,
        createdAt:    r.createdAt,
        updatedAt:    r.updatedAt,
      );
}
