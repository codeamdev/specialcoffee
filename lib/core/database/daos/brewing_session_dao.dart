import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/brewing_sessions_table.dart';
import 'package:special_coffee/domain/entities/brewing_session.dart';

part 'brewing_session_dao.g.dart';

@DriftAccessor(tables: [BrewingSessions])
class BrewingSessionDao extends DatabaseAccessor<AppDatabase>
    with _$BrewingSessionDaoMixin {
  BrewingSessionDao(super.db);

  Future<void> upsert(BrewingSessionsCompanion session) =>
      into(brewingSessions).insertOnConflictUpdate(session);

  Future<List<BrewingSession>> getRecent({int limit = 20}) async {
    final rows = await (select(brewingSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.brewedAt)])
          ..limit(limit))
        .get();
    return rows.map(_toEntity).toList();
  }

  Future<List<BrewingSession>> getByOwner(String ownerId) async {
    final rows = await (select(brewingSessions)
          ..where((t) => t.ownerId.equals(ownerId))
          ..orderBy([(t) => OrderingTerm.desc(t.brewedAt)]))
        .get();
    return rows.map(_toEntity).toList();
  }

  static BrewingSession _toEntity(DbBrewingSession r) => BrewingSession(
        id:            r.id,
        ownerId:       r.ownerId,
        method:        r.method,
        doseG:         r.doseG,
        waterG:        r.waterG,
        waterTempC:    r.waterTempC,
        actualTimeSec: r.actualTimeSec,
        tdsPct:        r.tdsPct,
        yieldG:        r.yieldG,
        notes:         r.notes,
        brewedAt:      r.brewedAt,
        createdAt:     r.createdAt,
      );
}
