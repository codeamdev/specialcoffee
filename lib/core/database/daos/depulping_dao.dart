import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/depulping_tables.dart';

part 'depulping_dao.g.dart';

@DriftAccessor(tables: [DepulpingSessions])
class DepulpingDao extends DatabaseAccessor<AppDatabase>
    with _$DepulpingDaoMixin {
  DepulpingDao(super.db);

  Future<DbDepulpingSession?> getByLotId(String lotId) =>
      (select(depulpingSessions)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsert(DepulpingSessionsCompanion session) =>
      into(depulpingSessions).insertOnConflictUpdate(session);
}
