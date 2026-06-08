import 'package:special_coffee/domain/entities/lot_certification.dart';

abstract interface class LotCertificationRepository {
  Future<List<LotCertification>> getByLotId(String lotId);
  Future<LotCertification> save(LotCertification certification);
  Future<void> deleteById(String id);
}
