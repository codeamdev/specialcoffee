# FUNC-1: Brewing MVP — Scope y decisiones de producto

**Fecha:** 2026-05-27  
**Referencia audit:** FUNC-1 (BrewRecipeScreen + BrewDiagnosisScreen stubs)

---

## Contexto previo

`BrewScreen` ya muestra receta y diagnóstico de IA **inline** (secciones
`_RecipeSection` y `_DiagnosisSection`). Los stubs de ruta `BrewRecipeScreen`
y `BrewDiagnosisScreen` existen en el router pero nunca se navega a ellos.

El MVP no elimina el comportamiento inline existente — lo complementa
añadiendo persistencia y una ruta dedicada para cada pantalla.

---

## Flujo implementado

```
BrewScreen (existente, sin cambios estructurales)
  └── _RecipeSection (inline, ya existía)
        └── [botón nuevo] "Registrar sesión →" → /brew/recipe

/brew/recipe — BrewRecipeScreen (stub → MVP)
  Muestra parámetros completos de la receta generada.
  └── "Iniciar extracción →" → /brew/diagnosis
      (pasa Map<String, dynamic> con campos de la receta)

/brew/diagnosis — BrewDiagnosisScreen (stub → MVP)
  Captura resultados post-extracción, guarda BrewingSession en Drift.
  └── "Guardar y volver" → Navigator.pop()
```

---

## Campos de BrewingSession (decisiones conservadoras)

| Campo | Tipo | Obligatorio | Razón |
|-------|------|-------------|-------|
| `id` | String | Sí | UUID generado |
| `ownerId` | String | Sí | del currentUserIdProvider |
| `method` | String | Sí | V60, Chemex, AeroPress, Espresso, Moka, Cold Brew |
| `doseG` | double | Sí | de la receta |
| `waterG` | double | Sí | de la receta |
| `waterTempC` | double | Sí | de la receta |
| `actualTimeSec` | int? | No | tiempo real de extracción — muchos usuarios no lo miden |
| `tdsPct` | double? | No | requiere refractómetro — opcional; REVISAR CON PRODUCTO si debe ser requerido |
| `yieldG` | double? | No | rendimiento en gramos — REVISAR CON PRODUCTO: ¿en g o en %? |
| `notes` | String? | No | notas libres de cata |
| `brewedAt` | DateTime | Sí | momento de la preparación |
| `createdAt` | DateTime | Sí | timestamp de guardado |

**REVISAR CON PRODUCTO:**
- ¿Yield en gramos o en porcentaje? → MVP usa gramos (más concreto, menos cálculo).
- ¿TDS requerido? → MVP lo deja opcional (no todos tienen refractómetro).
- ¿Mostrar historial de sesiones? → No en MVP; sí en backlog.

---

## Tabla Drift

Nombre: `brewing_sessions_local` (evita colisión con tabla de backend `brew_sessions`)
Schema: v8 → **v9** (solo CREATE TABLE — migración aditiva)

---

## Manejo de errores

Sigue exactamente el patrón QUAL-1:
- `BrewingSessionState.error: String?` con `copyWith(error: () => '...')`
- `catch (e, st)` con `if (kDebugMode) debugPrint(...)`
- SnackBar en la UI cuando `state.error != null`

---

## Tests requeridos

1. **Widget test** `BrewRecipeScreen` — verifica que muestra los campos de receta
2. **Widget test** `BrewDiagnosisScreen` — verifica que el formulario renderiza
3. **Provider test** `BrewingSessionNotifier`:
   - happy path: session guardada, `isSaved = true`
   - error de persistencia: `state.error != null`

Patrón: `drying_provider_test.dart` (_FakeRepo, ProviderContainer.overrides)

---

## Decisiones arquitectónicas

- `BrewingSessionNotifier` es un provider separado de `BrewNotifier`
  (BrewNotifier = AI interactions; BrewingSessionNotifier = persistencia)
- `BrewScreen` recibe un botón mínimo en `_RecipeSection` solo cuando
  `state.hasRecipe == true` — ningún otro cambio estructural
- `BrewRecipeScreen` lee de `brewProvider` (state en memoria del mismo proceso)
  — si `state.recipe == null`, muestra mensaje de fallback (ruta cold-start)
- `BrewDiagnosisScreen` recibe los campos de la receta via `state.extra`
  (Map<String, dynamic>) para poder precalcular targets de TDS/yield
