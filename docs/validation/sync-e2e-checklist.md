# Checklist E2E — Validación del Sync Offline → PostgreSQL

**Fecha de creación:** 2026-06-10  
**Revisión:** v1.0

---

## Arranque

```powershell
# 1. Backend
cd backend && docker compose up -d

# 2. App (modo desarrollo local)
flutter run -d windows --dart-define=DEV_MODE=true
```

---

## Pre-checklist: servicios en pie

Verificar antes de cualquier prueba E2E:

```powershell
docker compose ps
# Todos deben aparecer como "healthy" o "Up":
#   specialcoffee-db-1         Up (postgres)
#   specialcoffee-auth-1       Up (fastapi)
#   specialcoffee-postgrest-1  Up (postgrest)
#   specialcoffee-nginx-1      Up (nginx)
```

```powershell
# Nginx responde
curl http://127.0.0.1/auth/health
# Esperado: {"status":"ok"}

# PostgREST responde
curl http://127.0.0.1/api/
# Esperado: JSON con "info" y "paths"
```

- [ ] postgres healthy
- [ ] auth (FastAPI) healthy
- [ ] postgrest healthy
- [ ] nginx proxy 127.0.0.1:80 responde

---

## Entidad 1: Lotes (`local_lots → lots`)

### Pasos UI
1. Iniciar sesión con `farmer@x.com` / contraseña de prueba
2. Navegar a **Lotes → Nuevo Lote**
3. Seleccionar variedad, ingresar altitud y región
4. Guardar → confirmar que redirige a detalle del lote
5. Esperar 3 s (el sync corre en background al guardar)

### Verificación SQL
```sql
SELECT id, owner_id, variety_name, altitude_masl, region, created_at
FROM lots
ORDER BY created_at DESC
LIMIT 3;
```
**Esperado:** la fila del lote recién creado aparece con `owner_id` = UUID del farmer.

### Verificación local (Drift)
```sql
-- Conectar con sqlite3 o DB Browser al archivo special_coffee.db
SELECT id, synced_at FROM local_lots ORDER BY created_at DESC LIMIT 3;
```
**Esperado:** `synced_at` ≠ NULL (timestamp UTC).

- [ ] Lote visible en PostgreSQL
- [ ] `synced_at` marcado en local_lots

---

## Entidad 2: Pases de cosecha (`cosecha_pases → cosecha_pases`)

### Pre-requisito
Ejecutar migración 004 si no se hizo:
```powershell
psql -U postgres -d specialcoffee -f backend/migrations/004_cosecha_sync_tables.sql
```

### Pasos UI
1. Desde el detalle de un lote, crear un **Nuevo Pase de Cosecha**
2. Ingresar peso de cereza ≥ 1 kg, seleccionar proceso
3. Guardar y confirmar que aparece en la lista de pases

### Verificación SQL
```sql
SELECT id, lot_id, owner_id, peso_cereza_kg, etapa_actual, status
FROM cosecha_pases
ORDER BY created_at DESC
LIMIT 3;
```
**Esperado:** fila presente con `owner_id` correcto, `etapa_actual = 'clasificacion'`.

- [ ] Pase visible en PostgreSQL
- [ ] `synced_at` marcado en local `cosecha_pases`

---

## Entidad 3: Sesiones de fermentación (`fermentation_sessions → fermentation_sessions`)

### Pasos UI
1. Desde un pase en etapa `fermentacion`, iniciar sesión de fermentación
2. Guardar parámetros (proceso, hora inicio)
3. Registrar al menos una lectura de pH y temperatura

### Verificación SQL
```sql
SELECT id, lot_id, owner_id, process_type, started_at, ph_initial
FROM fermentation_sessions
ORDER BY created_at DESC
LIMIT 3;
```

```sql
SELECT id, session_id, ph_value, mucilago_temp_c, recorded_at
FROM fermentation_readings
ORDER BY recorded_at DESC
LIMIT 5;
```
**Esperado:** sesión y lecturas visibles; `ai_protocol_*` columnas pueden ser NULL (no enviadas por la app móvil).

- [ ] Sesión de fermentación en PostgreSQL
- [ ] Lecturas de fermentación en PostgreSQL
- [ ] `synced_at` marcados en tablas locales

---

## Entidad 4: Sesiones de secado (`drying_sessions → drying_sessions`)

### Pasos UI
1. Desde un pase en etapa `secado`, iniciar secado
2. Seleccionar método (solar/shade/mechanical)
3. Registrar lecturas de humedad y temperatura
4. Finalizar secado con humedad objetivo

### Verificación SQL
```sql
SELECT id, lot_id, owner_id, method, started_at, ended_at, humidity_final_pct
FROM drying_sessions
ORDER BY created_at DESC
LIMIT 3;
```

```sql
SELECT id, session_id, moisture_pct, ambient_temp_c, recorded_at
FROM drying_readings
ORDER BY recorded_at DESC
LIMIT 5;
```
**Nota:** columna local `drying_method` → PostgreSQL `method`; `final_moisture_pct` → `humidity_final_pct`.

