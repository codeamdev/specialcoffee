# SpecialCoffee AI — Auditoría Técnica (Vivo)

> **Fuente de verdad única.** Última actualización: 2026-05-26 — reconciliación post-sprint.
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
| 8  | Trilla            | ❌ Sin reglas, sin etapa en stepper       | B-3      | 🔴 |
| 9  | Clasificación 2   | ❌ Parte de Trilla                        | B-3      | 🔴 |
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

### B-3 — Trilla + Clasificación física: etapa sin implementar
- **Área**: Dominio + AI + UI
- **Impacto**: No se registra rendimiento de trilla (kg pergamino → kg almendra). Backlog ítem #9.
- **Regla clave**: rendimiento esperado 18–22% (estándar SCA).
- **Estado**: 🔴 Abierto (backlog ítem #9)

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

### C-2 — Fermentación: sin reglas honey/anaeróbico
- **Hallazgo**: `fermentation_rules.dart` cubre solo lavado (pH, temperatura, tiempo). No hay reglas para fermentación honey (sin agua) ni anaeróbico (presión CO₂, pH láctico < 3.8).
- **Estado**: 🟠 Deuda aceptada (backlog ítem #7)

### C-3 — `userAvgFermentationH` nunca se popula
- **Hallazgo**: `AIContext.userAvgFermentationH` se usa en reglas de fermentación para comparar con histórico del usuario, pero ningún DAO ni provider lo calcula ni lo inyecta en el contexto.
- **Estado**: 🔴 Abierto

### C-4 — Reglas de process_selection sin integrar al stepper
- **Hallazgo**: `process_selection_rules.dart` emite recomendaciones de proceso (lavado/natural) basadas en Brix, lluvia y variedad. El stepper de `lot_detail_screen.dart` no las consulta al crear el lote.
- **Estado**: 🟡 Pendiente revisión

---

## D. Deudas Técnicas — Tabla Unificada

> Fuente única. Consolidado desde ANDROID_SETUP.md, coffee_thresholds.dart, cupping_tables.dart,
> local_lots_table.dart, harvest_repository_local.dart y sesiones de auditoría.
> D-10: gap en numeración — nunca asignado.
> D-1, D-4, D-11, D-12: agrupados en Fase Final (sync PostgREST / Android).

| ID  | Categoría     | Descripción                                                         | Archivo fuente                       | Estado |
|-----|---------------|---------------------------------------------------------------------|--------------------------------------|--------|
| D-1 | Android       | Verificación completa en dispositivo Android (ver ANDROID_SETUP.md)| ANDROID_SETUP.md                    | ⚪ Fase final |
| D-2 | Agronomía     | Calibración de intervalo entre pases de cosecha por variedad/microclima | harvest_repository_local.dart:135 | 🟠 Calibrar |
| D-3 | Agronomía     | `cherryColorOptimalMin` — umbral madurez cereza (≥95%)             | coffee_thresholds.dart:17            | ✅ Cerrado (E-2, commit 3c69afc) |
| D-4 | Android       | Migración v1→v6 en dispositivo con base existente (onUpgrade encadenado)| ANDROID_SETUP.md                | ⚪ Fase final (mitigado — solo aditivas) |
| D-5 | Agronomía     | Umbrales flotación (warn 20%, crit 35%) y aprovechamiento (60%) — estimados | coffee_thresholds.dart:30–37   | 🟠 Calibrar con Cenicafé / FNC |
| D-6 | Agronomía     | Umbrales °Brix cereza (óptimo 18–24) — fuente general SCA          | coffee_thresholds.dart:8             | 🟠 Calibrar con Cenicafé Avances Técnicos |
| D-7 | Agronomía     | Retraso despulpado: warnH=6h (sin doc), critH=8h (C-1)             | coffee_thresholds.dart:42            | 🟠 Calibrar con Cenicafé |
| D-8 | Código        | Rename `hoursSinceClassification` → `hoursFromDepulpingReference` (Dart puro, sin migración SQL) | ai_context.dart, condition_evaluator.dart, depulping_rules.dart, depulping_provider.dart | ✅ Cerrado (Bloque 1) |
| D-9 | Dominio       | Catación: migrar de SCA Classic 2004 a CVA cuando FNC publique adaptación colombiana | cupping_tables.dart:4 | ⚪ Post-MVP |
| D-10| —             | Gap en numeración — nunca asignado                                  | —                                    | — |
| D-11| Android       | Decidir `applicationId` definitivo antes de publicar en Play Store  | ANDROID_SETUP.md                    | ⚪ Fase final |
| D-12| Persistencia  | Reconciliar `local_lots` vs `lots` — fuente de verdad en ítem #14  | local_lots_table.dart:7              | ⚪ Fase final |
| D-13| Agronomía     | Umbrales Lavado (waterTempC 15–30°C, waterChanges≥2, effluentPh≤5.5) — estimados, sin doc Cenicafé | coffee_thresholds.dart | 🟠 Calibrar con Cenicafé / FNC |
| D-14| Agronomía     | Umbrales secado expandidos (heatStress 35°C, highAmbHum 80%, critAmbHum 85%, turningDay 3, turningGrainHum 40%) — estimados | coffee_thresholds.dart | 🟠 Calibrar con Cenicafé / FNC |
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

### F-2 — BrewDiagnosisScreen / BrewRecipeScreen: dead-code stubs
- **Hallazgo**: ambas pantallas tienen ~17–19 líneas de stub. La funcionalidad de diagnóstico existe inline en `brew_screen.dart` (`_DiagnosisSection`). No están expuestas en el router.
- **Estado**: 🟡 Pendiente (no crítico — refactor post-MVP)

---

## G. Persistencia y Sincronización

### G-1 — Dos tablas para Lot (`local_lots` vs `lots`)
- **Hallazgo**: `local_lots` es la tabla local activa (devBypass). `lots` es la tabla legacy. El ítem #14 debe reconciliarlas. Ver D-12.
- **Estado**: ⚪ Fase final (post-MVP sync)

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

### I-1 — Variedades Cenicafé 1 y Tabí ausentes
- **Hallazgo**: el catálogo de variedades no incluye Cenicafé 1 (resistente a roya, alta producción) ni Tabí (Timor × Bourbon × Typica, alta calidad de taza).
- **Estado**: 🟡 Pendiente añadir

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
| A. Dominio         | B-3               | C-2         | C-4, D-9      | B-2, B-4      | 9 etapas IA  |
| B. Etapas          | B-3               | —           | —             | B-2, B-4      | B-1          |
| C. Reglas          | C-3               | C-2         | C-4           | —             | C-1          |
| D. Deudas técnicas | —                 | D-2,D-5,D-6,D-7,D-13,D-14 | — | D-1,D-4,D-9,D-11,D-12 | D-3, D-8, D-15, D-16 |
| E. Conflictos      | —                 | —           | —             | —             | E-1, E-2     |
| F. Preparación     | —                 | —           | F-2           | —             | F-1          |
| G. Persistencia    | —                 | —           | —             | G-1 (=D-12)   | G-2, G-3     |
| H. Seguridad       | —                 | —           | H-3           | —             | H-1, H-2, H-4, H-5, H-6, H-7 |
| I. Variedades      | —                 | —           | I-1           | —             | —            |
| J. Tests/Código    | —                 | —           | —             | —             | J-1, J-2, J-3, J-4, J-5 |
| K. UX              | —                 | —           | —             | K-1           | —            |

**Abiertos críticos (MVP)**: B-3 (Trilla/ítem#9), C-3 (userAvgFermentationH).
**Pendiente manual (seguridad)**: H-3 — purga de historial git con `git filter-repo`.

---

## Prioridad de Bloques (Windows-first, MVP-first)

| Bloque | Ítems | Descripción | Estado |
|--------|-------|-------------|--------|
| **Bloque 0** | Reconciliación | J-1 corregido, D unificado, F-1/J-2 marcados | ✅ 2026-05-26 |
| **Bloque 1** | J-3, D-8, G-2 | Fix 13 tests fallando + rename campo DepulpingDao | ✅ 2026-05-26 |
| **Bloque 2** | B-1, C-1 | Módulo Lavado (entidad + reglas + UI) + expansión reglas secado | ✅ 2026-05-26 |
| **Bloque 3** | C-3, C-4, I-1 | userAvgFermentationH, integración process_selection, variedades | ⏳ |
| **Bloque 4** | B-3 | Módulo Trilla (backlog ítem #9) | ⏳ |
| **Fase final** | D-1,D-4,D-12,D-11 | Android + sync PostgREST — no tocar hasta OK | 🔒 |
| **Auditoría Pre-Prod T1** | SEC-1…7, QUAL-1, DB-1/2, ARCH-1, TEST-1 | Primera tanda de correcciones del INFORME_AUDITORIA.md | ✅ 2026-05-27 |
| **Auditoría Pre-Prod T2** | ARCH-2/3, DEVOPS-2, DB-3, QUAL-2 | Segunda tanda de correcciones (pendiente commit) | ⏳ |

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
| 2026-05-27 | pendiente | Auditoría T1: H-3(parcial) H-4 H-5 H-6 H-7 J-4 J-5 G-3 D-15 D-16 cerrados — 227 tests ✅ |
