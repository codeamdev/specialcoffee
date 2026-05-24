#!/usr/bin/env bash
# SpecialCoffee AI — Setup inicial completo
# Ejecutar desde la raíz del proyecto: bash setup.sh

set -e

echo "▸ Verificando Flutter..."
flutter --version

echo "▸ Instalando dependencias..."
flutter pub get

echo "▸ Generando código (freezed, riverpod, drift, json_serializable)..."
dart run build_runner build --delete-conflicting-outputs

echo "▸ Configurando Firebase (requiere flutterfire CLI)..."
echo "  Si no tienes flutterfire: dart pub global activate flutterfire_cli"
echo "  Luego ejecuta: flutterfire configure --project=TU_PROJECT_ID"

echo "▸ Descargando fuentes..."
echo "  Descargar manualmente y colocar en assets/fonts/:"
echo "  - DM Serif Display: https://fonts.google.com/specimen/DM+Serif+Display"
echo "  - Inter:            https://fonts.google.com/specimen/Inter"
echo "  - JetBrains Mono:   https://fonts.google.com/specimen/JetBrains+Mono"

echo ""
echo "✓ Setup completo. Verifica firebase_options.dart antes de correr la app."
echo "  flutter run"
