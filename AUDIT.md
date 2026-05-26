# SpecialCoffee AI — Auditoría Técnica Intermedia (Vivo)

> Archivo vivo. Última actualización: 2026-05-26.
> Sprint de referencia: Sprints 1–3 completados (commit b3c1633 + sesión de auditoría).
> Leyenda de estado: ✅ Cerrado · 🔴 Abierto · 🟡 Pendiente revisión · 🟠 Deuda aceptada · ⚪ Post-MVP

---

## A. Dominio — Cobertura de Etapas Productivas

El proceso del café tiene 11 etapas. Actualmente el motor IA cubre **7 de 11**.

| #  | Etapa           | Cobertura AI | Estado |
|----|-----------------|--------------|--------|
| 1  | Cosecha         | ✅ Reglas harvest_rules (5 reglas)        | ✅ Cerrado |
| 2  | Clasificación   | ✅ Reglas classification_rules (3 reglas) | ✅ Cerrado |
| 3  | Despulpado      | ✅ Reglas depulping_rules (2 reglas)      | ✅ Cerrado |
| 4  | Fermentación    | ✅ Reglas fermentation_rules (4 reglas)   | ✅ Cerrado (parcial — ver F-1) |
| 5  | Lavado          | ❌ Sin reglas, sin etapa en stepper       | 🔴 B-1 |
| 6  | Reposo          | ❌ Sin reglas, sin etapa en stepper       | 🔴 B-2 |
| 7  | Secado          | ✅ Reglas drying_rules (3 reglas)         | 🟡 C-1 (sparse) |
| 8  | Trilla          | ❌ Sin reglas, sin etapa en stepper       | 🔴 B-3 |
| 9  | Clasificación 2 | ❌ Sin reglas (parte de Trilla)           | 🔴 B-3 |
| 10 | Empaque         | ❌ Sin reglas, sin etapa en stepper       | 🔴 B-4 |
| 11 | Catación        | ✅ Reglas cupping_rules                   | ✅ Cerrado |

---

## B. Etapas faltantes

### B-1 — Lavado: etapa sin implementar
- **Área**: Dominio + AI + UI
- **Impacto**: El flujo no-natural (lavado) salta de Fermentación → Secado sin registrar el lavado del grano.
- **Reglas mínimas**: tiempo de lavado (horas), temperatura del agua, número de cambios de agua, pH efluente.
- **Refs**: C-1 (constraint: Cenicafé 8h max sin lavar post-fermentación).
- **Estado**: 🔴 Abierto

### B-2 — Reposo: etapa sin implementar
- **Área**: Dominio + UI
- **Impacto**: Etapa post-lavado (opcional según beneficiadero). No hay tracking de tiempo ni condiciones.
- **Estado**: ⚪ Post-MVP

