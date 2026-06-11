# Sync Tables Mapping — SpecialCoffee AI
Date: 2026-06-10

## Pre-vuelo: tablas PostgreSQL detectadas
Ejecutado: `docker compose exec auth python -c "..."` apuntando a PostgREST en `http://postgrest:3000/`

### Tablas existentes en PostgreSQL (PostgREST)
lots, harvest_records, fermentation_sessions, fermentation_readings,
drying_sessions, drying_readings, brew_sessions, sca_evaluations,
sync_queue, ai_recommendations, alert_events, users, farm_plots,
ai_user_profiles, coffee_varieties_catalog, environmental_snapshots,
rule_effectiveness, storage_records

### Tablas existentes solo en Drift (necesitan tabla PostgreSQL nueva)
| Drift table        | Decisión                                              |
|--------------------|-------------------------------------------------------|
| cosecha_pases      | CREAR en PostgreSQL — migración 004                   |
| washing_sessions   | CREAR en PostgreSQL — migración 004 · REVISAR CON PRODUCTO |
| milling_sessions   | CREAR en PostgreSQL — migración 004 · REVISAR CON PRODUCTO |
| classification_sessions | CREAR en PostgreSQL — migración 004 · REVISAR CON PRODUCTO |

## Mapeo de columnas

### local_lots → lots
| Drift column     | PostgreSQL column | Notas                          |
|-----------------|-------------------|--------------------------------|
| id              | id                | PK                             |
| user_id         | owner_id          | nombre diferente               |
| variety_id      | variety_id        |                                |
| variety_name    | variety_name      |                                |
| altitude_masl   | altitude_masl     |                                |
| region          | region            |                                |
| notes           | notes             |                                |
| created_at      | created_at        |                                |
| —               | status            | enviado como 'activo'          |
| —               | plot_id           | enviado como null              |
| —               | process_type      | enviado como ''                |
| latitude        | —                 | no existe en lots (farm_plots) |
| longitude       | —                 | no existe en lots (farm_plots) |
| farm_area_ha    | —                 | no existe en lots (farm_plots) |
| blend_variety_ids | —               | no existe en PostgreSQL        |
| plant_age_years | —                 | no existe en PostgreSQL        |
| plant_type      | —                 | no existe en PostgreSQL        |

NOTA: lat/lng/farm_area_ha/blend/plant pertenecen conceptualmente a `farm_plots`.
Se sincronizan solo los campos presentes en `lots`. El resto queda local.
REVISAR CON PRODUCTO: agregar columns a lots o crear farm_plot implícito.

### cosecha_pases → cosecha_pases (nueva tabla)
Columnas: id, lot_id, created_by (=owner_id), fecha_recoleccion, hora_inicio,
hora_fin, peso_cereza_kg, num_operarios, brix_promedio, pct_madurez_visual,
tipo_proceso, peso_flotacion_kg, pct_flotacion, peso_pergamino_humedo_kg,
horas_hasta_despulpe, etapa_actual, status, notas, created_at, updated_at

### fermentation_sessions → fermentation_sessions
Mapeo directo de columnas (mismos nombres). PostgreSQL tiene campos AI protocol
(ai_protocol_*) que la app móvil no genera — se envían como null.

### drying_sessions → drying_sessions
| Drift column       | PostgreSQL column      |
|--------------------|------------------------|
| drying_method      | method                 |
| target_moisture_pct| —  (no existe en PG)   |
| final_moisture_pct | humidity_final_pct     |
| started_at         | started_at             |
| ended_at           | ended_at               |

### washing_sessions → washing_sessions (nueva tabla)
Tabla nueva. REVISAR CON PRODUCTO si los campos se alinean con el flujo.

### milling_sessions → milling_sessions (nueva tabla)
Tabla nueva. REVISAR CON PRODUCTO si los campos se alinean con el flujo.

### classification_sessions → classification_sessions (nueva tabla)
Tabla nueva. REVISAR CON PRODUCTO si los campos se alinean con el flujo.

## Patrón de sync elegido
`synced_at nullable` — igual que fermentation_readings y drying_readings.
- NULL = pendiente de sync
- DateTime = ya enviado al servidor
- UPSERT con `Prefer: resolution=ignore-duplicates` — idempotente

Se descartó `sync_queue` porque:
1. Agrega complejidad sin beneficio para el caso de uso actual (datos propios del usuario)
2. El patrón synced_at ya funciona en producción para readings
3. sync_queue no tiene owner_id ni RLS (DB-3 en AUDIT.md — deuda conocida)
