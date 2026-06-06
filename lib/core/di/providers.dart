import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/data/repositories/classification_repository_local.dart';
import 'package:special_coffee/data/repositories/cupping_repository_local.dart';
import 'package:special_coffee/data/repositories/depulping_repository_local.dart';
import 'package:special_coffee/data/repositories/drying_repository_local.dart';
import 'package:special_coffee/data/repositories/fermentation_repository_local.dart';
import 'package:special_coffee/data/repositories/harvest_repository_local.dart';
import 'package:special_coffee/data/repositories/lot_repository_local.dart';
import 'package:special_coffee/data/repositories/batch_insights_repository_local.dart';
import 'package:special_coffee/data/repositories/brew_session_detail_repository_local.dart';
import 'package:special_coffee/data/repositories/coffee_reference_repository_local.dart';
import 'package:special_coffee/data/repositories/water_profile_repository_local.dart';
import 'package:special_coffee/data/sync/sync_data_source.dart';
import 'package:special_coffee/domain/repositories/brew_session_detail_repository.dart';
import 'package:special_coffee/domain/repositories/coffee_reference_repository.dart';
import 'package:special_coffee/domain/repositories/water_profile_repository.dart';
import 'package:special_coffee/data/sync/sync_service.dart';
import 'package:special_coffee/data/repositories/brewing_session_repository_local.dart';
import 'package:special_coffee/data/repositories/milling_repository_local.dart';
import 'package:special_coffee/data/repositories/washing_repository_local.dart';
import 'package:special_coffee/domain/repositories/brewing_session_repository.dart';
import 'package:special_coffee/domain/repositories/classification_repository.dart';
import 'package:special_coffee/domain/repositories/cupping_repository.dart';
import 'package:special_coffee/domain/repositories/depulping_repository.dart';
import 'package:special_coffee/domain/repositories/drying_repository.dart';
import 'package:special_coffee/domain/repositories/fermentation_repository.dart';
import 'package:special_coffee/domain/repositories/harvest_repository.dart';
import 'package:special_coffee/domain/repositories/lot_repository.dart';
import 'package:special_coffee/domain/repositories/milling_repository.dart';
import 'package:special_coffee/domain/repositories/washing_repository.dart';
import 'package:special_coffee/presentation/providers/auth_provider.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
FermentationRepository fermentationLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return FermentationLocalRepository(db.fermentationDao, userId);
}

@Riverpod(keepAlive: true)
DryingRepository dryingLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return DryingLocalRepository(db.dryingDao, userId);
}

@Riverpod(keepAlive: true)
HarvestRepository harvestLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return HarvestLocalRepository(db.harvestDao, userId);
}

@Riverpod(keepAlive: true)
ClassificationRepository classificationLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ClassificationLocalRepository(db.classificationDao, userId);
}

@Riverpod(keepAlive: true)
DepulpingRepository depulpingLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return DepulpingLocalRepository(db.depulpingDao, userId);
}

@Riverpod(keepAlive: true)
CuppingRepository cuppingLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return CuppingLocalRepository(db.cuppingDao, userId);
}

@Riverpod(keepAlive: true)
WashingRepository washingLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return WashingLocalRepository(db.washingDao, userId);
}

@Riverpod(keepAlive: true)
LotRepository lotLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LotLocalRepository(db.lotDao);
}

@Riverpod(keepAlive: true)
BrewingSessionRepository brewingSessionLocalRepo(Ref ref) {
  final db     = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return BrewingSessionLocalRepository(db.brewingSessionDao, userId);
}

@Riverpod(keepAlive: true)
MillingRepository millingLocalRepo(Ref ref) {
  final db     = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return MillingLocalRepository(db.millingDao, userId);
}

@Riverpod(keepAlive: true)
BatchInsightsLocalRepository batchInsightsLocalRepo(Ref ref) {
  final db     = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return BatchInsightsLocalRepository(db.batchInsightsDao, userId);
}

@Riverpod(keepAlive: true)
CoffeeReferenceRepository coffeeReferenceLocalRepo(Ref ref) {
  final db     = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return CoffeeReferenceLocalRepository(db.coffeeReferenceDao, userId);
}

@Riverpod(keepAlive: true)
WaterProfileRepository waterProfileLocalRepo(Ref ref) {
  final db     = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return WaterProfileLocalRepository(db.waterProfileDao, userId);
}

@Riverpod(keepAlive: true)
BrewSessionDetailRepository brewSessionDetailLocalRepo(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return BrewSessionDetailLocalRepository(db.brewSessionDetailDao);
}

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) => SyncService(
      LocalSyncDataSource(ref.watch(appDatabaseProvider)),
      ref.watch(apiClientProvider),
    );
