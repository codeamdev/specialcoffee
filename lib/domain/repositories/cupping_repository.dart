import 'package:special_coffee/domain/entities/cupping_session.dart';

abstract class CuppingRepository {
  Future<CuppingSession?> getByLotId(String lotId);
  Future<CuppingSession> save(CuppingSession session);
  Future<List<CuppingSession>> getAllByOwner(String ownerId);
}
