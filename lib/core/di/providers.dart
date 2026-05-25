import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/data/repositories/classification_repository_local.dart';
import 'package:special_coffee/data/repositories/cupping_repository_local.dart';
import 'package:special_coffee/data/repositories/depulping_repository_local.dart';
import 'package:special_coffee/data/repositories/drying_repository_local.dart';
import 'package:special_coffee/data/repositories/fermentation_repository_local.dart';
import 'package:special_coffee/data/repositories/harvest_repository_local.dart';
import 'package:special_coffee/domain/repositories/classification_repository.dart';
import 'package:special_coffee/domain/repositories/cupping_repository.dart';
import 'package:special_coffee/domain/repositories/depulping_repository.dart';
import 'package:special_coffee/domain/repositories/drying_repository.dart';
import 'package:special_coffee/domain/repositories/fermentation_repository.dart';
import 'package:special_coffee/domain/repositories/harvest_repository.dart';
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
