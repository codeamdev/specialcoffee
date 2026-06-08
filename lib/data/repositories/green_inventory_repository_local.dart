import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/green_inventory_dao.dart';
import 'package:special_coffee/domain/entities/green_inventory.dart';
import 'package:special_coffee/domain/repositories/green_inventory_repository.dart';
import 'package:uuid/uuid.dart';

class GreenInventoryLocalRepository implements GreenInventoryRepository {
  GreenInventoryLocalRepository(this._dao);

  final GreenInventoryDao _dao;
  static const _uuid = Uuid();

  @override
  Future<GreenInventory?> getByLotId(String lotId) async {
    final row = await _dao.getByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<List<GreenInventory>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<GreenInventory> save(GreenInventory inventory) async {
    final id = inventory.id.isEmpty ? _uuid.v4() : inventory.id;
    final now = DateTime.now();
    await _dao.upsert(GreenInventoriesCompanion(
      id:                Value(id),
      lotId:             Value(inventory.lotId),
      weightKg:          Value(inventory.weightKg),
      sackType:          Value(inventory.sackType),
      sackCount:         Value(inventory.sackCount),
      warehouseLocation: Value(inventory.warehouseLocation),
      updatedAt:         Value(now),
    ));
    return GreenInventory(
      id:                id,
      lotId:             inventory.lotId,
      weightKg:          inventory.weightKg,
      sackType:          inventory.sackType,
      sackCount:         inventory.sackCount,
      warehouseLocation: inventory.warehouseLocation,
      updatedAt:         now,
    );
  }

  GreenInventory _fromRow(DbGreenInventory r) => GreenInventory(
        id:                r.id,
        lotId:             r.lotId,
        weightKg:          r.weightKg,
        sackType:          r.sackType,
        sackCount:         r.sackCount,
        warehouseLocation: r.warehouseLocation,
        updatedAt:         r.updatedAt,
      );
}
