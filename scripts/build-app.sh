#!/bin/bash
# Compila el ejecutable con SPM y ensambla el bundle .app con firma ad-hoc.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Limpia node_modules.app"

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/LimpiaNodeModules "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"

codesign --force --sign - "$APP"

echo "Bundle listo: $APP"
