#!/bin/bash
set -euo pipefail

# Run Flowbar tests
# Usage: ./run-tests.sh [--unit] [--ui] [--all]
#   No flags = unit tests only
#   --unit   = unit tests only
#   --ui     = UI tests only
#   --all    = both unit and UI tests

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$REPO_ROOT/Flowbar"

RUN_UNIT=false
RUN_UI=false

if [ $# -eq 0 ]; then
  RUN_UNIT=true
fi

for arg in "$@"; do
  case "$arg" in
    --unit) RUN_UNIT=true ;;
    --ui)   RUN_UI=true ;;
    --all)  RUN_UNIT=true; RUN_UI=true ;;
  esac
done

EXIT_CODE=0

if [ "$RUN_UNIT" = true ]; then
  echo "==> Running unit tests (FlowbarTests)..."
  xcodebuild test \
    -project Flowbar.xcodeproj \
    -scheme Flowbar \
    -only-testing:FlowbarTests \
    -destination 'platform=macOS' \
    -derivedDataPath ../build/DerivedData \
    2>&1 | grep -E '(error:|Test run with|SUCCEEDED|FAILED|Suite.*failed|passed|Executed)' || EXIT_CODE=$?
fi

if [ "$RUN_UI" = true ]; then
  echo "==> Running UI tests (FlowbarUITests)..."
  xcodebuild test \
    -project Flowbar.xcodeproj \
    -scheme FlowbarUITests \
    -destination 'platform=macOS' \
    -derivedDataPath ../build/DerivedData \
    2>&1 | grep -E '(error:|Test run with|SUCCEEDED|FAILED|Suite.*failed|passed|Executed)' || EXIT_CODE=$?
fi

exit $EXIT_CODE
