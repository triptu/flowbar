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

## Navigating to specific views

Use keyboard shortcuts to navigate reliably — this is the preferred method over clicking UI elements.

| Shortcut | Action |
|----------|--------|
| `⌘B` | Toggle sidebar |
| `⌘,` | Open Settings |
| `⌥⌘T` | Open Timer |
| `⌥⌘L` | Open Todo List |
| `⌘E` | Toggle Edit/Preview mode |
| `⌘F` / `⌘K` | Toggle search |
| `⌥⌘←` | Previous file |
| `⌥⌘→` | Next file |
| `⌥⌘A` | Toggle Light/Dark theme |
| `Space` | Pause/Resume timer (when timer view is active) |

```bash
# Open settings
osascript -e 'tell application "System Events" to keystroke "," using command down'

# Open todo list
osascript -e 'tell application "System Events" to keystroke "l" using {option down, command down}'

# Open timer
osascript -e 'tell application "System Events" to keystroke "t" using {option down, command down}'

# Toggle edit/preview
osascript -e 'tell application "System Events" to keystroke "e" using command down'

# Navigate to next file
osascript -e 'tell application "System Events" to key code 124 using {option down, command down}'
```

## Interacting with UI elements

All interactive elements have accessibility identifiers for reliable targeting via AppleScript.

### Key accessibility identifiers

**Search:**
- `search-overlay` — search overlay container
- `search-field` — search text field
- `search-backdrop` — transparent backdrop (click to dismiss)

**Sidebar:**
- `sidebar-row-{fileId}` — file row in sidebar
- `sidebar-folder-{relativePath}` — folder row in sidebar
- `sidebar-footer-{label}` — footer buttons (settings, timer)
- `rename-field` — inline rename text field

**Content area:**
- `content-area` — main content panel
- `note-edit-preview` — edit/preview toggle button
- `note-open-obsidian` — open in Obsidian button

**Timer:**
- `timer-home-view` / `timer-todos-view` — timer sub-views
- `timer-pause-resume` — pause/resume button
- `timer-complete` — complete button
- `timeline-play-{todoText}` — play button per timeline entry

**Todo list:**
- `todo-row-{text}` — individual todo row
- `todo-toggle-{text}` — checkbox toggle
- `todo-play-{text}` — play/pause timer for a todo
- `todo-navigate-{fileId}` — source file link
- `todos-search` — search field
- `todos-filter-file` — file filter menu
- `todos-group-by-file` — group by file toggle
- `todos-toggle-completed` — show/hide completed toggle

**Title bar:**
- `titlebar-task-label` — active task label
- `titlebar-toggle-timeline` — timeline toggle button

### Targeting elements by accessibility identifier

```bash
# Click the edit/preview button
osascript -e 'tell application "System Events" to tell process "Flowbar" to tell window 1 to click button "note-edit-preview"'

# Click the timer pause/resume button
osascript -e 'tell application "System Events" to tell process "Flowbar" to tell window 1 to click button "timer-pause-resume"'
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
- **Prefer keyboard shortcuts** over clicking — they're faster and never break due to layout changes
- **Use accessibility identifiers** when you need to click a specific button — never rely on positional paths like `group 4 of UI element 1`
- **If you can't reach an element by shortcut or accessibility ID, fix the app** — add a `.accessibilityIdentifier()` or a keyboard shortcut to the SwiftUI view instead of hacking around with positional AppleScript paths or coordinate clicks. Fragile workarounds will just break again next time the layout changes. The fix belongs in the source code, not in the automation script.
