import 'dart:convert';

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
    // Datos basados en: WCR Variety Catalog 2022, Cenicafé AT 335/420/457, FNC Colombia
    const rows = [
      (
        id: 'var_geisha',
        name: 'Geisha',
        sensitivity: 'very_high',
        scaPotential: 89.5,
        sortOrder: 1,
        especie: 'arabica',
        altMin: 1700,
        altMax: 2200,
        proceso: 'lavado',
        perfiles: '["jazmín","bergamota","durazno","té negro","cítrico"]',
      ),
      (
        id: 'var_pink_bourbon',
        name: 'Pink Bourbon',
        sensitivity: 'very_high',
        scaPotential: 88.0,
        sortOrder: 2,
        especie: 'arabica',
        altMin: 1600,
        altMax: 2000,
        proceso: 'honey',
        perfiles: '["frutos rojos","rosas","panela","fruta tropical"]',
      ),
      (
        id: 'var_typica',
        name: 'Typica',
        sensitivity: 'high',
        scaPotential: 87.0,
        sortOrder: 3,
        especie: 'arabica',
        altMin: 1400,
        altMax: 2000,
        proceso: 'lavado',
        perfiles: '["caramelo","chocolate","fruta suave","nuez"]',
      ),
      (
        id: 'var_bourbon',
        name: 'Borbón',
        sensitivity: 'high',
        scaPotential: 86.0,
        sortOrder: 4,
        especie: 'arabica',
        altMin: 1200,
        altMax: 1800,
        proceso: 'lavado',
        perfiles: '["caramelo","avellana","cereza","panela"]',
      ),
      (
        id: 'var_tabi',
        name: 'Tabi',
        sensitivity: 'high',
        scaPotential: 85.5,
        sortOrder: 5,
        especie: 'arabica',
        altMin: 1500,
        altMax: 2000,
        proceso: 'lavado',
        perfiles: '["floral","fruta tropical","chocolate","canela"]',
      ),
      (
        id: 'var_caturra',
        name: 'Caturra',
        sensitivity: 'high',
        scaPotential: 84.5,
        sortOrder: 6,
        especie: 'arabica',
        altMin: 1200,
        altMax: 1900,
        proceso: 'lavado',
        perfiles: '["cítrico","limón","panela","mandarina"]',
      ),
      (
        id: 'var_castillo',
        name: 'Castillo',
        sensitivity: 'medium',
        scaPotential: 84.0,
        sortOrder: 7,
        especie: 'arabica',
        altMin: 1000,
        altMax: 2000,
        proceso: 'lavado',
        perfiles: '["caramelo","chocolate","fruta roja leve","miel"]',
      ),
      (
        id: 'var_colombia',
        name: 'Colombia',
        sensitivity: 'medium',
        scaPotential: 83.0,
        sortOrder: 8,
        especie: 'arabica',
        altMin: 1200,
        altMax: 1800,
        proceso: 'lavado',
        perfiles: '["caramelo","chocolate amargo","nuez","miel"]',
      ),
    ];
    return batch((b) => b.insertAllOnConflictUpdate(
          coffeeVarietiesCatalog,
          rows
              .map((v) => CoffeeVarietiesCatalogCompanion.insert(
                    id:                 v.id,
                    name:               v.name,
                    sensitivity:        Value(v.sensitivity),
                    scaPotential:       Value(v.scaPotential),
                    sortOrder:          Value(v.sortOrder),
                    especie:            Value(v.especie),
                    altitudMinMasl:     Value(v.altMin),
                    altitudMaxMasl:     Value(v.altMax),
                    procesoRecomendado: Value(v.proceso),
                    perfilesSabor:      Value(v.perfiles),
                  ))
              .toList(),
        ));
  }

  static CoffeeVariety _toEntity(DbCoffeeVariety r) {
    List<String>? perfiles;
    if (r.perfilesSabor != null) {
      try {
        final decoded = jsonDecode(r.perfilesSabor!);
        if (decoded is List) perfiles = List<String>.from(decoded);
      } catch (_) {}
    }
    return CoffeeVariety(
      id:                r.id,
      name:              r.name,
      sensitivity:       r.sensitivity,
      scaPotential:      r.scaPotential,
      especie:           r.especie,
      altitudMinMasl:    r.altitudMinMasl,
      altitudMaxMasl:    r.altitudMaxMasl,
      procesoRecomendado: r.procesoRecomendado,
      perfilesSabor:     perfiles,
    );
  }
}
