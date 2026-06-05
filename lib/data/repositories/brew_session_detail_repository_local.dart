import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/brew_session_detail_dao.dart';
import 'package:special_coffee/domain/entities/brew_session_detail.dart';
import 'package:special_coffee/domain/repositories/brew_session_detail_repository.dart';
import 'package:uuid/uuid.dart';

class BrewSessionDetailLocalRepository implements BrewSessionDetailRepository {
  BrewSessionDetailLocalRepository(this._dao);

  final BrewSessionDetailDao _dao;
  static const _uuid = Uuid();

  @override
  Future<BrewSessionDetail?> getByBrewingSession(
          String brewingSessionId) async {
    final row = await _dao.getByBrewingSession(brewingSessionId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<BrewSessionDetail> save(BrewSessionDetail detail) async {
    final id = detail.id.isEmpty ? _uuid.v4() : detail.id;
    await _dao.upsert(BrewSessionDetailsCompanion(
      id:                Value(id),
      brewingSessionId:  Value(detail.brewingSessionId),
      coffeeReferenceId: Value(detail.coffeeReferenceId),
      waterProfileId:    Value(detail.waterProfileId),
      actualRatioUsed:   Value(detail.actualRatioUsed),
      extractionYieldPct: Value(detail.extractionYieldPct),
      measuredTdsPct:    Value(detail.measuredTdsPct),
      notes:             Value(detail.notes),
      createdAt:         Value(detail.createdAt),
    ));
    return BrewSessionDetail(
      id:                id,
      brewingSessionId:  detail.brewingSessionId,
      coffeeReferenceId: detail.coffeeReferenceId,
      waterProfileId:    detail.waterProfileId,
      actualRatioUsed:   detail.actualRatioUsed,
      extractionYieldPct: detail.extractionYieldPct,
      measuredTdsPct:    detail.measuredTdsPct,
      notes:             detail.notes,
      createdAt:         detail.createdAt,
    );
  }

  BrewSessionDetail _fromRow(DbBrewSessionDetail r) => BrewSessionDetail(
        id:                r.id,
        brewingSessionId:  r.brewingSessionId,
        coffeeReferenceId: r.coffeeReferenceId,
        waterProfileId:    r.waterProfileId,
        actualRatioUsed:   r.actualRatioUsed,
        extractionYieldPct: r.extractionYieldPct,
        measuredTdsPct:    r.measuredTdsPct,
        notes:             r.notes,
        createdAt:         r.createdAt,
      );
}
