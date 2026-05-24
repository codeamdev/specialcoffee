import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:special_coffee/core/database/daos/drying_dao.dart';
import 'package:special_coffee/core/database/daos/fermentation_dao.dart';
import 'package:special_coffee/core/database/tables/drying_tables.dart';
import 'package:special_coffee/core/database/tables/fermentation_tables.dart';
import 'package:special_coffee/core/database/tables/lots_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Lots,
    FermentationSessions,
    FermentationReadings,
    DryingSessions,
    DryingReadings,
  ],
  daos: [FermentationDao, DryingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/special_coffee.db');
      return NativeDatabase.createInBackground(file);
    });
