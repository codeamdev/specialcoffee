import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/drying_tables.dart';

part 'drying_dao.g.dart';

@DriftAccessor(tables: [DryingSessions, DryingReadings])
class DryingDao extends DatabaseAccessor<AppDatabase> with _$DryingDaoMixin {
  DryingDao(super.db);

  Future<DbDryingSession?> getLatestSession(String lotId) =>
      (select(dryingSessions)
            ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<DbDryingSession?> getActiveSession(String lotId) =>
      (select(dryingSessions)
            ..where(
              (t) =>
                  t.lotId.equals(lotId) &
                  t.endedAt.isNull() &
                  t.deletedAt.isNull(),
            ))
          .getSingleOrNull();

  Future<DbDryingSession?> getSessionById(String id) =>
      (select(dryingSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertSession(DryingSessionsCompanion session) =>
      into(dryingSessions).insert(session);

  Future<void> updateSession(String id, DryingSessionsCompanion data) =>
      (update(dryingSessions)..where((t) => t.id.equals(id))).write(data);

  Future<void> insertReading(DryingReadingsCompanion reading) =>
      into(dryingReadings).insert(reading);

  Future<List<DbDryingReading>> getReadings(String sessionId) =>
      (select(dryingReadings)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm(expression: t.recordedAt)]))
          .get();

  Stream<List<DbDryingReading>> watchReadings(String sessionId) =>
      (select(dryingReadings)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm(expression: t.recordedAt)]))
          .watch();

  Future<List<DbDryingReading>> getUnsyncedReadings() =>
      (select(dryingReadings)..where((t) => t.syncedAt.isNull())).get();

  Future<void> markDryingReadingSynced(String id) =>
      (update(dryingReadings)..where((t) => t.id.equals(id)))
          .write(DryingReadingsCompanion(
              syncedAt: Value(DateTime.now().toUtc())));

  Future<List<DbDryingSession>> getUnsyncedSessions() =>
      (select(dryingSessions)
            ..where((t) => t.syncedAt.isNull() & t.deletedAt.isNull()))
          .get();

  Future<void> markDryingSessionSynced(String id) =>
      (update(dryingSessions)..where((t) => t.id.equals(id)))
          .write(DryingSessionsCompanion(
              syncedAt: Value(DateTime.now().toUtc())));
}
