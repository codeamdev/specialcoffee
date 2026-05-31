import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/varieties_table.dart';
import 'package:special_coffee/domain/entities/coffee_variety.dart';

part 'varieties_dao.g.dart';

@DriftAccessor(tables: [CoffeeVarietiesCatalog])
class VarietiesDao extends DatabaseAccessor<AppDatabase>
    with _$VarietiesDaoMixin {
  VarietiesDao(super.db);

  Future<List<CoffeeVariety>> getAll() async {
    final rows = await (select(coffeeVarietiesCatalog)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map(_toEntity).toList();
  }

  Future<bool> isEmpty() async {
    final count = await customSelect(
      'SELECT COUNT(*) AS c FROM coffee_varieties_catalog',
      readsFrom: {coffeeVarietiesCatalog},
    ).getSingleOrNull();
    return (count?.data['c'] as int? ?? 0) == 0;
  }

  Future<void> seedDefaults() {
    const rows = [
      (id: 'var_geisha',       name: 'Geisha',       sensitivity: 'very_high', scaPotential: 89.5, sortOrder: 1),
      (id: 'var_pink_bourbon', name: 'Pink Bourbon',  sensitivity: 'very_high', scaPotential: 88.0, sortOrder: 2),
      (id: 'var_typica',       name: 'Typica',        sensitivity: 'high',      scaPotential: 87.0, sortOrder: 3),
      (id: 'var_bourbon',      name: 'Borbón',        sensitivity: 'high',      scaPotential: 86.0, sortOrder: 4),
      (id: 'var_caturra',      name: 'Caturra',       sensitivity: 'high',      scaPotential: 85.5, sortOrder: 5),
      (id: 'var_castillo',     name: 'Castillo',      sensitivity: 'medium',    scaPotential: 84.0, sortOrder: 6),
      (id: 'var_colombia',     name: 'Colombia',      sensitivity: 'medium',    scaPotential: 83.0, sortOrder: 7),
    ];
    return batch((b) => b.insertAllOnConflictUpdate(
          coffeeVarietiesCatalog,
          rows
              .map((v) => CoffeeVarietiesCatalogCompanion.insert(
                    id:           v.id,
                    name:         v.name,
                    sensitivity:  Value(v.sensitivity),
                    scaPotential: Value(v.scaPotential),
                    sortOrder:    Value(v.sortOrder),
                  ))
              .toList(),
        ));
  }

  static CoffeeVariety _toEntity(DbCoffeeVariety r) => CoffeeVariety(
        id:           r.id,
        name:         r.name,
        sensitivity:  r.sensitivity,
        scaPotential: r.scaPotential,
      );
}
