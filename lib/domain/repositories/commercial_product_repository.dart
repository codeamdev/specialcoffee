import 'package:special_coffee/domain/entities/commercial_product.dart';

abstract interface class CommercialProductRepository {
  Future<List<CommercialProduct>> getByInventoryId(String roastedInventoryId);
  Future<List<CommercialProduct>> getAll();
  Future<CommercialProduct> save(CommercialProduct product);
}
