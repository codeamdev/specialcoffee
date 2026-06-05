import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/water_profile_dao.dart';
import 'package:special_coffee/domain/entities/water_profile.dart';
import 'package:special_coffee/domain/repositories/water_profile_repository.dart';
import 'package:uuid/uuid.dart';

class WaterProfileLocalRepository implements WaterProfileRepository {
  WaterProfileLocalRepository(this._dao, this._ownerId);

  final WaterProfileDao _dao;
  final String          _ownerId;
  static const _uuid = Uuid();

  @override
  Future<List<WaterProfile>> getAll() async {
    final rows = await _dao.getByOwner(_ownerId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<WaterProfile>> watchAll() =>
      _dao.watchByOwner(_ownerId).map((rows) => rows.map(_fromRow).toList());

  @override
  Future<WaterProfile?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<WaterProfile> save(WaterProfile profile) async {
    final now = DateTime.now();
    final id  = profile.id.isEmpty ? _uuid.v4() : profile.id;
    await _dao.upsert(WaterProfilesCompanion(
      id:          Value(id),
      ownerId:     Value(_ownerId),
      name:        Value(profile.name),
      hardnessPpm: Value(profile.hardnessPpm),
      phLevel:     Value(profile.phLevel),
      tdsPpm:      Value(profile.tdsPpm),
      notes:       Value(profile.notes),
      createdAt:   Value(profile.createdAt),
      updatedAt:   Value(now),
    ));
    return WaterProfile(
      id:          id,
      ownerId:     _ownerId,
      name:        profile.name,
      hardnessPpm: profile.hardnessPpm,
      phLevel:     profile.phLevel,
      tdsPpm:      profile.tdsPpm,
      notes:       profile.notes,
      createdAt:   profile.createdAt,
      updatedAt:   now,
    );
  }

  WaterProfile _fromRow(DbWaterProfile r) => WaterProfile(
        id:          r.id,
        ownerId:     r.ownerId,
        name:        r.name,
        hardnessPpm: r.hardnessPpm,
        phLevel:     r.phLevel,
        tdsPpm:      r.tdsPpm,
        notes:       r.notes,
        createdAt:   r.createdAt,
        updatedAt:   r.updatedAt,
      );
}
