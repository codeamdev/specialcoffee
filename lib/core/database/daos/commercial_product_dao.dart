import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/commercial_products_table.dart';

part 'commercial_product_dao.g.dart';

@DriftAccessor(tables: [CommercialProducts])
class CommercialProductDao extends DatabaseAccessor<AppDatabase>
    with _$CommercialProductDaoMixin {
  CommercialProductDao(super.db);

  Future<void> upsert(CommercialProductsCompanion row) =>
      into(commercialProducts).insertOnConflictUpdate(row);

  Future<List<DbCommercialProduct>> getByInventoryId(String roastedInventoryId) =>
      (select(commercialProducts)
            ..where((t) => t.roastedInventoryId.equals(roastedInventoryId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<DbCommercialProduct>> getAll() =>
      (select(commercialProducts)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
}
