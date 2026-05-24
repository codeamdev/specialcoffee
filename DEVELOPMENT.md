# SpecialCoffee AI — Guía de desarrollo y pruebas

## Inicio rápido (Windows)

```powershell
# Desde PowerShell en la raíz del proyecto
.\setup.ps1
```

> Si PowerShell bloquea la ejecución:
> `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
>
> **No usar** `bash setup.sh` — requiere WSL que no está instalado.
> El script `setup.ps1` es el equivalente nativo para Windows.

---

## Estado actual del proyecto

| Componente | Estado |
|---|---|
| AI Engine (reglas Dart) | ✅ Completo |
| Screens: LotCreate, Fermentation, Brew | ✅ Completo |
| Providers: Riverpod | ✅ Completo |
| Tests: unit, provider, widget | ✅ Completo |
| Código generado (`*.g.dart`, `*.freezed.dart`) | ❌ Pendiente |
| Firebase configurado | ❌ Pendiente |
| Fuentes tipográficas en assets/ | ❌ Pendiente |

**Bloqueador principal:** el código generado por `build_runner` no existe aún.
Ningún archivo compila hasta ejecutar el paso de generación.

---

## 1. Prerrequisitos

### Flutter SDK

```bash
# Verificar instalación
flutter --version
# Requiere: Flutter >= 3.22.0 y Dart >= 3.3.0

# Si no está instalado: https://docs.flutter.dev/get-started/install/windows
```

### Herramientas necesarias

```bash
# Firebase CLI (para configurar el proyecto)
npm install -g firebase-tools
firebase --version   # >= 13.0

# FlutterFire CLI (para generar firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire --version

# Verificar que el PATH incluye el pub cache
# Windows: %LOCALAPPDATA%\Pub\Cache\bin
# macOS/Linux: $HOME/.pub-cache/bin
```

### Android

- Android Studio instalado con SDK Platform 34+
- Un emulador AVD creado, o un dispositivo físico con USB debugging activado
- Verificar: `flutter doctor` debe mostrar Android toolchain ✓

---

## 2. Instalación de dependencias

```bash
cd c:\Users\Administrador\Documents\specialcoffee

# Instalar todos los paquetes (pubspec.yaml)
flutter pub get
```

**Paquetes clave que se instalan:**

| Paquete | Rol |
|---|---|
| `flutter_riverpod` + `riverpod_annotation` | State management |
| `freezed_annotation` + `json_annotation` | Modelos inmutables |
| `hive_flutter` | Caché local de reglas IA |
| `drift` | Base de datos SQLite offline |
| `firebase_*` | Auth, Firestore, FCM, Remote Config |
| `mocktail` | Mocking en tests |

---

## 3. Generación de código (obligatorio antes de compilar)

Todos los archivos `@freezed`, `@riverpod`, `@JsonSerializable` y los esquemas Drift requieren generación. Sin este paso, **nada compila**.

```bash
# Ejecución única (normal para desarrollo)
dart run build_runner build --delete-conflicting-outputs

# Modo watch (regenera automáticamente al guardar un archivo)
dart run build_runner watch --delete-conflicting-outputs
```

### Qué genera este comando

```
lib/ai_engine/models/
  ai_context.freezed.dart      ← AIContext (37 campos, copyWith, ==, toString)
  ai_context.g.dart            ← fromJson / toJson
  ai_rule.freezed.dart         ← AIRule, RuleCondition, RuleOutcome, Recommendation
  ai_rule.g.dart
  brew_recipe.freezed.dart
  brew_recipe.g.dart

lib/core/di/
  providers.g.dart             ← firestoreProvider, rulesBoxProvider, cacheBoxProvider...

lib/presentation/providers/
  ai_engine_provider.g.dart    ← aiEngineProvider (FutureProvider)
  auth_provider.g.dart         ← authStateProvider, currentUserProvider
  lot_provider.g.dart          ← lotRepositoryProvider, lotCreateNotifierProvider
  fermentation_provider.g.dart ← fermentationNotifierProvider (family)
  brew_provider.g.dart         ← brewNotifierProvider

lib/domain/entities/
  lot.freezed.dart
  lot.g.dart