### B-3 — Trilla + Clasificación física: etapa sin implementar
- **Área**: Dominio + AI + UI
- **Impacto**: No se registra rendimiento de trilla (kg pergamino → kg almendra). Ítem #9 del backlog.
- **Regla clave**: rendimiento esperado 18–22% (estándar SCA).
- **Estado**: 🔴 Abierto (ítem #9 backlog)

### B-4 — Empaque: etapa sin implementar
- **Área**: Dominio + UI
- **Impacto**: No hay tracking de peso final, tipo de empaque (GrainPro, saco yute), trazabilidad lote.
- **Estado**: ⚪ Post-MVP

---

## C. Motor de Reglas — Calidad y Cobertura

### C-1 — Reglas de secado escasas (3 reglas)
- **Hallazgo**: `drying_rules.dart` tiene solo 3 reglas. Falta: alerta por temperatura ambiental >35°C en secado, humedad relativa, control de volteo (días), riesgo de sobre-secado (<10% humedad del grano).
- **Estado**: 🟡 Pendiente expansión

### C-2 — Fermentación: reglas honey/anaeróbico ausentes
- **Hallazgo**: `fermentation_rules.dart` cubre lavado (pH, temperatura, tiempo). No hay reglas para fermentación honey (más seca, sin agua), ni para anaeróbico (presión CO₂, pH láctico < 3.8).
- **Estado**: 🟠 Deuda aceptada (backlog item #7)

### C-3 — userAvgFermentationH nunca se popula
- **Hallazgo**: `AIContext.userAvgFermentationH` se usa en reglas de fermentación para comparar con el histórico del usuario pero no hay ningún DAO ni provider que lo calcule y lo inyecte en el contexto.
- **Estado**: 🔴 Abierto

### C-4 — Reglas de process_selection sin integrar al stepper
- **Hallazgo**: `process_selection_rules.dart` emite recomendaciones de proceso (lavado/natural) basadas en Brix, lluvia y variedad. Pero el stepper de `lot_detail_screen.dart` no consulta estas recomendaciones al crear el lote.
- **Estado**: 🟡 Pendiente revisión

---

## D. Calibración Agrónoma (Thresholds)

| ID  | Variable                    | Valor actual | Respaldo documental     | Estado |
|-----|-----------------------------|--------------|-------------------------|--------|
| D-3 | `cherryColorOptimalMin`     | 95.0%        | FNC / estándar "falto"  | ✅ Cerrado (E-2) |
| D-5 | `flotationWarnPct`          | 20%          | Estimado                | 🟠 Calibrar con Cenicafé |
| D-5 | `flotationCriticalPct`      | 35%          | Estimado                | 🟠 Calibrar con Cenicafé |
| D-5 | `aprovechamientoMinPct`     | 60%          | Estimado                | 🟠 Calibrar con Cenicafé |
| D-6 | Umbrales °Brix              | 18–24 óptimo | General SCA             | 🟠 Calibrar con Cenicafé Avances Técnicos |
| D-7 | `depulpingWarnH` / `CritH`  | 6h / 8h      | C-1 para 8h; 6h sin doc | 🟠 Calibrar con Cenicafé |

---

## E. Errores de Lógica / Conflictos de Reglas

### E-1 — (CERRADO) ConflictResolver de-dupe por acción
- **Hallazgo**: el resolver de-dupe por nombre de acción. Acciones distintas no colisionan — correcto por diseño.
- **Estado**: ✅ Cerrado (comportamiento intencional)

### E-2 — (CERRADO) Conflicto HARVEST_NOW + STOP_GREEN_HARVEST simultáneos
- **Causa**: `cherryColorOptimalMin = 75.0` permitía cosechar con 25% verde, lo que disparaba HARVEST_NOW y STOP_GREEN_HARVEST al mismo tiempo.
- **Fix**: `cherryColorOptimalMin` → 95.0 en `coffee_thresholds.dart`. Propagado automáticamente a `HARV-BRIX-OPTIMAL-001`.
- **Commit**: sesión de auditoría 2026-05-26.
- **Estado**: ✅ Cerrado

---

## F. Módulos de Preparación (Barista)

### F-1 — Cold Brew: faltaba como método de preparación
- **Hallazgo**: `brew_screen.dart` tenía 6 métodos — faltaba Cold Brew. `BrewRecipeGenerator` no lo soportaba.
- **Fix aplicado**:
  - `brew_recipe.dart`: campo `steepHours` añadido (`@Default(0) int steepHours`).
  - `brew_recipe_generator.dart`: entrada `cold_brew` en `_baseRecipes`; `isColdBrew` guard en ajustes 1,2,4,6; TDS concentrado 2.5–3.5%.
  - `brew_screen.dart`: `cold_brew` añadido a `_methods`; UI adapta temperatura ("X°C (frío)") y parámetro maceración.
  - `brewing_rules.dart`: regla `BREW-COLDBREW-STEEP-001` añadida.
  - `_prettyMethod`: caso `'cold_brew' => 'Cold Brew'` añadido.
- **Estado**: ✅ Cerrado

### F-2 — BrewDiagnosisScreen / BrewRecipeScreen: dead-code stubs
- **Hallazgo**: ambas pantallas tienen ~17–19 líneas de stub placeholder. La funcionalidad de diagnóstico existe inline dentro de `brew_screen.dart` (`_DiagnosisSection`).
- **Decisión**: mantener como dead code — no expuestos en router. Eliminar o completar en ítem de refactor.
- **Estado**: 🟡 Pendiente (no crítico)

---

## G. Persistencia y Sincronización

### G-1 — D-12: dos tablas para Lot (`local_lots` vs `lots`)
- **Hallazgo**: existen dos tablas para Lot en Drift. `local_lots` es la tabla local (devBypass). `lots` es la tabla legacy. El ítem #14 debe reconciliarlas.
- **Estado**: 🟠 Deuda aceptada — ver ANDROID_SETUP.md D-12

### G-2 — D-8: campo `hours_since_classification` en DepulpingDao pendiente de renombrar
- **Hallazgo**: el campo en el DAO refleja un nombre de variable temporal que no coincide con el dominio.
- **Estado**: 🟡 Pendiente rename

---

## H. Seguridad y Red

### H-1 — (CERRADO) JWT refresh no implementado
- **Hallazgo inicial**: sospecha de que el interceptor Dio no hacía refresh.
- **Verificación**: `api_client.dart` tiene interceptor completo: 401 → skip rutas auth → getRefreshToken → POST `/auth/v1/refresh` → saveTokens → retry.
- **Estado**: ✅ Cerrado (ya implementado)

### H-2 — (CERRADO) Session persistence (currentUser)
- **Hallazgo**: `currentUser()` usa `flutter_secure_storage` + `JwtDecoder.isExpired()` + `refresh()` si expirado. Persiste correctamente entre reinicios de app.
- **Estado**: ✅ Cerrado (ya implementado)

---

## I. Catálogo de Variedades

### I-1 — Variedades Cenicafé 1 y Tabí ausentes
- **Hallazgo**: el catálogo de variedades no incluye Cenicafé 1 (variedad resistente a roya, alta producción) ni Tabí (híbrido Timor × Bourbon × Typica, alta calidad de taza).
- **Estado**: 🟡 Pendiente añadir

---

## J. Calidad de Código y Tests

### J-1 — Cero tests automatizados
- **Hallazgo**: no hay archivos en `test/`. Ningún unit test, widget test, ni integration test.
- **Impacto**: riesgo de regresión al expandir reglas o migrar datos.
- **Mínimo recomendado**: unit tests para `BrewRecipeGenerator`, `ConflictResolver`, y cada conjunto de reglas.
- **Estado**: 🔴 Abierto

### J-2 — build_runner artefactos Freezed pendientes de regenerar
- **Hallazgo**: `brew_recipe.freezed.dart` es stale (no incluye `steepHours`). Causa error pre-generación en `brew_screen.dart`.
- **Fix**: `dart run build_runner build`.
- **Estado**: 🟡 Pendiente (resolver antes del próximo commit)

---

## K. UX / Flujos de Pantalla

### K-1 — Dashboard no diferencia procesador de barista
- **Hallazgo**: `dashboard_screen.dart` aplica role-aware solo en `_QuickActions`. El contenido de lotes recientes es idéntico para todos los roles.
- **Decisión**: post-MVP — dashboard especializado por rol es backlog item.
- **Estado**: ⚪ Post-MVP

---

## Resumen de Estado

| Área | Abiertos 🔴 | Deuda 🟠 | Pendientes 🟡 | Post-MVP ⚪ | Cerrados ✅ |
|------|------------|----------|--------------|-----------|------------|
| A. Dominio         | 4 (B-1,B-3,B-3,B-4) | — | — | 2 (B-2,B-4) | 7 |
| C. Reglas          | 1 (C-3)    | 1 (C-2)  | 2 (C-1,C-4)  | —         | —          |
| D. Calibración     | —          | 5        | —            | —         | 1 (D-3)    |
| E. Conflictos      | —          | —        | —            | —         | 2          |
| F. Preparación     | —          | —        | 1 (F-2)      | —         | 1 (F-1)    |
| G. Persistencia    | —          | 1 (G-1)  | 1 (G-2)      | —         | —          |
| H. Seguridad       | —          | —        | —            | —         | 2          |
| I. Variedades      | —          | —        | 1 (I-1)      | —         | —          |
| J. Tests/Código    | 1 (J-1)    | —        | 1 (J-2)      | —         | —          |
| K. UX              | —          | —        | —            | 1 (K-1)   | —          |

**Total abiertos críticos**: B-1 (Lavado), B-3 (Trilla), C-3 (userAvgFermentationH), J-1 (Tests).

---

## Historial de Cambios

| Fecha      | Cambio                                                           |
|------------|------------------------------------------------------------------|
| 2026-05-26 | Auditoría inicial — 11 hallazgos documentados                   |
| 2026-05-26 | E-2 cerrado — `cherryColorOptimalMin` 75→95 en coffee_thresholds |
| 2026-05-26 | F-1 cerrado — Cold Brew implementado (recipe + UI + regla)       |
| 2026-05-26 | H-1, H-2 cerrados — JWT refresh y session persistence verificados |
