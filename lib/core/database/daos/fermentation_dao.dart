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
}
