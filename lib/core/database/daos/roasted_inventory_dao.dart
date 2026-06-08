import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/roasted_inventory_table.dart';

part 'roasted_inventory_dao.g.dart';

@DriftAccessor(tables: [RoastedInventories])
class RoastedInventoryDao extends DatabaseAccessor<AppDatabase>
    with _$RoastedInventoryDaoMixin {
  RoastedInventoryDao(super.db);

  Future<void> upsert(RoastedInventoriesCompanion row) =>
      into(roastedInventories).insertOnConflictUpdate(row);

  Future<DbRoastedInventory?> getByRoastProfileId(String roastProfileId) =>
      (select(roastedInventories)
            ..where((t) => t.roastProfileId.equals(roastProfileId))
            ..limit(1))
          .getSingleOrNull();

  Future<List<DbRoastedInventory>> getAll() =>
      (select(roastedInventories)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
}
