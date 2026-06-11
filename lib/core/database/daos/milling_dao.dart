import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/milling_tables.dart';

part 'milling_dao.g.dart';

@DriftAccessor(tables: [MillingSessions])
class MillingDao extends DatabaseAccessor<AppDatabase>
    with _$MillingDaoMixin {
  MillingDao(super.db);

  Future<DbMillingSession?> getByLotId(String lotId) =>
      (select(millingSessions)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsert(MillingSessionsCompanion session) =>
      into(millingSessions).insertOnConflictUpdate(session);

  Future<List<DbMillingSession>> getUnsyncedSessions() =>
      (select(millingSessions)..where((t) => t.syncedAt.isNull())).get();

  Future<void> markMillingSessionSynced(String id) =>
      (update(millingSessions)..where((t) => t.id.equals(id)))
          .write(MillingSessionsCompanion(
              syncedAt: Value(DateTime.now().toUtc())));
}
