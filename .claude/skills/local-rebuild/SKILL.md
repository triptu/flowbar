---
name: local-rebuild
description: Build and run Flowbar locally for development. Use this skill whenever the user asks to build, rebuild, run, launch, or test-run the app locally. Also use when they say "local rebuild", "build and run", "restart the app", or just "run it".
---

# Local Rebuild

Build and launch Flowbar for local development by running the build script.

## Usage

Run the script from the repo root:

```bash
bash .claude/skills/local-rebuild/scripts/local-rebuild.sh
```

Pass `--skip-xcodegen` if `project.yml` hasn't changed:

```bash
bash .claude/skills/local-rebuild/scripts/local-rebuild.sh --skip-xcodegen
```

## What it does

1. Kills any running Flowbar instance
2. Regenerates the Xcode project via `xcodegen` (unless `--skip-xcodegen`)
3. Builds in Debug configuration
4. Launches the app

## Running tests

Tests are separate from the build — run them with:

```bash
xcodebuild test \
  -project Flowbar/Flowbar.xcodeproj \
  -scheme Flowbar \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData
```
