import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/roasted_inventory_dao.dart';
import 'package:special_coffee/domain/entities/roasted_inventory.dart';
import 'package:special_coffee/domain/repositories/roasted_inventory_repository.dart';
import 'package:uuid/uuid.dart';

class RoastedInventoryLocalRepository implements RoastedInventoryRepository {
  RoastedInventoryLocalRepository(this._dao);

  final RoastedInventoryDao _dao;
  static const _uuid = Uuid();

  @override
  Future<RoastedInventory?> getByRoastProfileId(String roastProfileId) async {
    final row = await _dao.getByRoastProfileId(roastProfileId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<List<RoastedInventory>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<RoastedInventory> save(RoastedInventory inventory) async {
    final id = inventory.id.isEmpty ? _uuid.v4() : inventory.id;
    final now = DateTime.now();
    await _dao.upsert(RoastedInventoriesCompanion(
      id:             Value(id),
      roastProfileId: Value(inventory.roastProfileId),
      weightKg:       Value(inventory.weightKg),
      updatedAt:      Value(now),
    ));
    return RoastedInventory(
      id:             id,
      roastProfileId: inventory.roastProfileId,
      weightKg:       inventory.weightKg,
      updatedAt:      now,
    );
  }

  RoastedInventory _fromRow(DbRoastedInventory r) => RoastedInventory(
        id:             r.id,
        roastProfileId: r.roastProfileId,
        weightKg:       r.weightKg,
        updatedAt:      r.updatedAt,
      );
}
