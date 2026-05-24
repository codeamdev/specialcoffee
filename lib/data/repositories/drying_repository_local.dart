import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/drying_dao.dart';
import 'package:special_coffee/domain/entities/drying_session.dart';
import 'package:special_coffee/domain/repositories/drying_repository.dart';
import 'package:uuid/uuid.dart';

class DryingLocalRepository implements DryingRepository {
  DryingLocalRepository(this._dao, this._ownerId);

  final DryingDao _dao;
  final String _ownerId;
  static const _uuid = Uuid();

  @override
  Future<DryingSession> createSession({
    required String lotId,
    required String dryingMethod,
  }) async {
    // Enforce one active session per lot
    final existing = await _dao.getActiveSession(lotId);
    if (existing != null) return _sessionFromRow(existing);

    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.insertSession(DryingSessionsCompanion(
      id: Value(id),
      lotId: Value(lotId),
      ownerId: Value(_ownerId),
      dryingMethod: Value(dryingMethod),
      startedAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    return DryingSession(
      id: id,
      lotId: lotId,
      ownerId: _ownerId,
      dryingMethod: dryingMethod,
      startedAt: now,
      createdAt: now,
    );
  }

  @override
  Future<DryingSession?> getActiveSession(String lotId) async {
    final row = await _dao.getActiveSession(lotId);
    return row != null ? _sessionFromRow(row) : null;
  }

  @override
  Future<DryingReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int dayNumber,
    required double moisturePct,
    required double ambientTempC,
    required double ambientHumidityPct,
    double uvIndex = 0.0,
    String? aiRecommendation,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.insertReading(DryingReadingsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      lotId: Value(lotId),
      ownerId: Value(_ownerId),
      moisturePct: Value(moisturePct),
      ambientTempC: Value(ambientTempC),
      ambientHumidityPct: Value(ambientHumidityPct),
      uvIndex: Value(uvIndex),
      aiRecommendation: Value(aiRecommendation),
      recordedAt: Value(now),
      updatedAt: Value(now),
    ));
    return DryingReadingRecord(
      id: id,
      sessionId: sessionId,
      lotId: lotId,
      ownerId: _ownerId,
      dayNumber: dayNumber,
      moisturePct: moisturePct,
      ambientTempC: ambientTempC,
      ambientHumidityPct: ambientHumidityPct,
      uvIndex: uvIndex,
      aiRecommendation: aiRecommendation,
      recordedAt: now,
    );
  }

  @override
  Future<List<DryingReadingRecord>> getReadings(String sessionId) async {
    final session = await _dao.getSessionById(sessionId);
    if (session == null) return [];
    final rows = await _dao.getReadings(sessionId);
    return rows.map((r) => _readingFromRow(r, session.startedAt)).toList();
  }

  @override
  Future<void> closeSession({
    required String sessionId,
    required double finalMoisturePct,
  }) =>
      _dao.updateSession(
        sessionId,
        DryingSessionsCompanion(
          endedAt: Value(DateTime.now()),
          finalMoisturePct: Value(finalMoisturePct),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ── Mappers ────────────────────────────────────────────────────────────────

  DryingSession _sessionFromRow(DbDryingSession r) => DryingSession(
        id: r.id,
        lotId: r.lotId,
        ownerId: r.ownerId,
        dryingMethod: r.dryingMethod,
        startedAt: r.startedAt,
        endedAt: r.endedAt,
        targetMoisturePct: r.targetMoisturePct,
        finalMoisturePct: r.finalMoisturePct,
        createdAt: r.createdAt,
      );

  DryingReadingRecord _readingFromRow(DbDryingReading r, DateTime sessionStart) {
    final dayNumber =
        (r.recordedAt.difference(sessionStart).inHours / 24).floor() + 1;
    return DryingReadingRecord(
      id: r.id,
      sessionId: r.sessionId,
      lotId: r.lotId,
      ownerId: r.ownerId,
      dayNumber: dayNumber,
      moisturePct: r.moisturePct,
      ambientTempC: r.ambientTempC,
      ambientHumidityPct: r.ambientHumidityPct,
      uvIndex: r.uvIndex,
      aiRecommendation: r.aiRecommendation,
      recordedAt: r.recordedAt,
    );
  }
}
