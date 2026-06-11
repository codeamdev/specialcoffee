import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/classification_tables.dart';

part 'classification_dao.g.dart';

@DriftAccessor(tables: [ClassificationSessions])
class ClassificationDao extends DatabaseAccessor<AppDatabase>
    with _$ClassificationDaoMixin {
  ClassificationDao(super.db);

  Future<DbClassificationSession?> getByLotId(String lotId) =>
      (select(classificationSessions)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsert(ClassificationSessionsCompanion session) =>
      into(classificationSessions).insertOnConflictUpdate(session);

  Future<List<DbClassificationSession>> getUnsyncedSessions() =>
      (select(classificationSessions)
            ..where((t) => t.syncedAt.isNull()))
          .get();

  Future<void> markClassificationSessionSynced(String id) =>
      (update(classificationSessions)..where((t) => t.id.equals(id)))
          .write(ClassificationSessionsCompanion(
              syncedAt: Value(DateTime.now().toUtc())));
}
