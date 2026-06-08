import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/roast_profiles_table.dart';

part 'roast_profile_dao.g.dart';

@DriftAccessor(tables: [RoastProfiles])
class RoastProfileDao extends DatabaseAccessor<AppDatabase>
    with _$RoastProfileDaoMixin {
  RoastProfileDao(super.db);

  Future<void> upsert(RoastProfilesCompanion row) =>
      into(roastProfiles).insertOnConflictUpdate(row);

  Future<List<DbRoastProfile>> getByLotId(String lotId) =>
      (select(roastProfiles)
            ..where((t) => t.lotId.equals(lotId))
            ..orderBy([(t) => OrderingTerm.desc(t.roastedAt)]))
          .get();

  Future<DbRoastProfile?> getById(String id) =>
      (select(roastProfiles)..where((t) => t.id.equals(id))).getSingleOrNull();
}
