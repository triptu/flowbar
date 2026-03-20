#!/bin/bash
set -euo pipefail

# Build a shareable DMG for Flowbar (ad-hoc signed, no notarization)
# Usage: ./build-dmg.sh [--skip-xcodegen]

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$REPO_ROOT"

SKIP_XCODEGEN=false
for arg in "$@"; do
  case "$arg" in
    --skip-xcodegen) SKIP_XCODEGEN=true ;;
  esac
done

# Clean previous build artifacts
rm -rf build/Flowbar.xcarchive build/Flowbar.app build/Flowbar.dmg

if [ "$SKIP_XCODEGEN" = false ]; then
  echo "==> Generating Xcode project..."
  cd Flowbar && xcodegen generate && cd ..
fi

echo "==> Archiving Flowbar (Release, ad-hoc signed)..."
xcodebuild archive \
  -project Flowbar/Flowbar.xcodeproj \
  -scheme Flowbar \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath build/Flowbar.xcarchive \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  ENABLE_HARDENED_RUNTIME=NO \
  AD_HOC_CODE_SIGNING_ALLOWED=YES \
  2>&1 | tail -20

echo "==> Extracting .app from archive..."
cp -r build/Flowbar.xcarchive/Products/Applications/Flowbar.app build/Flowbar.app

echo "==> Creating DMG..."
hdiutil create \
  -volname Flowbar \
  -srcfolder build/Flowbar.app \
  -ov \
  -format UDZO \
  build/Flowbar.dmg

echo "==> Done! DMG is at build/Flowbar.dmg"
echo "    Recipients need: System Settings → Privacy & Security → Open Anyway"
