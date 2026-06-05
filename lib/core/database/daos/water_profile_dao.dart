import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/water_profiles_table.dart';

part 'water_profile_dao.g.dart';

@DriftAccessor(tables: [WaterProfiles])
class WaterProfileDao extends DatabaseAccessor<AppDatabase>
    with _$WaterProfileDaoMixin {
  WaterProfileDao(super.db);

  Future<List<DbWaterProfile>> getByOwner(String ownerId) =>
      (select(waterProfiles)
            ..where((t) => t.ownerId.equals(ownerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<DbWaterProfile>> watchByOwner(String ownerId) =>
      (select(waterProfiles)
            ..where((t) => t.ownerId.equals(ownerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<DbWaterProfile?> getById(String id) =>
      (select(waterProfiles)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsert(WaterProfilesCompanion entry) =>
      into(waterProfiles).insertOnConflictUpdate(entry);
}
