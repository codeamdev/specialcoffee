# SpecialCoffee AI — Auditoría Técnica (Vivo)

> **Fuente de verdad única.** Última actualización: 2026-06-05 — Bloques F (RBAC 6 roles) + G (Coffee Master, schema v14) + H (Brand Manager, schema v15).
> Sprint de referencia: Sprints 1–3 (commit `b3c1633`) + sesión de auditoría (commit `3c69afc`).
> Leyenda: ✅ Cerrado · 🔴 Abierto · 🟡 Pendiente / Mitigado · 🟠 Deuda aceptada · ⚪ Post-MVP / Fase final

---

## A. Dominio — Cobertura de Etapas Productivas

El proceso del café tiene 11 etapas. El motor IA cubre **7 de 11**.

| #  | Etapa             | Cobertura AI                              | Hallazgo | Estado |
|----|-------------------|-------------------------------------------|----------|--------|
| 1  | Cosecha           | ✅ harvest_rules (5 reglas)               | —        | ✅ |
| 2  | Clasificación     | ✅ classification_rules (3 reglas)        | —        | ✅ |
| 3  | Despulpado        | ✅ depulping_rules (2 reglas)             | —        | ✅ |
| 4  | Fermentación      | ✅ fermentation_rules (4 reglas, lavado)  | C-2      | 🟠 parcial |
| 5  | Lavado            | ✅ washing_rules (4 reglas)               | —        | ✅ |
| 6  | Reposo            | ❌ Sin etapa en stepper                   | —        | ⚪ Post-MVP |
| 7  | Secado            | ✅ drying_rules (7 reglas)               | —        | ✅ |
| 8  | Trilla            | ✅ milling_rules (2 reglas)               | B-3      | ✅ |
| 9  | Clasificación 2   | ✅ Parte de Trilla                        | B-3      | ✅ |
| 10 | Empaque           | ❌ Sin reglas, sin etapa en stepper       | —        | ⚪ Post-MVP |
| 11 | Catación          | ✅ cupping_rules                          | D-9      | 🟡 CVA pendiente |

---

## B. Etapas Faltantes

### B-1 — ✅ Lavado: etapa implementada
- **Área**: Dominio + AI + UI
- **Fix (Bloque 2, 2026-05-26)**:
  - Schema v7: `CREATE TABLE washing_sessions` (aditivo, sin ALTER/DROP). Entidad `WashingSession`, DAO `WashingDao`, repositorio `WashingLocalRepository`.
  - 4 reglas AI (`washing_rules.dart`): WASH-TEMP-HIGH-001, WASH-TEMP-LOW-001, WASH-INSUFFICIENT-CHANGES-001, WASH-EFFLUENT-PH-HIGH-001.
  - Stepper no-natural: 6 → 7 pasos; Lavado insertado entre Fermentación y Secado. Secuencia natural sin cambios (4 pasos).
  - `WashingNotifier`, `WashingScreen` con form + resultado. Umbrales en `coffee_thresholds.dart` (ver D-13).
  - Tests: `washing_rules_test.dart` + `washing_provider_test.dart`.
- **Estado**: ✅ Cerrado (Bloque 2)

### B-2 — Reposo: etapa sin implementar
- **Área**: Dominio + UI
- **Impacto**: Etapa post-lavado opcional. No hay tracking de tiempo ni condiciones.
- **Estado**: ⚪ Post-MVP

### B-3 — ✅ Trilla + Clasificación física: implementado
- **Área**: Dominio + AI + UI
- **Impacto**: Registro de rendimiento de trilla (kg pergamino → kg almendra). Backlog ítem #9.
- **Fix (Bloque 4, 2026-06-03)**:
  - Schema v10: `CREATE TABLE milling_sessions` (aditivo). Entidad `MillingSession`, DAO `MillingDao`, repositorio `MillingLocalRepository`.
  - `AIContext.millingYieldPct` añadido. `ConditionEvaluator` actualizado con `milling_yield_pct`.
  - 2 reglas IA (`milling_rules.dart`): `MILL-YIELD-LOW-001` (< 18% → critical, D-2), `MILL-YIELD-HIGH-001` (> 22% → info). Umbrales en `CoffeeThresholds`. `AllRules.all` actualizado, versión → 1.3.0.
  - Stepper no-natural: 7 → 8 pasos (Trilla entre Secado y Catación). Natural: 4 → 5 pasos.
  - `MillingNotifier`, `MillingScreen` con form + preview de rendimiento en tiempo real + resultado. Ruta `/lots/:id/milling`.
  - Tests: `milling_rules_test.dart` (9 tests) + `milling_provider_test.dart` (9 tests) = 21 tests nuevos sobre baseline de 240. Total: 261/261 ✅.
- **Estado**: ✅ Cerrado (Bloque 4)

### B-4 — Empaque: etapa sin implementar
- **Área**: Dominio + UI
- **Impacto**: No hay tracking de peso final, tipo de empaque (GrainPro, saco yute), trazabilidad.
- **Estado**: ⚪ Post-MVP

---

