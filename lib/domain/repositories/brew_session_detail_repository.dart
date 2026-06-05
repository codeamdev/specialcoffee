import 'package:special_coffee/domain/entities/brew_session_detail.dart';

abstract interface class BrewSessionDetailRepository {
  Future<BrewSessionDetail?> getByBrewingSession(String brewingSessionId);
  Future<BrewSessionDetail> save(BrewSessionDetail detail);
}