```

### Tiempo estimado

En un equipo moderno, la primera generación tarda **25–45 segundos**.
Las ejecuciones posteriores con `watch` son instantáneas (solo los archivos modificados).

### Posibles errores en este paso

```
Error: Could not find package "build_runner"
→ Solución: flutter pub get antes de correr build_runner

Error: The getter 'xxx' isn't defined for the type '_$AIContext'
→ Causa: archivo .freezed.dart desactualizado
→ Solución: dart run build_runner build --delete-conflicting-outputs

Error: Undefined name 'aiEngineProvider'
→ Causa: falta ai_engine_provider.g.dart
→ Solución: correr build_runner
```

---

## 4. Configuración de Firebase

La app requiere Firebase para arrancar (`main.dart` llama a `Firebase.initializeApp()`).
Sin este paso, la app crashea en el inicio con `No Firebase App '[DEFAULT]' has been created`.

### 4.1 Crear proyecto Firebase

1. Ir a [console.firebase.google.com](https://console.firebase.google.com)
2. Crear proyecto: `specialcoffee-ai-dev` (entorno de desarrollo)
3. Activar los servicios:
   - **Authentication** → método Email/Password
   - **Firestore Database** → modo test (reglas abiertas durante desarrollo)
   - **Remote Config** → agregar los parámetros de reglas IA (ver sección 4.3)
   - **Cloud Messaging** → para alertas push

### 4.2 Registrar la app Android

```bash
# Dentro del directorio del proyecto
flutterfire configure --project=specialcoffee-ai-dev
```

Esto genera automáticamente:
- `lib/firebase_options.dart` (reemplaza el placeholder actual)
- `android/app/google-services.json`
- `ios/GoogleService-Info.plist` (si se configura iOS)

Verificar que `android/app/google-services.json` existe antes de continuar.

### 4.3 Configurar Remote Config (reglas IA)

En la consola de Firebase → Remote Config → agregar parámetros:

| Parámetro | Tipo | Valor inicial |
|---|---|---|
| `ai_rules_version` | String | `1.0.0` |
| `ai_rules_json` | JSON | `[]` (array vacío — la app usa las reglas embedded como fallback) |
| `min_app_version` | String | `1.0.0` |

Con `ai_rules_json = []`, la app usa automáticamente `AllRules.all` (las reglas Dart embedded en el binario). No es necesario poblar Remote Config para desarrollo local.

### 4.4 Reglas de Firestore para desarrollo

En la consola → Firestore → Rules → publicar estas reglas temporales:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Solo para desarrollo.** Las reglas de producción con multi-tenant están documentadas en `ARCHITECTURE.md`.

---

## 5. Assets pendientes

La app referencia fuentes en `pubspec.yaml` que aún no existen en `assets/fonts/`.
Sin los archivos, Flutter muestra un error en el primer build.

### Solución temporal (desarrollo)

Comentar las fuentes en `pubspec.yaml` hasta tener los archivos:

```yaml
# fonts:
#   - family: DMSerifDisplay
#     fonts:
#       - asset: assets/fonts/DMSerifDisplay-Regular.ttf
# ... etc
```

### Descarga de fuentes (producción)

Descargar de Google Fonts:
- [DM Serif Display](https://fonts.google.com/specimen/DM+Serif+Display) → Regular + Italic
- [Inter](https://fonts.google.com/specimen/Inter) → Regular (400), Medium (500), SemiBold (600), Bold (700)
- [JetBrains Mono](https://fonts.google.com/specimen/JetBrains+Mono) → Regular (400), Medium (500)

Copiar a `assets/fonts/` con los nombres exactos que indica `pubspec.yaml`.

---

## 6. Ejecución de tests

Los tests están organizados en capas. Las capas inferiores se pueden ejecutar sin Firebase ni dispositivo.

### Capa 1 — Tests del AI Engine (sin Firebase, sin dispositivo)

Estos tests son puros Dart. No requieren emulador, no requieren Firebase. Solo necesitan que el código esté generado.

```bash
# Todos los tests del motor IA
flutter test test/ai_engine/

