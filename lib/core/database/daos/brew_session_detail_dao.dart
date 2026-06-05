import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/brew_session_details_table.dart';

part 'brew_session_detail_dao.g.dart';

@DriftAccessor(tables: [BrewSessionDetails])
class BrewSessionDetailDao extends DatabaseAccessor<AppDatabase>
    with _$BrewSessionDetailDaoMixin {
  BrewSessionDetailDao(super.db);

  Future<DbBrewSessionDetail?> getByBrewingSession(String brewingSessionId) =>
      (select(brewSessionDetails)
            ..where((t) => t.brewingSessionId.equals(brewingSessionId))
            ..limit(1))
          .getSingleOrNull();

  Future<List<DbBrewSessionDetail>> getAllByBrewingSession(
          String brewingSessionId) =>
      (select(brewSessionDetails)
            ..where((t) => t.brewingSessionId.equals(brewingSessionId)))
          .get();

  Future<void> upsert(BrewSessionDetailsCompanion entry) =>
      into(brewSessionDetails).insertOnConflictUpdate(entry);
}