- [ ] Sesión de secado en PostgreSQL
- [ ] Lecturas de secado en PostgreSQL

---

## Entidad 5: Sesiones de lavado (`washing_sessions → washing_sessions`)

### Pre-requisito
Migración 004 ejecutada (tabla `washing_sessions` creada).

### Pasos UI
1. Desde un pase en etapa `lavado`, registrar sesión de lavado
2. Ingresar temperatura del agua, cambios de agua, pH final y duración
3. Guardar

### Verificación SQL
```sql
SELECT id, lot_id, owner_id, water_temp_c, water_changes, effluent_ph_final, duration_h, washed_at
FROM washing_sessions
ORDER BY created_at DESC
LIMIT 3;
```

- [ ] Sesión de lavado en PostgreSQL
- [ ] REVISAR CON PRODUCTO: validar campos contra flujo SCA real

---

## Entidad 6: Sesiones de trilla (`milling_sessions → milling_sessions`)

### Pre-requisito
Migración 004 ejecutada.

### Pasos UI
1. Desde un pase en etapa `trilla`, registrar sesión de trilla
2. Ingresar kg pergamino entrada, kg café verde salida
3. Guardar

### Verificación SQL
```sql
SELECT id, lot_id, owner_id, input_kg_parchment, output_kg_green, yield_pct
FROM milling_sessions
ORDER BY created_at DESC
LIMIT 3;
```

- [ ] Sesión de trilla en PostgreSQL
- [ ] REVISAR CON PRODUCTO: validar campos contra flujo real

---

## Entidad 7: Sesiones de clasificación (`classification_sessions → classification_sessions`)

### Pre-requisito
Migración 004 ejecutada.

### Pasos UI
1. Desde la pantalla de clasificación, registrar sesión
2. Ingresar kg entrada, kg flotantes, kg descarte manual
3. Guardar

### Verificación SQL
```sql
SELECT id, lot_id, owner_id, kg_entrada, kg_flotantes, kg_descarte_manual, classified_at
FROM classification_sessions
ORDER BY created_at DESC
LIMIT 3;
```

- [ ] Sesión de clasificación en PostgreSQL
- [ ] REVISAR CON PRODUCTO: validar campos contra flujo SCA real

---

## Casos de error

### E1: Sync con red caída

1. Detener PostgREST: `docker compose stop postgrest`
2. Crear un lote nuevo en la app
3. Verificar que la app no muestra error (sync falla silenciosamente en background)
4. Volver a levantar: `docker compose start postgrest`
5. Crear otro objeto o reiniciar la app (el sync reintenta al llamar `syncPendingReadings`)
6. Verificar que **ambos** registros llegan a PostgreSQL

**Esperado:** La app opera offline sin bloquear al usuario. Al reconectarse, todos los `synced_at = NULL` se procesan.

- [ ] App no muestra error con backend caído
- [ ] Al reconectar, todos los registros pendientes se sincronizan

### E2: Sync duplicado (idempotencia)

1. Crear un lote y esperar a que se sincronice (`synced_at` ≠ NULL)
2. Forzar `synced_at = NULL` directamente en SQLite local:
   ```sql
   UPDATE local_lots SET synced_at = NULL WHERE id = '<lot-id>';
   ```
3. Triggear sync nuevamente (reiniciar app o crear otro objeto)

**Esperado:** PostgREST retorna 200 con `Prefer: resolution=ignore-duplicates` — la fila no se duplica en PostgreSQL. `synced_at` se vuelve a marcar en local.

- [ ] Sin duplicados en PostgreSQL
- [ ] `synced_at` re-marcado en local

### E3: Sync parcial (error en un objeto)

1. Insertar manualmente un registro inválido en `local_lots` con `synced_at = NULL` y `lot_id` que no existe en PostgreSQL (FK violation)
2. Crear también un lote válido
3. Triggear sync

**Esperado:** El registro inválido falla silenciosamente (error capturado en `catch`), el lote válido sí se sincroniza. Verificar que `synced_at` solo se marca en el válido.

- [ ] Fallo de un objeto no bloquea el sync de los demás
- [ ] Solo el objeto válido tiene `synced_at` marcado

---

## Notas finales

- Todos los endpoints nuevos (`/api/cosecha_pases`, `/api/washing_sessions`, `/api/milling_sessions`, `/api/classification_sessions`) requieren token `Bearer` — PostgREST aplica RLS con `owner_id = current_user_id()`.
- Los campos `latitude`, `longitude`, `farm_area_ha`, `blend_variety_ids`, `plant_age_years`, `plant_type` **no se sincronizan** con `lots` (ver `docs/decisions/lots-fields-not-synced.md`).
- Si `ApiConfig.devBypass = true`, el sync está deshabilitado completamente — asegurarse de que sea `false` en la build de prueba.
