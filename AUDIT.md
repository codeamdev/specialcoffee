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
| 5  | Lavado            | ❌ Sin reglas, sin etapa en stepper       | B-1      | 🔴 |
| 6  | Reposo            | ❌ Sin etapa en stepper                   | —        | ⚪ Post-MVP |
| 7  | Secado            | ✅ drying_rules (3 reglas)               | C-1      | 🟡 sparse |
| 8  | Trilla            | ❌ Sin reglas, sin etapa en stepper       | B-3      | 🔴 |
| 9  | Clasificación 2   | ❌ Parte de Trilla                        | B-3      | 🔴 |
| 10 | Empaque           | ❌ Sin reglas, sin etapa en stepper       | —        | ⚪ Post-MVP |
| 11 | Catación          | ✅ cupping_rules                          | D-9      | 🟡 CVA pendiente |

---

## B. Etapas Faltantes

### B-1 — Lavado: etapa sin implementar
- **Área**: Dominio + AI + UI
- **Impacto**: El flujo lavado salta de Fermentación → Secado sin registrar el lavado del grano.
- **Reglas mínimas**: tiempo de lavado, temperatura del agua, número de cambios de agua, pH efluente.
- **Prioridad**: Alta — bloquea flujo no-natural completo (MVP).
- **Estado**: 🔴 Abierto

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

### C-1 — Reglas de secado escasas (3 reglas)
- **Hallazgo**: `drying_rules.dart` tiene 3 reglas. Faltan: temperatura ambiental > 35°C, humedad relativa del aire, control de volteo (días), riesgo de sobre-secado (< 10% humedad del grano).
- **Estado**: 🟡 Pendiente expansión

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
| D-8 | Código        | Campo `hours_since_classification` pendiente de renombrar en DepulpingDao | depulping_dao.dart             | 🟡 Pendiente rename |
| D-9 | Dominio       | Catación: migrar de SCA Classic 2004 a CVA cuando FNC publique adaptación colombiana | cupping_tables.dart:4 | ⚪ Post-MVP |
| D-10| —             | Gap en numeración — nunca asignado                                  | —                                    | — |
| D-11| Android       | Decidir `applicationId` definitivo antes de publicar en Play Store  | ANDROID_SETUP.md                    | ⚪ Fase final |
| D-12| Persistencia  | Reconciliar `local_lots` vs `lots` — fuente de verdad en ítem #14  | local_lots_table.dart:7              | ⚪ Fase final |

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

### G-2 — Campo `hours_since_classification` pendiente de renombrar
- **Hallazgo**: nombre de variable temporal en DepulpingDao que no coincide con el dominio. Ver D-8.
- **Estado**: 🟡 Pendiente rename

---

## H. Seguridad y Red

### H-1 — ✅ JWT refresh implementado
- **Verificación**: `api_client.dart` tiene interceptor completo: 401 → skip rutas auth → getRefreshToken → POST `/auth/v1/refresh` → saveTokens → retry.
- **Estado**: ✅ Cerrado

### H-2 — ✅ Session persistence (currentUser) implementada
- **Verificación**: `currentUser()` usa `flutter_secure_storage` + `JwtDecoder.isExpired()` + `refresh()` si expirado. Persiste entre reinicios.
- **Estado**: ✅ Cerrado

---

## I. Catálogo de Variedades

### I-1 — Variedades Cenicafé 1 y Tabí ausentes
- **Hallazgo**: el catálogo de variedades no incluye Cenicafé 1 (resistente a roya, alta producción) ni Tabí (Timor × Bourbon × Typica, alta calidad de taza).
- **Estado**: 🟡 Pendiente añadir

---

## J. Calidad de Código y Tests

### J-1 — ✅ Tests existen — 13 fallos a resolver
- **Corrección**: J-1 estaba mal documentado. `test/` tiene 8 archivos, 1942 líneas. Estado real al 2026-05-26:
  - **155/168 tests pasan** (ai_engine: todos OK, brew_provider: todos OK).
  - **13 fallan** en dos grupos:
    1. `fermentation_provider_test.dart` (10 tests): `FermentationNotifier.addReading` + `locked after first reading` — causa: `TestWidgetsFlutterBinding.ensureInitialized()` ausente en `main()` + repo Drift no mockeado en tests que llaman `addReading`.
    2. `recommendation_card_test.dart` (2 tests): widget test sin binding inicializado.
    3. `widget_test.dart` (1 test): `App renders without crashing` — timer pendiente por `flutter_local_notifications`.
- **Estado**: 🔴 Abierto (J-3 para tracking del fix)

