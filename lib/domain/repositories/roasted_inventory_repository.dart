import 'package:special_coffee/domain/entities/roasted_inventory.dart';

abstract interface class RoastedInventoryRepository {
  Future<RoastedInventory?> getByRoastProfileId(String roastProfileId);
  Future<List<RoastedInventory>> getAll();
  Future<RoastedInventory> save(RoastedInventory inventory);
}
