import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/local_lots_table.dart';

part 'lot_dao.g.dart';

@DriftAccessor(tables: [LocalLots])
class LotDao extends DatabaseAccessor<AppDatabase> with _$LotDaoMixin {
  LotDao(super.db);

  Future<void> upsert(LocalLotsCompanion companion) =>
      into(localLots).insertOnConflictUpdate(companion);

  Future<List<DbLocalLot>> findAllByUser(String userId) =>
      (select(localLots)
            ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<DbLocalLot?> findById(String id, String userId) =>
      (select(localLots)
            ..where((t) =>
                t.id.equals(id) &
                t.userId.equals(userId) &
                t.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();

  Future<void> softDelete(String id) =>
      (update(localLots)..where((t) => t.id.equals(id)))
          .write(LocalLotsCompanion(deletedAt: Value(DateTime.now())));
}
