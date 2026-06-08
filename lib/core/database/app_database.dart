import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:special_coffee/core/database/daos/batch_insights_dao.dart';
import 'package:special_coffee/core/database/daos/lot_stage_log_dao.dart';
import 'package:special_coffee/core/database/daos/brew_session_detail_dao.dart';
import 'package:special_coffee/core/database/daos/brewing_session_dao.dart';
import 'package:special_coffee/core/database/daos/classification_dao.dart';
import 'package:special_coffee/core/database/daos/coffee_reference_dao.dart';
import 'package:special_coffee/core/database/daos/cupping_dao.dart';
import 'package:special_coffee/core/database/daos/depulping_dao.dart';
import 'package:special_coffee/core/database/daos/drying_dao.dart';
import 'package:special_coffee/core/database/daos/fermentation_dao.dart';
import 'package:special_coffee/core/database/daos/harvest_dao.dart';
import 'package:special_coffee/core/database/daos/lot_dao.dart';
import 'package:special_coffee/core/database/daos/milling_dao.dart';
import 'package:special_coffee/core/database/daos/varieties_dao.dart';
import 'package:special_coffee/core/database/daos/washing_dao.dart';
import 'package:special_coffee/core/database/daos/water_profile_dao.dart';
// Block G — Coffee Master
import 'package:special_coffee/core/database/daos/physical_analysis_dao.dart';
import 'package:special_coffee/core/database/daos/roast_profile_dao.dart';
import 'package:special_coffee/core/database/daos/cupping_evaluation_dao.dart';
// Block H — Brand Manager
import 'package:special_coffee/core/database/daos/green_inventory_dao.dart';
import 'package:special_coffee/core/database/daos/roasted_inventory_dao.dart';
import 'package:special_coffee/core/database/daos/commercial_product_dao.dart';
import 'package:special_coffee/core/database/daos/lot_certification_dao.dart';
import 'package:special_coffee/core/database/tables/batch_insights_table.dart';
import 'package:special_coffee/core/database/tables/lot_stage_log_table.dart';
import 'package:special_coffee/core/database/tables/brew_session_details_table.dart';
import 'package:special_coffee/core/database/tables/brewing_sessions_table.dart';
import 'package:special_coffee/core/database/tables/classification_tables.dart';
import 'package:special_coffee/core/database/tables/coffee_references_table.dart';
import 'package:special_coffee/core/database/tables/cupping_tables.dart';
import 'package:special_coffee/core/database/tables/depulping_tables.dart';
import 'package:special_coffee/core/database/tables/drying_tables.dart';
import 'package:special_coffee/core/database/tables/fermentation_tables.dart';
import 'package:special_coffee/core/database/tables/harvest_tables.dart';
import 'package:special_coffee/core/database/tables/local_lots_table.dart';
import 'package:special_coffee/core/database/tables/lots_table.dart';
import 'package:special_coffee/core/database/tables/milling_tables.dart';
import 'package:special_coffee/core/database/tables/varieties_table.dart';
import 'package:special_coffee/core/database/tables/washing_tables.dart';
import 'package:special_coffee/core/database/tables/water_profiles_table.dart';
// Block G tables
import 'package:special_coffee/core/database/tables/physical_analyses_table.dart';
import 'package:special_coffee/core/database/tables/roast_profiles_table.dart';
import 'package:special_coffee/core/database/tables/cupping_evaluations_table.dart';
// Block H tables
import 'package:special_coffee/core/database/tables/green_inventory_table.dart';
import 'package:special_coffee/core/database/tables/roasted_inventory_table.dart';
import 'package:special_coffee/core/database/tables/commercial_products_table.dart';
import 'package:special_coffee/core/database/tables/lot_certifications_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Lots,
    LocalLots,
    FermentationSessions,
    FermentationReadings,
    DryingSessions,
    DryingReadings,
    HarvestSessions,
    HarvestPasses,
    ClassificationSessions,
    DepulpingSessions,
    CuppingSessions,
    WashingSessions,
    CoffeeVarietiesCatalog,
    BrewingSessions,
    MillingSessions,
    BatchInsights,
    CoffeeReferences,
    WaterProfiles,
    BrewSessionDetails,
    LotStageLogs,
    // Block G — Coffee Master (v14)
    PhysicalAnalyses,
    RoastProfiles,
    CuppingEvaluations,
    // Block H — Brand Manager (v15)
    GreenInventories,
    RoastedInventories,
    CommercialProducts,
    LotCertifications,
  ],
  daos: [
    FermentationDao, DryingDao, HarvestDao, ClassificationDao,
    DepulpingDao, CuppingDao, LotDao, WashingDao, VarietiesDao,
    BrewingSessionDao, MillingDao, BatchInsightsDao,
    CoffeeReferenceDao, WaterProfileDao, BrewSessionDetailDao,
    LotStageLogDao,
    // Block G
    PhysicalAnalysisDao, RoastProfileDao, CuppingEvaluationDao,
    // Block H
    GreenInventoryDao, RoastedInventoryDao, CommercialProductDao,
    LotCertificationDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(harvestSessions);
            await m.createTable(harvestPasses);
          }
          if (from < 3) {
            await m.createTable(classificationSessions);
          }
          if (from < 4) {
            await m.createTable(depulpingSessions);
          }
          if (from < 5) {
            await m.createTable(cuppingSessions);
          }
          if (from < 6) {
            await m.createTable(localLots);
          }
          if (from < 7) {
            await m.createTable(washingSessions);
          }
          if (from < 8) {
            await m.createTable(coffeeVarietiesCatalog);
          }
          if (from < 9) {
            await m.createTable(brewingSessions);
          }
          if (from < 10) {
            await m.createTable(millingSessions);
          }
          if (from < 11) {
            await m.createTable(batchInsights);
          }
          if (from < 12) {
            await m.createTable(coffeeReferences);
            await m.createTable(waterProfiles);
            await m.createTable(brewSessionDetails);
          }
          if (from < 13) {
            await m.createTable(lotStageLogs);
          }
          // Block G — Coffee Master
          if (from < 14) {
            await m.createTable(physicalAnalyses);
            await m.createTable(roastProfiles);
            await m.createTable(cuppingEvaluations);
          }
          // Block H — Brand Manager
          if (from < 15) {
            await m.createTable(greenInventories);
            await m.createTable(roastedInventories);
            await m.createTable(commercialProducts);
            await m.createTable(lotCertifications);
          }
        },
      );
}

QueryExecutor _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/special_coffee.db');
      return NativeDatabase.createInBackground(file);
    });