### J-2 — ✅ build_runner artefactos regenerados
- **Fix**: `dart run build_runner build` ejecutado en sesión 2026-05-26. `brew_recipe.freezed.dart` actualizado con `steepHours`.
- **Estado**: ✅ Cerrado (commit `3c69afc`)

### J-3 — 13 tests fallando (causas conocidas)
- **Grupo 1** (`fermentation_provider_test.dart`): falta `TestWidgetsFlutterBinding.ensureInitialized()` + override de `fermentationLocalRepoProvider` con repo in-memory.
- **Grupo 2** (`recommendation_card_test.dart`): binding no inicializado en setup.
- **Grupo 3** (`widget_test.dart`): timer pendiente de notificaciones — necesita `pumpAndSettle` con timeout extendido o fake `NotificationService`.
- **Estado**: 🔴 Abierto

---

## K. UX / Flujos de Pantalla

### K-1 — Dashboard no diferencia procesador de barista
- **Hallazgo**: `dashboard_screen.dart` aplica role-aware solo en `_QuickActions`. El contenido de lotes recientes es idéntico para todos los roles.
- **Estado**: ⚪ Post-MVP

---

## Resumen de Estado

| Área | 🔴 Abiertos | 🟠 Deuda | 🟡 Pendientes | ⚪ Post-MVP/Final | ✅ Cerrados |
|------|------------|----------|--------------|------------------|------------|
| A. Dominio         | B-1, B-3          | C-2         | C-1, C-4, D-9 | B-2, B-4      | 7 etapas IA  |
| B. Etapas          | B-1, B-3          | —           | —             | B-2, B-4      | —            |
| C. Reglas          | C-3               | C-2         | C-1, C-4      | —             | —            |
| D. Deudas técnicas | —                 | D-2,D-5,D-6,D-7 | D-8      | D-1,D-4,D-9,D-11,D-12 | D-3   |
| E. Conflictos      | —                 | —           | —             | —             | E-1, E-2     |
| F. Preparación     | —                 | —           | F-2           | —             | F-1          |
| G. Persistencia    | —                 | —           | G-2 (=D-8)    | G-1 (=D-12)   | —            |
| H. Seguridad       | —                 | —           | —             | —             | H-1, H-2     |
| I. Variedades      | —                 | —           | I-1           | —             | —            |
| J. Tests/Código    | J-1 (corr.), J-3  | —           | —             | —             | J-2          |
| K. UX              | —                 | —           | —             | K-1           | —            |

**Abiertos críticos (MVP)**: B-1 (Lavado), B-3 (Trilla/ítem#9), C-3 (userAvgFermentationH), J-3 (13 tests fallando).

---

## Prioridad de Bloques (Windows-first, MVP-first)

| Bloque | Ítems | Descripción | Estado |
|--------|-------|-------------|--------|
| **Bloque 0** | Reconciliación | J-1 corregido, D unificado, F-1/J-2 marcados | ✅ 2026-05-26 |
| **Bloque 1** | J-3, D-8, G-2 | Fix 13 tests fallando + rename campo DepulpingDao | 🔴 Pendiente OK |
| **Bloque 2** | B-1, C-1 | Módulo Lavado (entidad + reglas + UI) + expansión reglas secado | ⏳ |
| **Bloque 3** | C-3, C-4, I-1 | userAvgFermentationH, integración process_selection, variedades | ⏳ |
| **Bloque 4** | B-3 | Módulo Trilla (backlog ítem #9) | ⏳ |
| **Fase final** | D-1,D-4,D-12,D-11 | Android + sync PostgREST — no tocar hasta OK | 🔒 |

---

## Historial de Cambios

| Fecha      | Commit    | Cambio                                                                 |
|------------|-----------|------------------------------------------------------------------------|
| 2026-05-26 | —         | Auditoría inicial — 11 hallazgos documentados                          |
| 2026-05-26 | 3c69afc   | E-2 cerrado — cherryColorOptimalMin 75→95 (coffee_thresholds)          |
| 2026-05-26 | 3c69afc   | F-1 cerrado — Cold Brew implementado (recipe + UI + regla)             |
| 2026-05-26 | 3c69afc   | H-1, H-2 cerrados — JWT refresh y session persistence verificados      |
| 2026-05-26 | 3c69afc   | J-2 cerrado — build_runner ejecutado, brew_recipe.freezed.dart OK      |
| 2026-05-26 | —         | Reconciliación: J-1 corregido (tests existen, 155/168 pasan), D unificado (D-1..D-12), tabla de bloques añadida |
