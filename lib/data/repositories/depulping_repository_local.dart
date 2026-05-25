import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/depulping_dao.dart';
import 'package:special_coffee/domain/entities/depulping_session.dart';
import 'package:special_coffee/domain/repositories/depulping_repository.dart';
import 'package:uuid/uuid.dart';

class DepulpingLocalRepository implements DepulpingRepository {
  DepulpingLocalRepository(this._dao, this._ownerId);

  final DepulpingDao _dao;
  final String       _ownerId;
  static const _uuid = Uuid();

  @override
  Future<DepulpingSession?> getByLotId(String lotId) async {
    final row = await _dao.getByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<DepulpingSession> save(DepulpingSession session) async {
    final now = DateTime.now();
    final id  = session.id.isEmpty ? _uuid.v4() : session.id;
    await _dao.upsert(DepulpingSessionsCompanion(
      id:                      Value(id),
      lotId:                   Value(session.lotId),
      ownerId:                 Value(_ownerId),
      classificationSessionId: Value(session.classificationSessionId),
      kgDepulped:              Value(session.kgDepulped),
      depulpedAt:              Value(session.depulpedAt),
      referenceSource:         Value(session.referenceSource),
      hoursFromReference:      Value(session.hoursFromReference),
      aiAlertLevel:            Value(session.aiAlertLevel),
      aiAlertMessage:          Value(session.aiAlertMessage),
      notes:                   Value(session.notes),
      createdAt:               Value(session.createdAt),
      updatedAt:               Value(now),
    ));
    return DepulpingSession(
      id:                      id,
      lotId:                   session.lotId,
      ownerId:                 _ownerId,
      classificationSessionId: session.classificationSessionId,
      kgDepulped:              session.kgDepulped,
      depulpedAt:              session.depulpedAt,
      referenceSource:         session.referenceSource,
      hoursFromReference:      session.hoursFromReference,
      aiAlertLevel:            session.aiAlertLevel,
      aiAlertMessage:          session.aiAlertMessage,
      notes:                   session.notes,
      createdAt:               session.createdAt,
    );
  }

  DepulpingSession _fromRow(DbDepulpingSession r) => DepulpingSession(
        id:                      r.id,
        lotId:                   r.lotId,
        ownerId:                 r.ownerId,
        classificationSessionId: r.classificationSessionId,
        kgDepulped:              r.kgDepulped,
        depulpedAt:              r.depulpedAt,
        referenceSource:         r.referenceSource,
        hoursFromReference:      r.hoursFromReference,
        aiAlertLevel:            r.aiAlertLevel,
        aiAlertMessage:          r.aiAlertMessage,
        notes:                   r.notes,
        createdAt:               r.createdAt,
      );
}
