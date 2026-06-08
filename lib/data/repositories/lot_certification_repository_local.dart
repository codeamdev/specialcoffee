import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/lot_certification_dao.dart';
import 'package:special_coffee/domain/entities/lot_certification.dart';
import 'package:special_coffee/domain/repositories/lot_certification_repository.dart';
import 'package:uuid/uuid.dart';

class LotCertificationLocalRepository implements LotCertificationRepository {
  LotCertificationLocalRepository(this._dao);

  final LotCertificationDao _dao;
  static const _uuid = Uuid();

  @override
  Future<List<LotCertification>> getByLotId(String lotId) async {
    final rows = await _dao.getByLotId(lotId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<LotCertification> save(LotCertification certification) async {
    final id = certification.id.isEmpty ? _uuid.v4() : certification.id;
    await _dao.upsert(LotCertificationsCompanion(
      id:             Value(id),
      lotId:          Value(certification.lotId),
      type:           Value(certification.type),
      issuingBody:    Value(certification.issuingBody),
      validFrom:      Value(certification.validFrom),
      validUntil:     Value(certification.validUntil),
      certificateUrl: Value(certification.certificateUrl),
    ));
    return LotCertification(
      id:             id,
      lotId:          certification.lotId,
      type:           certification.type,
      issuingBody:    certification.issuingBody,
      validFrom:      certification.validFrom,
      validUntil:     certification.validUntil,
      certificateUrl: certification.certificateUrl,
    );
  }

  @override
  Future<void> deleteById(String id) => _dao.deleteById(id);

  LotCertification _fromRow(DbLotCertification r) => LotCertification(
        id:             r.id,
        lotId:          r.lotId,
        type:           r.type,
        issuingBody:    r.issuingBody,
        validFrom:      r.validFrom,
        validUntil:     r.validUntil,
        certificateUrl: r.certificateUrl,
      );
}
