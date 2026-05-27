import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:special_coffee/core/database/daos/classification_dao.dart';
import 'package:special_coffee/core/database/daos/cupping_dao.dart';
import 'package:special_coffee/core/database/daos/depulping_dao.dart';
import 'package:special_coffee/core/database/daos/drying_dao.dart';
import 'package:special_coffee/core/database/daos/fermentation_dao.dart';
import 'package:special_coffee/core/database/daos/harvest_dao.dart';
import 'package:special_coffee/core/database/daos/lot_dao.dart';
import 'package:special_coffee/core/database/daos/washing_dao.dart';
import 'package:special_coffee/core/database/tables/classification_tables.dart';
import 'package:special_coffee/core/database/tables/cupping_tables.dart';
import 'package:special_coffee/core/database/tables/depulping_tables.dart';
import 'package:special_coffee/core/database/tables/drying_tables.dart';
import 'package:special_coffee/core/database/tables/fermentation_tables.dart';
import 'package:special_coffee/core/database/tables/harvest_tables.dart';
import 'package:special_coffee/core/database/tables/local_lots_table.dart';
import 'package:special_coffee/core/database/tables/lots_table.dart';
import 'package:special_coffee/core/database/tables/washing_tables.dart';

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
  ],
  daos: [FermentationDao, DryingDao, HarvestDao, ClassificationDao, DepulpingDao, CuppingDao, LotDao, WashingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

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
        },
      );
}

QueryExecutor _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/special_coffee.db');
      return NativeDatabase.createInBackground(file);
    });