## C. Motor de Reglas — Calidad y Cobertura

### C-1 — ✅ Reglas de secado expandidas (3 → 7 reglas)
- **Hallazgo original**: `drying_rules.dart` tenía 3 reglas.
- **Fix (Bloque 2, 2026-05-26)**: 4 reglas nuevas añadidas (existentes intactas):
  - `DRY-HEAT-STRESS-001`: temp ambiental > 35°C → REDUCE_SUN_EXPOSURE (warning).
  - `DRY-HIGH-AMBIENT-HUMIDITY-001`: hum. ambiental > 80% + grano > 12% → MONITOR_MOLD_RISK (warning).
  - `DRY-CRITICAL-AMBIENT-HUMIDITY-001`: hum. ambiental > 85% + día ≥ 3 → SHELTER_COFFEE_IMMEDIATELY (high); supercede DRY-HIGH-AMBIENT-HUMIDITY-001.
  - `DRY-TURNING-REMINDER-001`: día ≥ 3 + grano > 40% → INCREASE_TURNING_FREQUENCY (info).
  - Umbrales en `coffee_thresholds.dart` (ver D-14). Tests en `drying_rules_expanded_test.dart`.
- **Estado**: ✅ Cerrado (Bloque 2)

### C-2 — ✅ Fermentación honey y anaeróbico implementadas
- **Hallazgo**: `fermentation_rules.dart` cubría solo lavado.
- **Fix (2026-06-03)**:
  - Honey (3 reglas): `FERM-HONEY-TEMP-HIGH-001` (> 28°C → warning), `FERM-HONEY-TIME-LONG-001` (> 96h → warning), `FERM-HONEY-ENDPOINT-001` (mucílago seco + ≥ 48h → info endpoint).
  - Anaeróbico (4 reglas): `FERM-ANAEROBIC-PH-CRITICAL-001` (pH < 3.5 → critical), `FERM-ANAEROBIC-PH-WARN-001` (pH 3.5–3.8 → high), `FERM-ANAEROBIC-TEMP-HIGH-001` (> 20°C → warning), `FERM-ANAEROBIC-TIME-MIN-001` (< 48h → info).
  - Umbrales en `CoffeeThresholds` (honey*: honeyTempHighC, honeyMaxH, honeyEndpointMinH; anaerobic*: anaerobicPhCritical, anaerobicPhWarnLow, anaerobicTempMaxC, anaerobicMinH).
  - Tests: `fermentation_honey_rules_test.dart` (9 tests) + `fermentation_anaerobic_rules_test.dart` (12 tests).
  - Total tests: **287/287** ✅
- **Estado**: ✅ Cerrado (C-2)

### C-3 — ✅ `userAvgFermentationH` — implementado
- **Hallazgo**: `AIContext.userAvgFermentationH` se usa en reglas de fermentación para comparar con histórico del usuario, pero ningún DAO ni provider lo calculaba ni lo inyectaba en el contexto.
- **Fix (Bloque 3, 2026-06-03)**: `FermentationDao.getAvgCompletedDurationH(ownerId)` (SQL AVG de sesiones completadas). Método añadido a `FermentationRepository` interface e implementado en `FermentationLocalRepository`. `FermentationNotifier.addReading()` llama `repo.getAvgCompletedDurationH()` antes de construir el `AIContext`. 2 tests nuevos en `fermentation_provider_test.dart`.
- **Estado**: ✅ Cerrado (Bloque 3)

### C-4 — ✅ Reglas de process_selection integradas al flujo de creación de lote
- **Hallazgo**: `process_selection_rules.dart` emite recomendaciones de proceso (lavado/natural) basadas en Brix, lluvia y variedad.
- **Verificación (Bloque 3, 2026-06-03)**: `lot_create_screen.dart` ya construía `AIContext(module: 'process_selection')` con todos los campos necesarios (variedad, altitud, temp, humedad, lluvia) y llamaba `engine.recommend()`. `AllRules.all` ya incluía `ProcessSelectionRules.all`. Las recomendaciones se muestran en `_RecommendationsSection`. La integración estaba completa — no se requirió código adicional.
- **Estado**: ✅ Cerrado (Bloque 3 — verificado)

---

## D. Deudas Técnicas — Tabla Unificada

> Fuente única. Consolidado desde ANDROID_SETUP.md, coffee_thresholds.dart, cupping_tables.dart,
> local_lots_table.dart, harvest_repository_local.dart y sesiones de auditoría.
> D-10: gap en numeración — nunca asignado.
> D-1, D-4, D-11, D-12: agrupados en Fase Final (sync PostgREST / Android).

