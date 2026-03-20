---
name: build-dmg
description: Build a shareable DMG for Flowbar. Use this skill whenever the user asks to create a DMG, package the app for sharing, build a release, or make a distributable. Also triggers on "build dmg", "create installer", "share the app", or "package for distribution".
---

# Build DMG

Build a shareable DMG for Flowbar (ad-hoc signed, no notarization) by running the build script.

## Usage

Run the script from the repo root:

```bash
bash .claude/skills/build-dmg/scripts/build-dmg.sh
```

Pass `--skip-xcodegen` if `project.yml` hasn't changed:

```bash
bash .claude/skills/build-dmg/scripts/build-dmg.sh --skip-xcodegen
```

## What it does

1. Cleans previous build artifacts
2. Regenerates the Xcode project via `xcodegen` (unless `--skip-xcodegen`)
3. Archives in Release configuration with ad-hoc signing
4. Extracts the `.app` from the archive
5. Creates a compressed DMG at `build/Flowbar.dmg`

## Distribution note

Recipients need to go to **System Settings > Privacy & Security > Open Anyway** since the app isn't notarized.

The GitHub Actions workflow (`.github/workflows/build-dmg.yml`) does the same thing and also creates a GitHub Release with the DMG attached.
