import 'package:special_coffee/domain/entities/coffee_reference.dart';

abstract interface class CoffeeReferenceRepository {
  Future<List<CoffeeReference>> getAll();
  Stream<List<CoffeeReference>> watchAll();
  Future<CoffeeReference?> getById(String id);
  Future<CoffeeReference> save(CoffeeReference reference);
  Future<void> updateStatus(String id, String status);
}