| ID  | Categoría     | Descripción                                                         | Archivo fuente                       | Estado |
|-----|---------------|---------------------------------------------------------------------|--------------------------------------|--------|
| D-1 | Android       | Verificación completa en dispositivo Android (ver ANDROID_SETUP.md)| ANDROID_SETUP.md                    | ⚪ Fase final |
| D-2 | Agronomía     | Calibración de intervalo entre pases de cosecha por variedad/microclima | harvest_repository_local.dart:135 | ✅ Calibrado — Cenicafé AT No. 420 (2012): base 14 días, +3d a 1500–1800 msnm, +7d a > 1800 msnm; Geisha +2d base. Ajuste fino por microclima: deuda aceptada. |
| D-3 | Agronomía     | `cherryColorOptimalMin` — umbral madurez cereza (≥95%)             | coffee_thresholds.dart:17            | ✅ Cerrado (E-2, commit 3c69afc) |
| D-4 | Android       | Migración v1→v6 en dispositivo con base existente (onUpgrade encadenado)| ANDROID_SETUP.md                | ⚪ Fase final (mitigado — solo aditivas) |
| D-5 | Agronomía     | Umbrales flotación (warn 20%, crit 35%) y aprovechamiento (60%) — estimados | coffee_thresholds.dart:30–37   | ✅ Calibrado — Manual del Cafetero Colombiano FNC/Cenicafé, cap. Beneficio. Valores confirmados para beneficiaderos colombianos con recolección selectiva. |
| D-6 | Agronomía     | Umbrales °Brix cereza (óptimo 18–24) — fuente general SCA          | coffee_thresholds.dart:8             | ✅ Calibrado — SCA + Manual del Cafetero. Cenicafé usa % madurez visual (≥95%) como indicador primario; rango 18–24°Brix alineado con estándares SCA adoptados para café colombiano. |
| D-7 | Agronomía     | Retraso despulpado: warnH=6h (sin doc), critH=8h (C-1)             | coffee_thresholds.dart:42            | ✅ Calibrado — Manual del Cafetero Colombiano FNC/Cenicafé, 4ª ed.: "despulpar el mismo día, idealmente ≤ 6h; > 8h genera defectos organolépticos irreversibles." |
| D-8 | Código        | Rename `hoursSinceClassification` → `hoursFromDepulpingReference` (Dart puro, sin migración SQL) | ai_context.dart, condition_evaluator.dart, depulping_rules.dart, depulping_provider.dart | ✅ Cerrado (Bloque 1) |
| D-9 | Dominio       | Catación: migrar de SCA Classic 2004 a CVA cuando FNC publique adaptación colombiana | cupping_tables.dart:4 | ⚪ Post-MVP |
| D-10| —             | Gap en numeración — nunca asignado                                  | —                                    | — |
| D-11| Android       | Decidir `applicationId` definitivo antes de publicar en Play Store  | ANDROID_SETUP.md                    | ⚪ Fase final |
| D-12| Persistencia  | Reconciliar `local_lots` vs `lots` — fuente de verdad en ítem #14  | local_lots_table.dart:7              | ⚪ Fase final |
| D-13| Agronomía     | Umbrales Lavado — calibrados (2026-06-03) | coffee_thresholds.dart | ✅ Calibrado — Manual del Cafetero FNC/Cenicafé: agua fresca ≤ 25°C (washingWaterTempCMax ajustado 30→25°C), ≥ 2 cambios, pH efluente ≤ 5.5. |
| D-14| Agronomía     | Umbrales secado expandidos — calibrados (2026-06-03) | coffee_thresholds.dart | ✅ Calibrado — Manual del Cafetero FNC/Cenicafé + Puerta-Quintero (Cenicafé): 35°C agrietamiento, 80% HR secado ineficiente, 85% HR riesgo hongos, volteo desde día 3 con grano > 40%. |
| D-15| BD (PostgreSQL)| Índice faltante en `drying_sessions(lot_id)` — queries O(n) en tabla crítica | schema.sql              | ✅ Cerrado (Auditoría T1, migración 0001) |
| D-16| BD (PostgreSQL)| `db-schema-cache-ttl = 0` en producción — re-introspección en cada request | postgrest.conf          | ✅ Cerrado (Auditoría T1, ttl→300) |

---

## E. Errores de Lógica / Conflictos de Reglas

### E-1 — ✅ ConflictResolver de-dupe por acción (comportamiento correcto)
- **Hallazgo**: el resolver de-dupe por nombre de acción. Acciones distintas no colisionan — correcto por diseño.
- **Estado**: ✅ Cerrado

### E-2 — ✅ Conflicto HARVEST_NOW + STOP_GREEN_HARVEST simultáneos
- **Causa**: `cherryColorOptimalMin = 75.0` permitía cosechar con 25% verde, disparando ambas reglas simultáneamente.
- **Fix**: `cherryColorOptimalMin` → 95.0 en `coffee_thresholds.dart`. Commit `3c69afc`, 2026-05-26.
- **Estado**: ✅ Cerrado

---

## F. Módulos de Preparación (Barista)

### F-1 — ✅ Cold Brew: implementado
- **Fix aplicado** (commit `3c69afc`, 2026-05-26):
  - `brew_recipe.dart`: campo `steepHours` añadido.
  - `brew_recipe_generator.dart`: `cold_brew` en `_baseRecipes`; guard `isColdBrew` en ajustes 1,2,4,6; TDS concentrado 2.5–3.5%.
  - `brew_screen.dart`: método añadido a `_methods`; UI adapta temperatura (4°C frío) y parámetro maceración.
  - `brewing_rules.dart`: regla `BREW-COLDBREW-STEEP-001` añadida (steep 12–24h).
  - `_prettyMethod`: caso `'cold_brew' => 'Cold Brew'` añadido.
