import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/washing_tables.dart';

part 'washing_dao.g.dart';

@DriftAccessor(tables: [WashingSessions])
class WashingDao extends DatabaseAccessor<AppDatabase>
    with _$WashingDaoMixin {
  WashingDao(super.db);

  Future<DbWashingSession?> getByLotId(String lotId) =>
      (select(washingSessions)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsert(WashingSessionsCompanion session) =>
      into(washingSessions).insertOnConflictUpdate(session);

  Future<List<DbWashingSession>> getUnsyncedSessions() =>
      (select(washingSessions)..where((t) => t.syncedAt.isNull())).get();

  Future<void> markWashingSessionSynced(String id) =>
      (update(washingSessions)..where((t) => t.id.equals(id)))
          .write(WashingSessionsCompanion(
              syncedAt: Value(DateTime.now().toUtc())));
}
