import 'package:drift/drift.dart';

/// Pase de cosecha — unidad de proceso húmedo.
/// Un lote puede tener múltiples pases a lo largo de la temporada.
/// Encapsula recolección + clasificación (implícita) + despulpado (implícito).
@DataClassName('DbCosechaPase')
class CosechaPases extends Table {
  TextColumn get id        => text()();
  TextColumn get lotId     => text().named('lot_id')();
  TextColumn get createdBy => text().named('created_by')();

  // ── Recolección ───────────────────────────────────────────────────────────
  DateTimeColumn get fechaRecoleccion => dateTime().named('fecha_recoleccion')();
  DateTimeColumn get horaInicio       => dateTime().named('hora_inicio').nullable()();
  DateTimeColumn get horaFin          => dateTime().named('hora_fin').nullable()();
  RealColumn     get pesoCerezaKg     => real().named('peso_cereza_kg')();
  IntColumn      get numOperarios     => integer().named('num_operarios').nullable()();
  RealColumn     get brixPromedio     => real().named('brix_promedio').nullable()();
  RealColumn     get pctMadurezVisual => real().named('pct_madurez_visual').nullable()();

  // ── Proceso ───────────────────────────────────────────────────────────────
  // 'lavado'|'natural'|'honey_yellow'|'honey_red'|'anaerobic_lactic'|'anaerobic_carbonic'
  TextColumn get tipoProceso => text().named('tipo_proceso')();

  // ── Clasificación implícita (flotación + descarte manual) ─────────────────
  RealColumn get pesoFlotacionKg => real().named('peso_flotacion_kg').nullable()();
  RealColumn get pctFlotacion    => real().named('pct_flotacion').nullable()();

  // ── Despulpado implícito (aplica lavado/honey/anaeróbico) ─────────────────
  RealColumn get pesoPergaminoHumedoKg =>
      real().named('peso_pergamino_humedo_kg').nullable()();
  RealColumn get horasHastaDespulpe =>
      real().named('horas_hasta_despulpe').nullable()();

  // ── Workflow ──────────────────────────────────────────────────────────────
  // 'clasificacion'|'fermentacion'|'lavado'|'secado'|'trilla'|'completado'
  TextColumn get etapaActual =>
      text().named('etapa_actual').withDefault(const Constant('clasificacion'))();
  // 'activo'|'completado'|'abandonado'
  TextColumn get status => text().withDefault(const Constant('activo'))();

  TextColumn     get notas     => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  DateTimeColumn get syncedAt  => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'cosecha_pases';

  @override
  Set<Column> get primaryKey => {id};
}
