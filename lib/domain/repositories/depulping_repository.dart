import 'package:special_coffee/domain/entities/depulping_session.dart';

abstract interface class DepulpingRepository {
  Future<DepulpingSession?> getByLotId(String lotId);
  Future<DepulpingSession>  save(DepulpingSession session);
}
