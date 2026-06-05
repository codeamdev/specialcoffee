import 'package:special_coffee/domain/entities/water_profile.dart';

abstract interface class WaterProfileRepository {
  Future<List<WaterProfile>> getAll();
  Stream<List<WaterProfile>> watchAll();
  Future<WaterProfile?> getById(String id);
  Future<WaterProfile> save(WaterProfile profile);
}
