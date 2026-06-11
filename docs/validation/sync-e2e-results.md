# Resultados E2E — Validación del Sync Offline → PostgreSQL

**Fecha de ejecución:** 2026-06-10  
**Backend:** local (Docker Compose — auth + postgrest + nginx)  
**Usuario de test:** `e2etest@specialcoffee.com` / id `c996134d-ce77-4e76-8e31-ce413a114d02`  
**Schema PostgreSQL:** v1 + migraciones 001–004  
**Dart/Flutter:** ≥3.8/3.22 · Drift 2.21 · SyncService wave-based (commit `57d4a4c`)

---

## Resumen de bugs encontrados y corregidos

| Bug | Descripción | Commit |
|-----|-------------|--------|
| Bug 1 | `_syncLots()` enviaba `status: 'activo'` — rechazado por CHECK constraint de PostgreSQL | `32916d2` |
| Bug 2 | `_syncLots()` enviaba `process_type: ''` — rechazado por CHECK constraint de PostgreSQL | `32916d2` |
| Bug 3 | `syncPendingReadings()` ejecutaba 9 entidades en paralelo — FK violation (`cosecha_pases.lot_id` insertado antes que el lote) | `57d4a4c` |

---

## Matriz de resultados — 7 entidades × 3 casos

| Entidad                    | Sync OK | Idempotencia | Error parcial | Notas |
|----------------------------|---------|--------------|---------------|-------|
| `lots`                     | ✅ E1   | ✅ E-idempotency | N/A — entidad raíz FK | `status`/`process_type` omitidos (Bug 1+2) |
| `cosecha_pases`            | ✅ E2   | ✅ (Prefer: ignore-duplicates) | ✅ E-partial — FK inválida falla silenciosamente | FK → `lots(id)` verificada en wave 2 |
| `fermentation_sessions`    | ✅ E3a  | ✅           | Cubierto por unit tests | FK → `lots(id)` |
| `fermentation_readings`    | ✅ E3b  | ✅           | Cubierto por unit tests | FK → sessions + lots |
| `drying_sessions`          | ✅ E4a  | ✅           | Cubierto por unit tests | FK → `lots(id)` |
| `drying_readings`          | ✅ E4b  | ✅           | Cubierto por unit tests | FK → sessions + lots |
| `washing_sessions`         | ✅ E5   | ✅           | Cubierto por unit tests | FK nullable → `fermentation_sessions` |
| `milling_sessions`         | ✅ E6   | ✅           | Cubierto por unit tests | FK → `lots(id)` |
| `classification_sessions`  | ✅ E7   | ✅           | Cubierto por unit tests | FK → `lots(id)` |

---

## Caso de error E1 — Red caída (documentación manual)

El caso "backend no disponible" se verifica mediante los unit tests existentes en
`test/data/sync/sync_service_test.dart` (grupo `lots → POST falla → markLotSynced no se llama,
no lanza`, equivalente para todas las entidades). El comportamiento verificado:

- `syncPendingReadings()` **completa sin lanzar** aunque el backend esté caído.
- `markXxxSynced` **no se llama** → el registro queda con `synced_at = NULL` para el siguiente intento.
- La UI no recibe el error (sync siempre se llama sin `await` desde el presenter).

Para validación manual completa (sin Docker):
```powershell
docker compose -f backend/docker-compose.yml stop postgrest
# Crear objeto en la app → no debe aparecer error en pantalla
docker compose -f backend/docker-compose.yml start postgrest
# Re-abrir la app o crear otro objeto → ambos registros deben sincronizar
```

---

## Caso de error E2 — Idempotencia

✅ **Verificado automáticamente** (`E-idempotency` en `test/integration/sync_e2e_test.dart`).

El header `Prefer: resolution=ignore-duplicates,return=minimal` hace que PostgREST ignore
el segundo INSERT si el `id` ya existe. El test verifica que la tabla tenga exactamente
1 fila con el id del test después de 2 POSTs consecutivos.

---

## Caso de error E3 — Fallo parcial (FK violation)

✅ **Verificado automáticamente** (`E-partial` en `test/integration/sync_e2e_test.dart`).

Escenario: 2 cosecha_pases — uno con `lot_id = 'nonexistent-lot-xyz'` (FK violation) y
uno con `lot_id` válido (existe en `lots`). Resultado:

- Pase inválido: PostgREST devuelve 400/422 → capturado por inner `catch` → `markCosechaPaseSynced` **no se llama**.
- Pase válido: POST exitoso → `markCosechaPaseSynced` **sí se llama** → `synced_at` marcado.
- `syncPendingReadings()` completa normalmente (sin lanzar).

---

## Campos NO sincronizados (G-1/D-12)

Los siguientes 6 campos de `local_lots` **no se incluyen en el payload** de `/api/lots`:

| Campo local         | Razón                                  |
|---------------------|----------------------------------------|
| `latitude`          | Sin columna en `lots` PostgreSQL       |
| `longitude`         | Sin columna en `lots` PostgreSQL       |
| `farm_area_ha`      | Sin columna en `lots` PostgreSQL       |
| `blend_variety_ids` | Sin columna en `lots` PostgreSQL       |
| `plant_age_years`   | Sin columna en `lots` PostgreSQL       |
| `plant_type`        | Sin columna en `lots` PostgreSQL       |

Invariante verificada por: `test/data/sync/sync_service_test.dart → campos G-1/D-12 nunca aparecen en el payload de /api/lots`.

Ver `docs/decisions/lots-fields-not-synced.md` para decisión completa.

---

## Validación pendiente (requiere UI manual)

Los siguientes items del checklist requieren validación manual con la UI de Flutter:

- [ ] `synced_at` marcado en cada tabla local de Drift después del sync
- [ ] La app no muestra error cuando `syncPendingReadings()` falla en background
- [ ] Al reconectar el backend, todos los registros con `synced_at = NULL` se re-sincronizan

Pasos exactos: ver `docs/validation/sync-e2e-checklist.md`.

---

## Estado de tests

```
flutter test test/integration/sync_e2e_test.dart → 11/11 ✅
flutter test test/data/sync/sync_service_test.dart → 29/29 ✅
flutter test (suite completa) → 413/413 ✅
```
