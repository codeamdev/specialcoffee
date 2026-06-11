import 'package:special_coffee/domain/entities/milling_session.dart';

abstract interface class MillingRepository {
  Future<MillingSession?> getByLotId(String lotId);
  Future<MillingSession> save(MillingSession session);
}
