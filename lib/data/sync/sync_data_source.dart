import 'package:special_coffee/core/database/app_database.dart';

/// Interfaz delgada sobre los DAOs de Drift para que SyncService sea testable
/// sin depender de la base de datos real.
abstract class SyncDataSource {
  // ── Readings (ya existentes) ──────────────────────────────────────────────
  Future<List<DbFermentationReading>> getUnsyncedFermentationReadings();
  Future<void> markFermentationSynced(String id);
  Future<List<DbDryingReading>> getUnsyncedDryingReadings();
  Future<void> markDryingSynced(String id);

  // ── Lots ──────────────────────────────────────────────────────────────────
  Future<List<DbLocalLot>> getUnsyncedLots();
  Future<void> markLotSynced(String id);

  // ── Cosecha pases ─────────────────────────────────────────────────────────
  Future<List<DbCosechaPase>> getUnsyncedCosechaPases();
  Future<void> markCosechaPaseSynced(String id);

  // ── Sessions ──────────────────────────────────────────────────────────────
  Future<List<DbFermentationSession>> getUnsyncedFermentationSessions();
  Future<void> markFermentationSessionSynced(String id);

  Future<List<DbDryingSession>> getUnsyncedDryingSessions();
  Future<void> markDryingSessionSynced(String id);

  Future<List<DbWashingSession>> getUnsyncedWashingSessions();
  Future<void> markWashingSessionSynced(String id);

  Future<List<DbMillingSession>> getUnsyncedMillingSessions();
  Future<void> markMillingSessionSynced(String id);

  Future<List<DbClassificationSession>> getUnsyncedClassificationSessions();
  Future<void> markClassificationSessionSynced(String id);
}

class LocalSyncDataSource implements SyncDataSource {
  const LocalSyncDataSource(this._db);

  final AppDatabase _db;

  // ── Readings ──────────────────────────────────────────────────────────────

  @override
  Future<List<DbFermentationReading>> getUnsyncedFermentationReadings() =>
      _db.fermentationDao.getUnsyncedReadings();

  @override
  Future<void> markFermentationSynced(String id) =>
      _db.fermentationDao.markFermentationReadingSynced(id);

  @override
  Future<List<DbDryingReading>> getUnsyncedDryingReadings() =>
      _db.dryingDao.getUnsyncedReadings();

  @override
  Future<void> markDryingSynced(String id) =>
      _db.dryingDao.markDryingReadingSynced(id);

  // ── Lots ──────────────────────────────────────────────────────────────────

  @override
  Future<List<DbLocalLot>> getUnsyncedLots() =>
      _db.lotDao.getUnsyncedLots();

  @override
  Future<void> markLotSynced(String id) =>
      _db.lotDao.markLotSynced(id);

  // ── Cosecha pases ─────────────────────────────────────────────────────────

  @override
  Future<List<DbCosechaPase>> getUnsyncedCosechaPases() =>
      _db.cosechaPaseDao.getUnsyncedPases();

  @override
  Future<void> markCosechaPaseSynced(String id) =>
      _db.cosechaPaseDao.markPaseSynced(id);

  // ── Sessions ──────────────────────────────────────────────────────────────

  @override
  Future<List<DbFermentationSession>> getUnsyncedFermentationSessions() =>
      _db.fermentationDao.getUnsyncedSessions();

  @override
  Future<void> markFermentationSessionSynced(String id) =>
      _db.fermentationDao.markFermentationSessionSynced(id);

  @override
  Future<List<DbDryingSession>> getUnsyncedDryingSessions() =>
      _db.dryingDao.getUnsyncedSessions();

  @override
  Future<void> markDryingSessionSynced(String id) =>
      _db.dryingDao.markDryingSessionSynced(id);

  @override
  Future<List<DbWashingSession>> getUnsyncedWashingSessions() =>
      _db.washingDao.getUnsyncedSessions();

  @override
  Future<void> markWashingSessionSynced(String id) =>
      _db.washingDao.markWashingSessionSynced(id);

  @override
  Future<List<DbMillingSession>> getUnsyncedMillingSessions() =>
      _db.millingDao.getUnsyncedSessions();

  @override
  Future<void> markMillingSessionSynced(String id) =>
      _db.millingDao.markMillingSessionSynced(id);

  @override
  Future<List<DbClassificationSession>> getUnsyncedClassificationSessions() =>
      _db.classificationDao.getUnsyncedSessions();

  @override
  Future<void> markClassificationSessionSynced(String id) =>
      _db.classificationDao.markClassificationSessionSynced(id);
}
