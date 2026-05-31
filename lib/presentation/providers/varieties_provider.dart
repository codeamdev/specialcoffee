import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/coffee_variety.dart';

part 'varieties_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<CoffeeVariety>> coffeeVarieties(Ref ref) async {
  final dao = ref.watch(appDatabaseProvider).varietiesDao;
  // Seed on first install / after schema migration — idempotent (insertAllOnConflictUpdate)
  if (await dao.isEmpty()) await dao.seedDefaults();
  return dao.getAll();
}
