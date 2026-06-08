import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/commercial_product_dao.dart';
import 'package:special_coffee/domain/entities/commercial_product.dart';
import 'package:special_coffee/domain/repositories/commercial_product_repository.dart';
import 'package:uuid/uuid.dart';

class CommercialProductLocalRepository implements CommercialProductRepository {
  CommercialProductLocalRepository(this._dao);

  final CommercialProductDao _dao;
  static const _uuid = Uuid();

  @override
  Future<List<CommercialProduct>> getByInventoryId(String roastedInventoryId) async {
    final rows = await _dao.getByInventoryId(roastedInventoryId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<CommercialProduct>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<CommercialProduct> save(CommercialProduct product) async {
    final id  = product.id.isEmpty ? _uuid.v4() : product.id;
    final now = product.createdAt;
    await _dao.upsert(CommercialProductsCompanion(
      id:                 Value(id),
      roastedInventoryId: Value(product.roastedInventoryId),
      name:               Value(product.name),
      description:        Value(product.description),
      formatG:            Value(product.formatG),
      unitsProduced:      Value(product.unitsProduced),
      unitsAvailable:     Value(product.unitsAvailable),
      costUsd:            Value(product.costUsd),
      priceUsd:           Value(product.priceUsd),
      packagedDate:       Value(product.packagedDate),
      barcode:            Value(product.barcode),
      createdAt:          Value(now),
    ));
    return CommercialProduct(
      id:                 id,
      roastedInventoryId: product.roastedInventoryId,
      name:               product.name,
      description:        product.description,
      formatG:            product.formatG,
      unitsProduced:      product.unitsProduced,
      unitsAvailable:     product.unitsAvailable,
      costUsd:            product.costUsd,
      priceUsd:           product.priceUsd,
      packagedDate:       product.packagedDate,
      barcode:            product.barcode,
      createdAt:          now,
    );
  }

  CommercialProduct _fromRow(DbCommercialProduct r) => CommercialProduct(
        id:                 r.id,
        roastedInventoryId: r.roastedInventoryId,
        name:               r.name,
        description:        r.description,
        formatG:            r.formatG,
        unitsProduced:      r.unitsProduced,
        unitsAvailable:     r.unitsAvailable,
        costUsd:            r.costUsd,
        priceUsd:           r.priceUsd,
        packagedDate:       r.packagedDate,
        barcode:            r.barcode,
        createdAt:          r.createdAt,
      );
}
