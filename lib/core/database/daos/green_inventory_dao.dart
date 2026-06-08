import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/green_inventory_table.dart';

part 'green_inventory_dao.g.dart';

@DriftAccessor(tables: [GreenInventories])
class GreenInventoryDao extends DatabaseAccessor<AppDatabase>
    with _$GreenInventoryDaoMixin {
  GreenInventoryDao(super.db);

  Future<void> upsert(GreenInventoriesCompanion row) =>
      into(greenInventories).insertOnConflictUpdate(row);

  Future<DbGreenInventory?> getByLotId(String lotId) =>
      (select(greenInventories)
            ..where((t) => t.lotId.equals(lotId))
            ..limit(1))
          .getSingleOrNull();

  Future<List<DbGreenInventory>> getAll() =>
      (select(greenInventories)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
}
