import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/lot_certifications_table.dart';

part 'lot_certification_dao.g.dart';

@DriftAccessor(tables: [LotCertifications])
class LotCertificationDao extends DatabaseAccessor<AppDatabase>
    with _$LotCertificationDaoMixin {
  LotCertificationDao(super.db);

  Future<void> upsert(LotCertificationsCompanion row) =>
      into(lotCertifications).insertOnConflictUpdate(row);

  Future<List<DbLotCertification>> getByLotId(String lotId) =>
      (select(lotCertifications)
            ..where((t) => t.lotId.equals(lotId)))
          .get();

  Future<void> deleteById(String id) =>
      (delete(lotCertifications)..where((t) => t.id.equals(id))).go();
}
