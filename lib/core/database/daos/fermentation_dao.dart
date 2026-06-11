import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/fermentation_tables.dart';

part 'fermentation_dao.g.dart';

@DriftAccessor(tables: [FermentationSessions, FermentationReadings])
class FermentationDao extends DatabaseAccessor<AppDatabase>
    with _$FermentationDaoMixin {
  FermentationDao(super.db);

  Future<DbFermentationSession?> getLatestSession(String lotId) =>
      (select(fermentationSessions)
            ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<DbFermentationSession?> getActiveSession(String lotId) =>
      (select(fermentationSessions)
            ..where(
              (t) =>
                  t.lotId.equals(lotId) &
                  t.endedAt.isNull() &
                  t.deletedAt.isNull(),
            ))
          .getSingleOrNull();

  Future<DbFermentationSession?> getSessionById(String id) =>
      (select(fermentationSessions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insertSession(FermentationSessionsCompanion session) =>
      into(fermentationSessions).insert(session);

  Future<void> updateSession(
    String id,
    FermentationSessionsCompanion data,
  ) =>
      (update(fermentationSessions)..where((t) => t.id.equals(id))).write(data);

  Future<void> insertReading(FermentationReadingsCompanion reading) =>
      into(fermentationReadings).insert(reading);

  Future<List<DbFermentationReading>> getReadings(String sessionId) =>
      (select(fermentationReadings)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm(expression: t.recordedAt)]))
          .get();

  Stream<List<DbFermentationReading>> watchReadings(String sessionId) =>
      (select(fermentationReadings)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm(expression: t.recordedAt)]))
          .watch();

  Future<double> getAvgCompletedDurationH(String ownerId) async {
    final result = await customSelect(
      'SELECT AVG(actual_duration_h) AS avg_h FROM fermentation_sessions '
      'WHERE owner_id = ? AND actual_duration_h IS NOT NULL',
      variables: [Variable.withString(ownerId)],
      readsFrom: {fermentationSessions},
    ).getSingleOrNull();
    return (result?.data['avg_h'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getLastCompletedDurationH(String ownerId) async {
    final row = await (select(fermentationSessions)
          ..where((t) =>
              t.ownerId.equals(ownerId) & t.actualDurationH.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.actualDurationH ?? 0.0;
  }

  Future<List<DbFermentationReading>> getUnsyncedReadings() =>
      (select(fermentationReadings)
            ..where((t) => t.syncedAt.isNull()))
          .get();

  Future<void> markFermentationReadingSynced(String id) =>
      (update(fermentationReadings)..where((t) => t.id.equals(id)))
          .write(FermentationReadingsCompanion(
              syncedAt: Value(DateTime.now().toUtc())));

  Future<List<DbFermentationSession>> getUnsyncedSessions() =>
      (select(fermentationSessions)
            ..where((t) => t.syncedAt.isNull() & t.deletedAt.isNull()))
          .get();

  Future<void> markFermentationSessionSynced(String id) =>
      (update(fermentationSessions)..where((t) => t.id.equals(id)))
          .write(FermentationSessionsCompanion(
              syncedAt: Value(DateTime.now().toUtc())));
}
