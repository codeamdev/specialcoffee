import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/physical_analyses_table.dart';

part 'physical_analysis_dao.g.dart';

@DriftAccessor(tables: [PhysicalAnalyses])
class PhysicalAnalysisDao extends DatabaseAccessor<AppDatabase>
    with _$PhysicalAnalysisDaoMixin {
  PhysicalAnalysisDao(super.db);

  Future<void> upsert(PhysicalAnalysesCompanion row) =>
      into(physicalAnalyses).insertOnConflictUpdate(row);

  Future<List<DbPhysicalAnalysis>> getByLotId(String lotId) =>
      (select(physicalAnalyses)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.analyzedAt)]))
          .get();

  Future<DbPhysicalAnalysis?> getLatestByLotId(String lotId) =>
      (select(physicalAnalyses)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.analyzedAt)])
            ..limit(1))
          .getSingleOrNull();
}