# Por archivo individual
flutter test test/ai_engine/alert_engine_test.dart
flutter test test/ai_engine/brew_recipe_generator_test.dart
flutter test test/ai_engine/condition_evaluator_test.dart
flutter test test/ai_engine/rule_engine_test.dart
```

**Cobertura esperada:**

| Archivo | Tests | Qué cubre |
|---|---|---|
| `alert_engine_test.dart` | 20 | Umbrales pH/temp por proceso, proyección lineal, secado |
| `brew_recipe_generator_test.dart` | 22 | Los 6 ajustes secuenciales de receta |
| `condition_evaluator_test.dart` | 25 | Todos los operadores + 36 campos del AIContext |
| `rule_engine_test.dart` | 15 | Pipeline completo: filtro módulo, AND/OR, prioridad, supersedes |

**Total Capa 1: 82 tests**

### Capa 2 — Tests de providers (sin Firebase, sin dispositivo)

Usan `ProviderContainer` con `_FakeAdapter` para aislar completamente Firebase e Hive.

```bash
flutter test test/presentation/providers/
```

| Archivo | Tests | Qué cubre |
|---|---|---|
| `brew_provider_test.dart` | 12 | generateRecipe, filtro DIAGNOSE, diagnose, reset |
| `fermentation_provider_test.dart` | 14 | addReading, AlertEngine primero, proyección, changeProcessType |

**Total Capa 2: 26 tests**

### Capa 3 — Widget tests (sin Firebase, sin dispositivo)

```bash
flutter test test/presentation/widgets/
```

| Archivo | Tests | Qué cubre |
|---|---|---|
| `recommendation_card_test.dart` | 12 | isTopCard, colores por confianza, íconos por nivel, formateo de action |

**Total Capa 3: 12 tests**

### Suite completa

```bash
# Todos los tests
flutter test

# Con output detallado
flutter test --reporter expanded

# Con cobertura de código
flutter test --coverage
# Genera coverage/lcov.info

# Convertir a HTML (requiere lcov instalado)
# Windows: instalar lcov vía Chocolatey: choco install lcov
genhtml coverage/lcov.info -o coverage/html
# Abrir coverage/html/index.html en el navegador
```

### Resultado esperado

```
00:00 +0: loading test/ai_engine/alert_engine_test.dart
00:02 +20: All tests passed!

00:00 +0: loading test/ai_engine/brew_recipe_generator_test.dart
00:03 +22: All tests passed!

... (continúa)

00:08 +120: All tests passed!
```

**120 tests en total, tiempo estimado: 8–15 segundos.**

---

## 7. Ejecutar la aplicación

### Verificar dispositivos disponibles

```bash
flutter devices
# Ejemplo de salida:
# emulator-5554   Android SDK built for x86   android-x86
# SM-A325F        Samsung Galaxy A32           android-arm64
```

### Modo debug (desarrollo)

```bash
# En el emulador por defecto
flutter run

# En un dispositivo específico
flutter run -d emulator-5554

# Con logs del RiverpodLogger visibles
flutter run --verbose
```

### Modo profile (para medir performance real)

```bash
flutter run --profile
# Conectar Flutter DevTools para ver: CPU, memoria, frames
# Verificar que RuleEngine.evaluate() < 5ms
```

### Build de release

```bash
# APK para distribución directa
flutter build apk --release
# Salida: build/app/outputs/flutter-apk/app-release.apk

# App Bundle para Google Play
flutter build appbundle --release
# Salida: build/app/outputs/bundle/release/app-release.aab
```

---

## 8. Flujo de trabajo diario

```bash
# 1. Al iniciar el día
git pull

# 2. Si se modificó pubspec.yaml
flutter pub get

# 3. Si se modificó un archivo con @freezed o @riverpod
dart run build_runner build --delete-conflicting-outputs

# 4. Correr tests antes de cada commit
flutter test test/ai_engine/           # rápido, siempre
flutter test                           # completo antes de push

# 5. Correr la app
flutter run
```

### Modo watch para desarrollo activo del AI Engine

```bash
# Terminal 1 — regenera código automáticamente
dart run build_runner watch --delete-conflicting-outputs

