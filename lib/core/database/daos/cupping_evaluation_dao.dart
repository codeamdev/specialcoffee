import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/cupping_evaluations_table.dart';

part 'cupping_evaluation_dao.g.dart';

@DriftAccessor(tables: [CuppingEvaluations])
class CuppingEvaluationDao extends DatabaseAccessor<AppDatabase>
    with _$CuppingEvaluationDaoMixin {
  CuppingEvaluationDao(super.db);

  Future<void> upsert(CuppingEvaluationsCompanion row) =>
      into(cuppingEvaluations).insertOnConflictUpdate(row);

  Future<List<DbCuppingEvaluation>> getByLotId(String lotId) =>
      (select(cuppingEvaluations)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.cuppedAt)]))
          .get();

  Future<DbCuppingEvaluation?> getLatestByLotId(String lotId) =>
      (select(cuppingEvaluations)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.cuppedAt)])
            ..limit(1))
          .getSingleOrNull();
}
