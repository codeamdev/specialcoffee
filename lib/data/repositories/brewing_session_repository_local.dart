import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/brewing_session_dao.dart';
import 'package:special_coffee/domain/entities/brewing_session.dart';
import 'package:special_coffee/domain/repositories/brewing_session_repository.dart';
import 'package:uuid/uuid.dart';

class BrewingSessionLocalRepository implements BrewingSessionRepository {
  BrewingSessionLocalRepository(this._dao, this._ownerId);

  final BrewingSessionDao _dao;
  final String            _ownerId;
  static const _uuid = Uuid();

  @override
  Future<BrewingSession> save(BrewingSession session) async {
    final now = DateTime.now();
    final id  = session.id.isEmpty ? _uuid.v4() : session.id;
    await _dao.upsert(BrewingSessionsCompanion(
      id:            Value(id),
      ownerId:       Value(_ownerId),
      method:        Value(session.method),
      doseG:         Value(session.doseG),
      waterG:        Value(session.waterG),
      waterTempC:    Value(session.waterTempC),
      actualTimeSec: Value(session.actualTimeSec),
      tdsPct:        Value(session.tdsPct),
      yieldG:        Value(session.yieldG),
      notes:         Value(session.notes),
      brewedAt:      Value(session.brewedAt),
      createdAt:     Value(now),
    ));
    return BrewingSession(
      id:            id,
      ownerId:       _ownerId,
      method:        session.method,
      doseG:         session.doseG,
      waterG:        session.waterG,
      waterTempC:    session.waterTempC,
      actualTimeSec: session.actualTimeSec,
      tdsPct:        session.tdsPct,
      yieldG:        session.yieldG,
      notes:         session.notes,
      brewedAt:      session.brewedAt,
      createdAt:     now,
    );
  }

  @override
  Future<List<BrewingSession>> getRecent({int limit = 20}) =>
      _dao.getRecent(limit: limit);
}