# Terminal 2 — corre tests del AI Engine en watch
flutter test test/ai_engine/ --watch   # nota: --watch requiere flutter test >= 3.22
```

---

## 9. Errores comunes y soluciones

### Error: `part of` archivo no encontrado

```
lib/core/di/providers.dart:12:1: Error: 'providers.g.dart' not found.
```
**Causa:** `build_runner` no se ha ejecutado.
**Solución:** `dart run build_runner build --delete-conflicting-outputs`

---

### Error: Firebase not initialized

```
[core/no-app] No Firebase App '[DEFAULT]' has been created
```
**Causa:** `google-services.json` no existe o `firebase_options.dart` tiene valores placeholder.
**Solución:** Ejecutar `flutterfire configure --project=TU_PROJECT_ID`

---

### Error: Hive box not open

```
HiveError: Box not found. Did you forget to call Hive.openBox()?
```
**Causa:** `main.dart` abre las boxes en `_initHive()`, pero se está accediendo a una box antes del `runApp()`.
**Solución:** Solo ocurre en tests. Los provider tests usan `ProviderContainer` con overrides — no acceden a Hive real.

---

### Error: MissingPluginException en tests

```
MissingPluginException(No implementation found for method...)
```
**Causa:** Plugin nativo (Firebase, Hive, connectivity_plus) llamado desde un test sin mock.
**Solución:** Los tests de la Capa 1 y 2 no usan plugins nativos. Si aparece este error, hay una importación directa de un provider real donde debería haber un override.

---

### Error: fuentes no encontradas

```
FileSystemException: Cannot open file, path = 'assets/fonts/Inter-Regular.ttf'
```
**Causa:** Archivos de fuente no copiados a `assets/fonts/`.
**Solución temporal:** Comentar el bloque `fonts:` en `pubspec.yaml`.

---

### Tests fallan con `Null check operator used on a null value`

**Causa más común:** El test usa `container.read(someProvider)` antes de que el provider asíncrono complete.
**Solución:** Usar `await container.read(someProvider.future)` para providers `FutureProvider`.

---

## 10. Estructura de directorios de referencia

```
specialcoffee/
├── lib/
│   ├── ai_engine/              ← Motor IA (sin Flutter, puro Dart)
│   │   ├── adapters/           ← InferenceAdapter, RuleBasedAdapter
│   │   ├── core/               ← RuleEngine, AlertEngine, BrewRecipeGenerator
│   │   ├── evaluators/         ← ConditionEvaluator, ConfidenceAdjuster
│   │   ├── models/             ← AIContext, AIRule, BrewRecipe, Alert (+ .g.dart)
│   │   └── rules/              ← AllRules, FermentationRules, BrewingRules...
│   ├── core/
│   │   ├── constants/          ← AppConstants, AppRoutes
│   │   ├── di/                 ← providers.dart (Firebase, Hive providers)
│   │   ├── router/             ← GoRouter
│   │   └── theme/              ← AppColors, AppTextStyles, AppTheme
│   ├── data/
│   │   └── repositories/       ← InMemoryLotRepository (→ Drift en v2)
│   ├── domain/
│   │   ├── entities/           ← Lot (freezed)
│   │   └── repositories/       ← LotRepository (abstract interface)
│   └── presentation/
│       ├── providers/          ← aiEngine, brew, fermentation, lot, auth
│       ├── screens/
│       │   ├── brewing/        ← BrewScreen
│       │   ├── fermentation/   ← FermentationScreen
│       │   └── lot/            ← LotCreateScreen
│       └── widgets/
│           └── ai/             ← RecommendationCard
├── test/
│   ├── helpers/
│   │   └── test_context.dart   ← ctx(), rule(), numCond() builders
│   ├── ai_engine/              ← Capa 1: puro Dart
│   └── presentation/
│       ├── providers/          ← Capa 2: ProviderContainer
│       └── widgets/            ← Capa 3: Flutter widget tests
├── assets/
│   ├── fonts/                  ← ⚠️ Vacío — descargar de Google Fonts
│   ├── images/
│   ├── icons/
│   └── rules/                  ← JSON de reglas (fallback offline)
├── pubspec.yaml
├── DEVELOPMENT.md              ← Este archivo
├── ARCHITECTURE.md
├── PRD_SpecialCoffeeAI.md
└── DATA_MODEL.md
```

---

## Checklist de primer arranque

```
[ ] flutter pub get
[ ] dart run build_runner build --delete-conflicting-outputs
[ ] flutterfire configure --project=TU_PROJECT_ID
[ ] Verificar android/app/google-services.json existe
[ ] Copiar fuentes a assets/fonts/ (o comentarlas en pubspec.yaml)
[ ] flutter test test/ai_engine/   → 82 tests passed
[ ] flutter test                   → 120 tests passed
[ ] flutter run
```
