#!/bin/bash
set -euo pipefail

# Take a screenshot of Flowbar's overlay panel
# Usage: ./screenshot.sh [output-path] [--show-panel] [--dark] [--light]
#
# Options:
#   output-path     Where to save (default: /tmp/flowbar-screenshot.png)
#   --show-panel    Click the menu bar icon first to ensure the panel is visible
#   --dark          Switch to dark mode before capturing
#   --light         Switch to light mode before capturing

OUTPUT="/tmp/flowbar-screenshot.png"
SHOW_PANEL=false
MODE=""

for arg in "$@"; do
  case "$arg" in
    --show-panel) SHOW_PANEL=true ;;
    --dark) MODE="dark" ;;
    --light) MODE="light" ;;
    --*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *) OUTPUT="$arg" ;;
  esac
done

# Check Flowbar is running (support both release "Flowbar" and dev "Flowbar Dev")
if pgrep -x "Flowbar Dev" > /dev/null; then
  PROCESS_NAME="Flowbar Dev"
elif pgrep -x Flowbar > /dev/null; then
  PROCESS_NAME="Flowbar"
else
  echo "ERROR: Flowbar is not running. Build and launch it first." >&2
  exit 1
fi

# Switch appearance if requested
if [ -n "$MODE" ]; then
  if [ "$MODE" = "dark" ]; then
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
  else
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
  fi
  sleep 0.5
fi

# Show the panel if requested
if [ "$SHOW_PANEL" = true ]; then
  osascript -e "tell application \"System Events\" to tell process \"$PROCESS_NAME\" to click menu bar item 1 of menu bar 2"
  sleep 0.5
fi

# Capture — the overlay has hidesOnDeactivate=false so it stays visible
screencapture -x "$OUTPUT"

echo "$OUTPUT"
