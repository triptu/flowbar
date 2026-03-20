---
name: screenshot
description: Take screenshots of the running Flowbar app for visual verification. Use this skill whenever visual inspection is needed — after UI changes, when iterating on design, when the user says "screenshot", "how does it look", "show me", "take a screenshot", "capture the UI", or when you need to verify visual changes look correct. Also use proactively after making UI/view changes to confirm they render as expected.
argument-hint: [what to capture or verify visually]
---

# Flowbar Screenshot

Take screenshots of the running Flowbar overlay panel for visual verification. This is the core tool for iterative visual development — make a change, screenshot, evaluate, repeat.

## Why this exists

Flowbar is an overlay panel that floats above other windows. The panel has `hidesOnDeactivate = false`, so it stays visible even when `screencapture` steals focus. This makes automated screenshots reliable without any workarounds.

## Quick capture

```bash
bash .claude/skills/screenshot/scripts/screenshot.sh [output-path] [--show-panel] [--dark] [--light]
```

- **No flags**: Captures the full screen (panel must already be visible)
- **`--show-panel`**: Clicks the menu bar icon first to ensure the panel is open
- **`--dark` / `--light`**: Switches system appearance before capturing
- **output-path**: Defaults to `/tmp/flowbar-screenshot.png`

After capturing, read the screenshot with the Read tool to inspect it visually.

## Typical workflow

This is how to use screenshots in an iterative design loop:

1. **Make a UI change** in the code
2. **Build and launch** using `/local-rebuild`
3. **Screenshot**:
   ```bash
   bash .claude/skills/screenshot/scripts/screenshot.sh /tmp/flowbar-screenshot.png --show-panel
   ```
4. **Inspect** — read the screenshot file to see the result
5. **Evaluate** — does it match the intent? Check colors, spacing, alignment, both themes
6. **Iterate** — if something's off, fix it and go back to step 1

For checking both themes in one pass:
```bash
bash .claude/skills/screenshot/scripts/screenshot.sh /tmp/flowbar-light.png --show-panel --light
bash .claude/skills/screenshot/scripts/screenshot.sh /tmp/flowbar-dark.png --dark
```

## Interacting with UI before capturing

Sometimes you need the app in a specific state (a particular tab, a modal open, text selected) before screenshotting.

**Click the menu bar icon** (to toggle the panel):
```bash
osascript -e 'tell application "System Events" to tell process "Flowbar" to click menu bar item 1 of menu bar 2'
```

**Discover UI elements** in the panel:
```bash
osascript -e 'tell application "System Events" to tell process "Flowbar" to tell window 1 to entire contents'
```

**Click a specific button or element** by name:
```bash
osascript -e 'tell application "System Events" to tell process "Flowbar" to tell window 1 to click button "Settings"'
```

**Coordinate-based clicks** with `cliclick` (install via `brew install cliclick`):
```bash
# Get window position first
osascript -e 'tell application "System Events" to tell process "Flowbar" to get position of window 1'
# Then click at offset from window origin
cliclick c:500,300
```

**Type text** into a focused field:
```bash
osascript -e 'tell application "System Events" to keystroke "hello world"'
```

**Keyboard shortcuts** (e.g. ⌘E to toggle editor):
```bash
osascript -e 'tell application "System Events" to keystroke "e" using command down'
```

## Setting app state via defaults

To get to a specific state quickly without clicking through UI:
```bash
defaults write com.flowbar.app folderPath "/path/to/folder"
defaults write com.flowbar.app theme dark        # dark, light, system
defaults write com.flowbar.app accentColor ocean  # sage, ocean, lavender, amber, clay, slate, rose
```

Then relaunch the app to pick up the changes.

## Tips

- Always use `--show-panel` on the first screenshot if you're not sure the panel is open
- The panel stays visible across screenshots, so subsequent captures don't need `--show-panel`
- Sleep briefly (`sleep 0.3`) after AppleScript interactions before capturing, to let animations settle
- If Flowbar isn't running, build it first with `/local-rebuild`
