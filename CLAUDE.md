# CLAUDE.md — SpecialCoffee AI

App Flutter offline-first de Q Grader digital para producción y preparación de café de especialidad.

## Stack

- Dart/Flutter ≥3.8/3.22 · Riverpod codegen 4.0 · GoRouter 14.6 · Freezed 3.0 · Drift 2.21 (SQLite schema v7)
- Dio 5.7 · flutter_secure_storage 9.2 · Gemini AI 0.4.7 · mocktail 1.0
- Backend auth: FastAPI :8000 · Backend datos: PostgREST vía Nginx :3001 (fase final, no activo hoy)

## Comandos

```powershell
flutter pub get
dart run build_runner build          # tras cambios en @freezed, Drift tables, @riverpod
flutter run -d windows
flutter run -d edge
flutter test                         # suite completa (baseline: 238 tests)
flutter test test/ai_engine/washing_rules_test.dart   # test individual
cd backend && docker compose up auth  # único backend necesario hoy
.\backend\setup_local.ps1            # solo primera vez con BD vacía
```

## Estructura

```
lib/
  ai_engine/        # motor de reglas on-device + adaptador Gemini
    constants/      # CoffeeThresholds — todos los umbrales van aquí, con fuente
    core/           # RuleEngine, ConflictResolver, AlertEngine
    evaluators/     # ConditionEvaluator (mapea string keys → AIContext fields)
    models/         # AIContext (@freezed), AIRule, Recommendation
    rules/          # *_rules.dart + all_rules.dart
  core/
    config/         # api_config.dart · gemini_config.dart (gitignored, nunca commitear)
    database/       # AppDatabase v7 + DAOs + tablas Drift
    di/             # providers.dart — wiring infraestructura
    router/         # app_router.dart (GoRouter)
  data/repositories/  # *_repository_local.dart (Drift) + PostgRESTLotRepository
  domain/
    entities/       # clases Dart planas (sin @freezed)
    repositories/   # interfaces abstractas
  presentation/
    providers/      # *_provider.dart — estado UI (Riverpod)
    screens/        # una carpeta por módulo de producción/preparación
    widgets/        # componentes reutilizables
test/
  ai_engine/
  helpers/          # test_context.dart — ctx() factory compartida
  presentation/providers/
backend/
  auth/             # FastAPI (main.py, Dockerfile)
  nginx/            # proxy config
  schema.sql        # schema PostgreSQL completo
```

## Convenciones

**Arquitectura (orden de capas):**
`domain/entities` → `domain/repositories` → `core/database/daos` → `data/repositories/*_local.dart` → `core/di/providers.dart` → `presentation/providers/*_provider.dart` → `presentation/screens`

**Modelos:** Freezed + json_annotation en `ai_engine/`; entidades de dominio son clases Dart planas  
**Estado:** `@riverpod` codegen; no `StateNotifier` manual; `@Riverpod(keepAlive: true)` para infraestructura  
**DB:** Drift DAOs; SQL raw solo en migraciones; migraciones solo `CREATE TABLE` (nunca `ALTER`/`DROP`)  
**Lógica de negocio:** `domain/` y `ai_engine/`; fuera de widgets  
**Widgets:** solo presentación + llamada a provider; sin lógica; sin `Navigator.push` directo  
**Errores:** `AsyncValue` de Riverpod; no try/catch sueltos en UI  
**Imports:** siempre `package:special_coffee/...`; nunca relativos  
**Comentarios:** solo el WHY no obvio; nunca describir qué hace el código  

**Drift — gotchas:**
- Usar `@DataClassName('DbXxx')` en todas las tablas para evitar colisión con entidades de dominio
- En repositorios locales importar `app_database.dart`, no el archivo de tabla — los tipos generados (`DbXxx`, `XxxCompanion`) viven en `app_database.g.dart`

**Motor de reglas — gotchas:**
- Todos los umbrales en `CoffeeThresholds`; nunca literales sueltos en `*_rules.dart`
- Cada umbral nuevo: fuente documental (Cenicafé/FNC) o entrada en `AUDIT.md` como deuda de calibración
- Para evitar falsos positivos con defaults (0.0/0), usar `between 0.1 and X` en lugar de `gt 0`
- `supersedes: 'RULE-ID'` en AIRule para que ConflictResolver elimine la regla inferior

**Tests:**
- Patrón: `_FakeRepo implements DomainRepository` (in-memory) + `ProviderContainer.overrides`
- `TestWidgetsFlutterBinding.ensureInitialized()` al inicio de cada `main()`
- Si un test revela un bug: arreglar el código, nunca el test

**`const` en Dart:** `.toDouble()` y operadores aritméticos (`+`, `-`) son invocaciones de método — no permitidos en contextos `const`; usar literales explícitos

## Reglas

- **NUNCA** commitear `devBypass = true` en `lib/core/config/api_config.dart`
- **NUNCA** commitear `lib/core/config/gemini_config.dart` (API key hardcodeada, en `.gitignore`)
- **NUNCA** `ALTER TABLE` / `DROP TABLE` en migraciones Drift — solo `CREATE TABLE` aditivo; bump `schemaVersion`
- **NO** tocar sync PostgREST (ítem #14) ni verificación Android hasta autorización explícita
- Correr `dart run build_runner build` tras cualquier cambio en `@freezed`, tablas Drift, o `@riverpod`; errores de IDE previos a la regeneración son normales
- No añadir dependencias sin verificar compatibilidad con Flutter ≥3.22
- `AUDIT.md` es la fuente de verdad de deudas técnicas y bloques de trabajo — actualizar al cerrar cada bloque

## Ahorra tokens

- Respuestas cortas; sin preámbulo ("Voy a…", "Claro, …") ni resumen final de lo que se hizo
- No releer archivos recién editados para confirmar — Edit/Write falla si el cambio no se aplicó
- No leer archivos completos si solo se necesita una sección; usar `offset`+`limit`
- No explicar qué hace el código; los nombres lo dicen
- No pedir confirmación para cambios pequeños obvios dentro de una tarea ya autorizada
- Si la tarea es exploración amplia (>3 búsquedas), delegar a subagente Explore; si es lookup puntual, Grep/Glob directo
- Usar herramientas en paralelo cuando no hay dependencia entre ellas

## Definición de terminado

```powershell
flutter analyze     # cero errores, cero warnings
flutter test        # todos en verde (≥238)
dart run build_runner build --delete-conflicting-outputs   # sin conflictos
```

Si se añadieron umbrales o cambió el schema: `AUDIT.md` actualizado con fuente o deuda de calibración. Commit limpio sin `devBypass = true` ni `gemini_config.dart`.
