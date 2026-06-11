# Decisión: Campos de lote sin sincronización con PostgreSQL

**Fecha:** 2026-06-10  
**Estado:** Activo — pendiente de revisión de producto

---

## Contexto

La tabla `lots` en PostgreSQL fue diseñada en Sprint 1 con un esquema mínimo enfocado en trazabilidad de proceso. La tabla local `local_lots` de Drift acumula campos agronómicos adicionales que no tienen columna equivalente en la tabla remota.

Al implementar el sync `local_lots → lots` (v21), estos campos no pueden enviarse a PostgREST porque generarían un error 400 (columna desconocida) o se perderían silenciosamente.

---

## Campos afectados

| Campo local         | Columna Drift           | Estado sync        |
|---------------------|-------------------------|--------------------|
| `latitude`          | `latitude REAL`         | ❌ No sincronizado |
| `longitude`         | `longitude REAL`        | ❌ No sincronizado |
| `farm_area_ha`      | `farm_area_ha REAL`     | ❌ No sincronizado |
| `blend_variety_ids` | `blend_variety_ids TEXT`| ❌ No sincronizado |
| `plant_age_years`   | `plant_age_years INT`   | ❌ No sincronizado |
| `plant_type`        | `plant_type TEXT`       | ❌ No sincronizado |

---

## Opciones evaluadas

1. **Enviar el campo y que PostgREST lo ignore** — No viable: PostgREST 400 por columna desconocida.
2. **Omitir los campos del payload de sync** — Adoptada. El sync usa solo los campos que `lots` acepta.
3. **Agregar las columnas a `lots` ahora** — Requiere migración PostgreSQL y acuerdo de producto (¿son parte del modelo de negocio o solo locales?). Pendiente de revisión.
4. **Eliminar los campos del schema local** — Rechazada. Ya hay datos guardados localmente; eliminarlos es destructivo.

---

## Decisión adoptada

Los campos se mantienen en Drift (sin eliminar) pero:
- **En `LotCreateScreen`**: los inputs correspondientes están deshabilitados (`enabled: false` + `IgnorePointer`) y muestran el disclaimer _"Campo no sincronizado — pendiente de revisión de producto."_
- **En `SyncService._syncLots()`**: los campos se omiten del payload JSON enviado a PostgREST.
- Los valores siguen guardándose localmente si vienen del GPS (lat/lng vía `currentGpsPositionProvider`).

---

## Próximo paso recomendado

Revisar con el equipo de producto si `latitude`, `longitude`, `farm_area_ha`, `blend_variety_ids`, `plant_age_years` y `plant_type` forman parte del modelo de datos del servidor. Si sí:

1. Agregar las columnas en `backend/migrations/005_lots_agronomic_fields.sql`
2. Habilitar los inputs en `LotCreateScreen` (quitar `enabled: false`)
3. Incluir los campos en el payload de `SyncService._syncLots()`
4. Eliminar este disclaimer

Deuda registrada en `AUDIT.md` como `SYNC-2`.
