import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/batch_insights_table.dart';

part 'batch_insights_dao.g.dart';

@DriftAccessor(tables: [BatchInsights])
class BatchInsightsDao extends DatabaseAccessor<AppDatabase>
    with _$BatchInsightsDaoMixin {
  BatchInsightsDao(super.db);

  Future<void> insert(BatchInsightsCompanion insight) =>
      into(batchInsights).insertOnConflictUpdate(insight);

  Future<List<DbLotInsight>> getByOwner(String ownerId) =>
      (select(batchInsights)
            ..where((t) => t.ownerId.equals(ownerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<DbLotInsight?> getByLotId(String lotId) =>
      (select(batchInsights)
            ..where((t) => t.lotId.equals(lotId))
            ..limit(1))
          .getSingleOrNull();
}
