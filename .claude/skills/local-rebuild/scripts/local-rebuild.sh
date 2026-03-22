#!/bin/bash
set -euo pipefail

# Build and run Flowbar for local development
# Usage: ./local-rebuild.sh [--skip-xcodegen]

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$REPO_ROOT"

SKIP_XCODEGEN=false
for arg in "$@"; do
  case "$arg" in
    --skip-xcodegen) SKIP_XCODEGEN=true ;;
  esac
done

echo "==> Killing existing Flowbar instance..."
pkill -x Flowbar 2>/dev/null || true
pkill -x "Flowbar Dev" 2>/dev/null || true

if [ "$SKIP_XCODEGEN" = false ]; then
  echo "==> Generating Xcode project..."
  cd Flowbar && xcodegen generate && cd ..
fi

echo "==> Building Flowbar (Debug)..."
xcodebuild build \
  -project Flowbar/Flowbar.xcodeproj \
  -scheme Flowbar \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  2>&1 | tail -20

echo "==> Launching Flowbar..."
APP_PATH="build/DerivedData/Build/Products/Debug/Flowbar Dev.app"
[ -d "$APP_PATH" ] || APP_PATH="build/DerivedData/Build/Products/Debug/Flowbar.app"
open "$APP_PATH"

echo "==> Done! Flowbar is running."