- **Estado**: ✅ Cerrado

### F-2 — ✅ BrewDiagnosisScreen / BrewRecipeScreen: MVP implementado
- **Fix** (commit `754543d`, 2026-05-27): stubs reemplazados por pantallas funcionales. `BrewRecipeScreen` muestra receta completa + botón "Iniciar extracción". `BrewDiagnosisScreen` captura TDS/yield/tiempo/notas y persiste `BrewingSession` en Drift (schema v9). Ver `docs/audit/brewing-mvp-scope.md` para decisiones de producto.
- **Estado**: ✅ Cerrado (FUNC-1)

---

## G. Persistencia y Sincronización

### G-1 — Dos tablas para Lot (`local_lots` vs `lots`)
- **Hallazgo**: `local_lots` es la tabla local activa (devBypass). `lots` es la tabla legacy. El ítem #14 debe reconciliarlas. Ver D-12.
- **Estado**: ⚪ Fase final (post-MVP sync)
- **🔴 BLOQUEANTE para activar sync**: `sync_queue` no tiene `owner_id` ni política RLS. Antes de que cualquier código de sync escriba en ella, la tabla necesita: (1) columna `owner_id TEXT NOT NULL REFERENCES users(id)`, (2) política RLS `USING (owner_id = current_user_id())`, (3) GRANTs actualizados. Esto es bloqueante — no opcional. Migración pendiente: `0003_sync_queue_owner_rls.sql`.

### G-2 — ✅ Campo `hours_since_classification` renombrado
- **Fix**: `hoursFromDepulpingReference` en ai_context + condition_evaluator + depulping_rules + depulping_provider. SQL column `hours_from_reference` ya era correcto — sin migración. Ver D-8.
- **Estado**: ✅ Cerrado (Bloque 1)

### G-3 — ✅ Logout no invalidaba providers `keepAlive` con userId capturado (ARCH-1)
- **Hallazgo**: Providers `keepAlive` (fermentation, drying, harvest, classification, depulping, cupping, washing) capturan `userId` en su construcción. En dispositivos compartidos, el usuario siguiente heredaba el contexto de la sesión anterior.
- **Fix**: `AuthNotifier.logout()` en `auth_provider.dart` invalida explícitamente los 7 providers de repositorio.
- **Estado**: ✅ Cerrado (Auditoría Pre-Producción T1, 2026-05-27)

---

## H. Seguridad y Red

### H-1 — ✅ JWT refresh implementado
- **Verificación**: `api_client.dart` tiene interceptor completo: 401 → skip rutas auth → getRefreshToken → POST `/auth/v1/refresh` → saveTokens → retry.
- **Estado**: ✅ Cerrado

### H-2 — ✅ Session persistence (currentUser) implementada
- **Verificación**: `currentUser()` usa `flutter_secure_storage` + `JwtDecoder.isExpired()` + `refresh()` si expirado. Persiste entre reinicios.
- **Estado**: ✅ Cerrado

### H-3 — 🟡 Archivos `.conf` con credenciales trackeados en git (SEC-1 — parcial)
- **Hallazgo**: `backend/postgrest.conf` y `backend/postgrest_local.conf` estaban versionados con credenciales reales (usuario postgrest_auth, JWT_SECRET).
- **Fix parcial** (Auditoría Pre-Producción, 2026-05-27): `*.conf` añadido a `.gitignore`; `backend/env.example` creado con placeholders documentados (renombrado sin punto para no quedar atrapado por `.env.*` del gitignore). Credenciales ya rotadas externamente.
- **Pendiente manual**: limpieza de historial git con `git filter-repo` (a ejecutar por el desarrollador).
- **Estado**: 🟡 Parcial — falta purga del historial git

### H-4 — ✅ Sin rate limiting en endpoints de autenticación (SEC-4)
- **Fix**: `limit_req_zone` en `nginx.conf` (5r/m, burst 10 en API) y en `specialcoffee.conf` (zonas separadas `auth` 5r/m en `/auth/login` y `/auth/register`, y `api` 30r/m en `/api/`).
- **Estado**: ✅ Cerrado (Auditoría Pre-Producción, 2026-05-27)

### H-5 — ✅ Security headers ausentes en Nginx (SEC-5)
- **Fix**: `X-Content-Type-Options`, `X-Frame-Options DENY`, `Referrer-Policy`, `Permissions-Policy` añadidos en ambos archivos Nginx. `Strict-Transport-Security` solo en `specialcoffee.conf` (producción HTTPS). `server_tokens off` en ambos.
- **Estado**: ✅ Cerrado (Auditoría Pre-Producción, 2026-05-27)

