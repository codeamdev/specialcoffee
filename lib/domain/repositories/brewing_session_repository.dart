import 'package:special_coffee/domain/entities/brewing_session.dart';

abstract interface class BrewingSessionRepository {
  Future<BrewingSession> save(BrewingSession session);
  Future<List<BrewingSession>> getRecent({int limit = 20});
}
