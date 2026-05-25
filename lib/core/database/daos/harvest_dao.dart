import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/harvest_tables.dart';

part 'harvest_dao.g.dart';

@DriftAccessor(tables: [HarvestSessions, HarvestPasses])
class HarvestDao extends DatabaseAccessor<AppDatabase> with _$HarvestDaoMixin {
  HarvestDao(super.db);

  Future<DbHarvestSession?> getActiveSession(String lotId) =>
      (select(harvestSessions)
            ..where(
              (t) =>
                  t.lotId.equals(lotId) &
                  t.completedAt.isNull() &
                  t.deletedAt.isNull(),
            ))
          .getSingleOrNull();

  /// Returns the most recent session (active or completed) for the cascade
  /// fallback in the depulping reference time calculation.
  Future<DbHarvestSession?> getLatestSession(String lotId) =>
      (select(harvestSessions)
            ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<DbHarvestSession?> getSessionById(String id) =>
      (select(harvestSessions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insertSession(HarvestSessionsCompanion session) =>
      into(harvestSessions).insert(session);

  Future<void> updateSession(String id, HarvestSessionsCompanion data) =>
      (update(harvestSessions)..where((t) => t.id.equals(id))).write(data);

  Future<void> insertPass(HarvestPassesCompanion pass) =>
      into(harvestPasses).insert(pass);

  Future<List<DbHarvestPass>> getPasses(String sessionId) =>
      (select(harvestPasses)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm(expression: t.passDate)]))
          .get();

  Stream<List<DbHarvestPass>> watchPasses(String sessionId) =>
      (select(harvestPasses)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm(expression: t.passDate)]))
          .watch();
}
