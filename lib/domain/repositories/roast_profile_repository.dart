import 'package:special_coffee/domain/entities/roast_profile.dart';

abstract interface class RoastProfileRepository {
  Future<List<RoastProfile>> getByLotId(String lotId);
  Future<RoastProfile?> getById(String id);
  Future<RoastProfile> save(RoastProfile profile);
}