### H-6 — ✅ `setup_local.ps1` exponía contraseña en variable de entorno (SEC-6)
- **Fix**: `$env:PGPASSWORD = "posgres"` → lectura desde `.env` vía `Get-Content`. Script falla con mensaje claro si `.env` no existe.
- **Estado**: ✅ Cerrado (Auditoría Pre-Producción, 2026-05-27)

### H-7 — ✅ Sin validación de fortaleza de contraseña en registro (SEC-7)
- **Fix**: `len(password) < 8` → HTTP 400 antes del check de rol en `POST /auth/register` (`backend/auth/main.py`).
- **Estado**: ✅ Cerrado (Auditoría Pre-Producción, 2026-05-27)

---

## I. Catálogo de Variedades

### I-1 — ✅ Variedades Cenicafé 1 y Tabí añadidas
- **Hallazgo**: el catálogo de variedades no incluía Cenicafé 1 ni Tabí.
- **Fix (Bloque 3, 2026-06-03)**: Añadidas a `varieties_dao.dart:seedDefaults()` con `insertAllOnConflictUpdate` (idempotente). Cenicafé 1: sensitivity=low, scaPotential=84.0. Tabí: sensitivity=high, scaPotential=87.5. `varieties_provider.dart` cambiado para siempre llamar `seedDefaults()` sin guard `isEmpty()`, garantizando que installs existentes reciban las nuevas variedades en el siguiente arranque. Sin bump de schema (solo datos semilla).
- **Estado**: ✅ Cerrado (Bloque 3)

---

## J. Calidad de Código y Tests

### J-1 — ✅ Tests existen y pasan
- **Corrección**: J-1 estaba mal documentado. `test/` tiene 8 archivos, 1942 líneas.
- **Estado post-Bloque 1**: **168/168** (2026-05-26). **Estado post-Bloque 2**: **213/213**. **Estado post-Auditoría T1**: **227/227** (2026-05-27). Ver J-3, J-4, J-5.
- **Estado**: ✅ Cerrado (en curso — baseline actualizado)

### J-2 — ✅ build_runner artefactos regenerados
- **Fix**: `dart run build_runner build` ejecutado en sesión 2026-05-26. `brew_recipe.freezed.dart` actualizado con `steepHours`.
- **Estado**: ✅ Cerrado (commit `3c69afc`)

### J-3 — ✅ 13 tests fallando — resueltos
- **Diagnóstico** (todos eran andamiaje de test — cero bugs de producción):
  - **Grupo 1** (`fermentation_provider_test.dart`, 12 tests): `ServicesBinding.instance` disparado por LazyDatabase/path_provider escapaba el `catch (_)` en zona de test Flutter. Fix: `_FakeRepo implements FermentationRepository` (in-memory, sin DB) + `fermentationLocalRepoProvider` override + `lotByIdProvider` override + `TestWidgetsFlutterBinding.ensureInitialized()`.
  - **Grupo 2** (`widget_test.dart`, 1 test): `_loadPersistedSession()` registraba `Future()` en zona FakeAsync; timer pendiente al final del test fallaba `_verifyInvariants`. Fix: envolver en `tester.runAsync()` para salir de la zona fake.
- **Estado**: ✅ Cerrado (Bloque 1)

### J-4 — ✅ 34 `catch (_) {}` silenciosos en providers críticos (QUAL-1)
- **Hallazgo**: `drying_provider.dart`, `fermentation_provider.dart`, `harvest_provider.dart` tenían 34 bloques catch que descartaban silenciosamente errores de BD, sesión y AI sin informar al usuario.
- **Fix**: Todos reemplazados por `catch (e, st)` con `if (kDebugMode) debugPrint(...)` + `state.copyWith(error: () => '...')`. Los State añadieron campo `error: String?`; `copyWith` usa el patrón `String? Function()?` para preservar errores existentes. `_loadPersistedSession` solo loguea (startup async — no puede actualizar state post-disposal).
- **Estado**: ✅ Cerrado (Auditoría Pre-Producción T1, 2026-05-27)

### J-5 — ✅ Sin tests para DryingProvider — 259 líneas sin cobertura (TEST-1)
- **Fix**: `test/presentation/providers/drying_provider_test.dart` creado (13 tests, 5 grupos): estado inicial, addReading happy path, error de persistencia (createSession + persist), error de AI, changeDryingMethod, reset.
- **Estado**: ✅ Cerrado (Auditoría Pre-Producción T1, 2026-05-27)

---

## K. UX / Flujos de Pantalla

### K-1 — Dashboard no diferencia procesador de barista
- **Hallazgo**: `dashboard_screen.dart` aplica role-aware solo en `_QuickActions`. El contenido de lotes recientes es idéntico para todos los roles.
- **Estado**: ⚪ Post-MVP

---

## Resumen de Estado

