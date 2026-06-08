import 'package:special_coffee/domain/entities/green_inventory.dart';

abstract interface class GreenInventoryRepository {
  Future<GreenInventory?> getByLotId(String lotId);
  Future<List<GreenInventory>> getAll();
  Future<GreenInventory> save(GreenInventory inventory);
}
