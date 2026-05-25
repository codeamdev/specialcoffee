import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/cupping_tables.dart';

part 'cupping_dao.g.dart';

@DriftAccessor(tables: [CuppingSessions])
class CuppingDao extends DatabaseAccessor<AppDatabase> with _$CuppingDaoMixin {
  CuppingDao(super.db);

  Future<DbCuppingSession?> getByLotId(String lotId) =>
      (select(cuppingSessions)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<DbCuppingSession>> getAllByOwner(String ownerId) =>
      (select(cuppingSessions)
            ..where((t) => t.ownerId.equals(ownerId))
            ..orderBy([(t) => OrderingTerm.desc(t.cuppedAt)]))
          .get();

  Future<void> upsert(CuppingSessionsCompanion session) =>
      into(cuppingSessions).insertOnConflictUpdate(session);
}