| Área | 🔴 Abiertos | 🟠 Deuda | 🟡 Pendientes | ⚪ Post-MVP/Final | ✅ Cerrados |
|------|------------|----------|--------------|------------------|------------|
| A. Dominio         | —                 | C-2         | D-9           | B-2, B-4      | 9 etapas IA + B-3 |
| B. Etapas          | —                 | —           | —             | B-2, B-4      | B-1, B-3     |
| C. Reglas          | —                 | —           | —             | —             | C-1, C-2, C-3, C-4 |
| D. Deudas técnicas | —                 | — | — | D-1,D-4,D-9,D-11,D-12 | D-2,D-3,D-5,D-6,D-7,D-8,D-13,D-14,D-15,D-16 |
| E. Conflictos      | —                 | —           | —             | —             | E-1, E-2     |
| F. Preparación     | —                 | —           | —             | —             | F-1, F-2     |
| G. Persistencia    | —                 | —           | —             | G-1 (=D-12)   | G-2, G-3     |
| H. Seguridad       | —                 | —           | H-3           | —             | H-1, H-2, H-4, H-5, H-6, H-7 |
| I. Variedades      | —                 | —           | —             | —             | I-1          |
| J. Tests/Código    | —                 | —           | —             | —             | J-1, J-2, J-3, J-4, J-5 |
| K. UX              | —                 | —           | —             | K-1           | —            |

**Abiertos críticos (MVP)**: ninguno. **Tests finales: 352/352 ✅ · Schema v15 · AllRules v1.3.0 · Motor de reglas: 12 módulos, 8 procesos cubiertos (brewing rules +14).**
**Calibración umbrales**: ✅ D-2,D-5,D-6,D-7,D-13,D-14 cerrados con fuentes Cenicafé/FNC (2026-06-03). `washingWaterTempCMax` ajustado 30→25°C; intervalos cosecha calibrados a AT No. 420. Bloque G: umbrales `physical_analyses` documentados (SCA Defect Handbook, ISO 6673) y `roast_profiles` (Scott Rao, SCA Roast Color Classification).
**Pendiente manual (seguridad)**: H-3 — purga de historial git con `git filter-repo`.

---

## Prioridad de Bloques (Windows-first, MVP-first)

