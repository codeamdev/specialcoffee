# Guía de build — Variables de entorno con --dart-define

`api_config.dart` usa `bool.fromEnvironment('DEV_MODE', defaultValue: false)`
para seleccionar las URLs de backend en tiempo de compilación. Por defecto
apunta a producción (`specialcoffee.app`).

---

## Desarrollo local

```powershell
# App en escritorio (Windows) — apunta a localhost
flutter run -d windows --dart-define=DEV_MODE=true

# App en navegador (Edge) — apunta a localhost
flutter run -d edge --dart-define=DEV_MODE=true
```

> En desarrollo, asegúrate de que el backend local esté corriendo:
> `cd backend && docker compose up auth`

---

## Build de producción

```powershell
# Android APK — apunta a specialcoffee.app
flutter build apk --dart-define=DEV_MODE=false

# Android AAB (Play Store)
flutter build appbundle --dart-define=DEV_MODE=false

# iOS — apunta a specialcoffee.app
flutter build ios --dart-define=DEV_MODE=false

# Windows desktop
flutter build windows --dart-define=DEV_MODE=false

# Web
flutter build web --dart-define=DEV_MODE=false
```

---

## Variables disponibles

| Variable | Tipo | Default | Efecto |
|----------|------|---------|--------|
| `DEV_MODE` | bool | `false` | `true` → localhost:8000/3001; `false` → specialcoffee.app |

---

## CI/CD

En pipelines de CI añadir el flag al paso de build:

```yaml
# Ejemplo GitHub Actions
- run: flutter build apk --dart-define=DEV_MODE=false
```

No es necesario en los pasos de `flutter test` — los tests no
dependen de `ApiConfig` (usan repositorios fake).
