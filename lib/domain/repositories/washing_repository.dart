import 'package:special_coffee/domain/entities/washing_session.dart';

abstract interface class WashingRepository {
  Future<WashingSession?> getByLotId(String lotId);
  Future<WashingSession> save(WashingSession session);
}