| Bloque | Ítems | Descripción | Estado |
|--------|-------|-------------|--------|
| **Bloque 0** | Reconciliación | J-1 corregido, D unificado, F-1/J-2 marcados | ✅ 2026-05-26 |
| **Bloque 1** | J-3, D-8, G-2 | Fix 13 tests fallando + rename campo DepulpingDao | ✅ 2026-05-26 |
| **Bloque 2** | B-1, C-1 | Módulo Lavado (entidad + reglas + UI) + expansión reglas secado | ✅ 2026-05-26 |
| **Bloque 3** | C-3, C-4, I-1 | userAvgFermentationH, integración process_selection, variedades | ✅ 2026-06-03 |
| **Bloque 4** | B-3 | Módulo Trilla (backlog ítem #9) | ✅ 2026-06-03 |
| **Bloque 5b** | OneSignal + FCM token | `POST /users/fcm-token`, migración 0004_fcm_token.sql, `onesignal_flutter ^5.2.0`, `OnesignalService`, `FcmService`, integración en `auth_provider.dart` + `auth_repository_impl.dart`, docker-compose vars desde .env, docs/build actualizados | ✅ 2026-06-04 |
| **Bloque A** | Admin | Route guard /admin (GoRouter), LearningModeIndicator todos los roles, LearningCard Cosecha+Fermentación | ✅ 2026-06-04 (a299776) |
| **Bloque B** | Schema v12 | coffee_references + water_profiles + brew_session_details (aditivo, sin ALTER/DROP) + CoffeeReferenceForm | ✅ 2026-06-04 (847e7ad) |
| **Bloque C** | Barista | BaristaHomeScreen + BrewSessionWizard + CoffeeReferenceForm | ✅ 2026-06-04 (317f288) |
| **Bloque D** | Brewing rules | 14 reglas nuevas (freshness/ratio/extraction/water) + AIContext waterPh/waterTds + 37 tests — ConflictResolver demo — 346/346 ✅ | ✅ 2026-06-04 (1b9ad02) |
| **Bloque E** | Workflow | lot_stage_log (schema v13), WorkflowConfig, WorkflowNotifier, WorkflowHubScreen, stage timers, ProcessCompletionAnalyzer, BatchInsightsCard — 352/352 ✅ | ✅ 2026-06-05 (b60bc8d…ffdc732) |
| **Bloque F** | RBAC | UserRole 6 valores (producer/coffeeMaster/brandManager/producerIntegral/barista/admin) + roleFromString() backward-compat + guards router + dashboard/shell/onboarding — 352/352 ✅ | ✅ 2026-06-05 (6f5c04c) |
| **Bloque G** | Coffee Master (v14) | physical_analyses (densidad/humedad/Aw/defectos SCA), roast_profiles (pesos/merma/DTR/Agtron), cupping_evaluations (scoresheet SCA 12 atributos) + CoffeeMasterLotScreen — 352/352 ✅ | ✅ 2026-06-05 (26e082d) |
| **Bloque H** | Brand Manager (v15) | green_inventory + roasted_inventory + commercial_products + lot_certifications + BrandManagerScreen + LotCertificationsCard — 352/352 ✅ | ✅ 2026-06-05 (26e082d) |
| **Fase final** | D-1,D-4,D-12,D-11 | Android + sync PostgREST — no tocar hasta OK | 🔒 |
| **Auditoría Pre-Prod T1** | SEC-1…7, QUAL-1, DB-1/2, ARCH-1, TEST-1 | Primera tanda de correcciones del INFORME_AUDITORIA.md | ✅ 2026-05-27 |
| **Auditoría Pre-Prod T2** | ARCH-2/3, DEVOPS-2, DB-3, QUAL-2 | Segunda tanda de correcciones | ✅ 2026-05-27 (f6f757b) |
| **Auditoría Pre-Prod T3** | SEC-2/3, DEVOPS-1, FUNC-1 | Dominio producción + Brewing MVP | ✅ 2026-05-27 (9187aab, 754543d) |
| **Bloque 6** | userAvgSca, lastLotFermentationH, userPreferredTdsMin/Max, batch_insights, LotSummaryNotifier, BrewingHistoryProvider | Datos históricos → personalización IA | ✅ 2026-06-03 |
| **Bloque 8** | dashboard_screen.dart 3 vistas: CAFICULTOR/PROCESADOR/BARISTA | Dashboard diferenciado por rol | ✅ 2026-06-03 |
| **Bloque 9** | Inter/DM Serif Display/JetBrains Mono en assets/fonts/, qr_flutter, pdf/printing — QR en LotDetail, PDF export | Fuentes + QR + PDF | ✅ 2026-06-03 |
| **Bloque 10** | coffee_thresholds.dart — fuentes documentadas para D-2, D-5, D-6, D-7, D-13, D-14 | Calibración de umbrales | ✅ 2026-06-03 |

---

## L. Mejoras Sugeridas (no bloqueantes)

> Migradas desde INFORME_AUDITORIA.md al consolidar en un único archivo de auditoría (2026-06-02).

| ID | Descripción | Área | Estado |
|----|-------------|------|--------|
| MEJ-1 | Patrón `Result<T, E>` en lugar de exceptions — mejor manejo en UI | Arquitectura | ⚪ Post-MVP |
| MEJ-2 | i18n / intl — soporte multiidioma (estructura importada pero no usada) | UX | ⚪ Post-MVP |
| MEJ-3 | Implementar sync_queue offline → PostgREST para fase final | Persistencia | ⚪ Fase final |
| MEJ-4 | Tests de widget para LotDetailScreen y FermentationScreen | QA | ⚪ Post-MVP |
| MEJ-5 | Benchmark real del RuleEngine (promete `< 5ms`, sin prueba adjunta) | Performance | ⚪ Post-MVP |
| MEJ-6 | Soft delete en todas las entidades, no solo Lot | Dominio | ⚪ Post-MVP |
| MEJ-7 | Validar rule_id únicos en AllRules al cargar (assert en debug) | Motor de reglas | ⚪ Post-MVP |
| MEJ-8 | `client_max_body_size 1M` en nginx.conf de desarrollo | DevOps | ⚪ Post-MVP |
| MEJ-9 | `PGRST_LOG_LEVEL: "warn"` en docker-compose (evitar logs con datos en info) | DevOps | ⚪ Post-MVP |
| MEJ-10 | Agregar `.env.example` al repo como plantilla con placeholders | DevOps | ⚪ Post-MVP |

---

## Historial de Cambios

| Fecha      | Commit    | Cambio                                                                 |
|------------|-----------|------------------------------------------------------------------------|
| 2026-05-26 | —         | Auditoría inicial — 11 hallazgos documentados                          |
| 2026-05-26 | 3c69afc   | E-2 cerrado — cherryColorOptimalMin 75→95 (coffee_thresholds)          |
| 2026-05-26 | 3c69afc   | F-1 cerrado — Cold Brew implementado (recipe + UI + regla)             |
| 2026-05-26 | 3c69afc   | H-1, H-2 cerrados — JWT refresh y session persistence verificados      |
| 2026-05-26 | 3c69afc   | J-2 cerrado — build_runner ejecutado, brew_recipe.freezed.dart OK      |
| 2026-05-26 | 43b53c7   | Reconciliación: J-1 corregido (tests existen, 155/168 pasan), D unificado (D-1..D-12), tabla de bloques añadida |
| 2026-05-26 | 7dff2c3   | J-3 cerrado — 168/168 tests verdes (_FakeRepo, tester.runAsync, ensureInitialized) |
| 2026-05-26 | 7dff2c3   | D-8/G-2 cerrados — rename hoursSinceClassification→hoursFromDepulpingReference (Dart puro, sin migración SQL) |
| 2026-05-26 | —         | B-1 cerrado — módulo Lavado completo: schema v7, 4 reglas AI, stepper 7 pasos, WashingScreen, 8 tests |
| 2026-05-26 | —         | C-1 cerrado — drying_rules expandido: 3 → 7 reglas, DRY-CRITICAL supercede DRY-HIGH, 11 tests regresión |
| 2026-05-26 | ef82a51   | B-1/C-1 cerrados — módulo Lavado + expansión Secado + 213 tests ✅      |
| 2026-05-26 | —         | D-13/D-14 abiertos — umbrales lavado y secado nuevo: deuda de calibración Cenicafé/FNC |
| 2026-05-27 | —         | INFORME_AUDITORIA.md generado — 9 CRÍTICO, 5 ALTO, 6 MEDIO, 4 BAJO     |
| 2026-05-27 | e7b4b21   | Auditoría T1: H-3(parcial) H-4 H-5 H-6 H-7 J-4 J-5 G-3 D-15 D-16 cerrados — 227 tests ✅ |
| 2026-05-27 | f6f757b   | Auditoría T2: ARCH-2 variedades Drift v8, ARCH-3 ConflictResolver, DEVOPS-2 healthchecks, DB-3 GRANTs, QUAL-2 linters — 229 tests ✅ |
| 2026-05-27 | 9187aab   | Auditoría T3a: SEC-2/3 CORS specialcoffee.app, DEVOPS-1 dart-define, docs/audit/git-history-cleanup.md |
| 2026-05-27 | 754543d   | Auditoría T3b: FUNC-1 BrewRecipeScreen + BrewDiagnosisScreen MVP, schema v9, 238 tests ✅ |
| 2026-06-02 | —         | INFORME_AUDITORIA.md eliminado — MEJ-1..MEJ-10 migrados a sección L. Un solo archivo de auditoría. |
| 2026-06-03 | —         | Bloque 3: C-3 userAvgFermentationH, C-4 verificado, I-1 Cenicafé 1 + Tabí — 240 tests ✅ |
| 2026-06-03 | —         | Bloque 4: B-3 Trilla completa, schema v10, milling_rules, stepper 8 pasos — 261 tests ✅ |
| 2026-06-03 | —         | Bloque 6: lastLotFermentationH, batch_insights (v11), LotSummaryNotifier, BrewingHistoryProvider, recentBrewingSessionsProvider — 261 tests ✅ |
| 2026-06-03 | —         | Bloque 8: dashboard 3 vistas por rol (CAFICULTOR/PROCESADOR/BARISTA) con semáforos, alertas y streaks |
| 2026-06-03 | —         | Bloque 9: Inter/DM Serif/JetBrains Mono descargados, qr_flutter + pdf/printing añadidos, QR y PDF en LotDetailScreen |
| 2026-06-03 | —         | Bloque 10: coffee_thresholds.dart — fuentes documentadas y TODOs de calibración para todos los umbrales |
| 2026-06-03 | —         | C-2: 7 reglas honey/anaeróbico, 21 tests nuevos — 287/287 ✅ criterio MVP ≥270 cumplido |
| 2026-06-03 | —         | PASO 1 sync: SyncService + SyncDataSource + DAOs unsynced/mark + integración fermentación/secado — 296/296 ✅ |
| 2026-06-03 | —         | PASO 2 backend: migración 0003_onesignal_player_id.sql + PATCH /auth/device + registerDevice() en Flutter |
| 2026-06-03 | —         | PASO 3: backend/migrations/003_alert_triggers.sql — triggers fn_check_fermentation_alerts + fn_check_drying_alerts + índice parcial pending |
| 2026-06-03 | —         | PASO 4: backend/auth/notifications.py — dispatch_pending_alerts + notification_loop + lifespan integrado + httpx en requirements — 296/296 ✅ |
| 2026-06-04 | —         | Bloque 5b: POST /users/fcm-token, migración 0004_fcm_token.sql, onesignal_flutter ^5.2.0, OnesignalService + FcmService, integración auth_provider + auth_repository_impl, docker-compose vars ONESIGNAL_* desde .env, docs/build/android-release-checklist.md + dart-define-guide.md actualizados — 296/296 ✅ |
| 2026-06-04 | a299776   | Bloque A: route guard /admin, LearningModeIndicator todos roles, LearningCard Cosecha + Fermentación |
| 2026-06-04 | 847e7ad   | Bloque B: schema v12 — coffee_references + water_profiles + brew_session_details (CREATE TABLE aditivo) |
| 2026-06-04 | 317f288   | Bloque C: BaristaHomeScreen + BrewSessionWizard (multi-step) + CoffeeReferenceForm |
| 2026-06-04 | 1b9ad02   | Bloque D: 14 reglas brewing (freshness/ratio/extraction/water) + AIContext waterPh/waterTds + 37 tests — ConflictResolver demo — 346/346 ✅ |
| 2026-06-05 | b60bc8d   | Bloque E1: lot_stage_log table (schema v13), WorkflowConfig, dominio + DAO + repo |
| 2026-06-05 | 42fdab7   | Bloque E2: WorkflowNotifier + WorkflowHubScreen + ruta /lots/:id/workflow + 6 tests |
| 2026-06-05 | 057b848   | Bloque E3: scheduleStageTimers + cancelStageTimers en NotificationService (IDs 6000–7999) |
| 2026-06-05 | ffdc732   | Bloque E4: ProcessCompletionAnalyzer + BatchInsightsCard en LotDetailScreen + cupping trigger — 352/352 ✅ |
