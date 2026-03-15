---
description: Build, test, and extend Flowbar — the macOS menu bar notes app. Encodes learnings about Swift/SwiftUI, the user's preferences, development workflow, and pitfalls to avoid.
argument-hint: [what to build or fix]
model: opus
---

# Flowbar Development Guide

You're working on Flowbar, a native macOS menu bar app (Swift/SwiftUI/AppKit) for quick access to Obsidian vault markdown files. The codebase is at `Flowbar/` in the current workspace.

## The User

- Doesn't know Swift deeply — keep code readable with clear module-level comments
- Obsessed with minimalism and consistency — every pixel, every color, every state matters
- Wants ONE accent color (sage green #8B9A6B) everywhere, no system blue, no multiple shades
- Treats this as a self-improving product — always think about what's reusable and extensible

## Build & Test Workflow

### Building
```bash
cd Flowbar
xcodebuild -project Flowbar.xcodeproj -scheme Flowbar -configuration Debug build 2>&1 | grep -E "error:|BUILD" | grep -v "DVT\|xcodebuild\|IDESimulator" | tail -5
```

If `project.yml` was modified, regenerate first:
```bash
xcodegen generate && xcodebuild ...
```

### Testing
```bash
cd Flowbar
xcodebuild test -scheme Flowbar -destination 'platform=macOS' 2>&1 | grep -E '(error:|Test run with|SUCCEEDED|FAILED|Suite.*failed)'
```

**Framework:** Swift Testing (`import Testing`, `@Test`, `@Suite`, `#expect`) — NOT XCTest. Migrated March 2025.

**Test directory mirrors source:**
```
Tests/
  App/        AppStateNavigationTests, AppStateTests, FileOperationsTests
  Models/     ModelTests
  Services/   MarkdownParserTests, TimerServiceTests, TimerServiceLifecycleTests
```

**Adding new test files:** Must be added to both the filesystem AND the pbxproj (PBXFileReference, PBXGroup children, PBXBuildFile, and the FlowbarTests Sources build phase).

**Style rules:**
- No mocks, stubs, or fakes. Tests hit real code e2e.
- Use `@Test(arguments:)` with case arrays for truth-table tests — never one method per input/output pair.
- Use `struct` (not `class`), `init() throws` for setup (no setUp/tearDown).
- Test real behavior, not implementation details. Don't test for the sake of testing.

### Running
```bash
open ~/Library/Developer/Xcode/DerivedData/Flowbar-*/Build/Products/Debug/Flowbar.app
```

### Taking Screenshots

The overlay panel has `hidesOnDeactivate = false`, so it stays visible when `screencapture` runs:

```bash
# Click menu bar icon to show the overlay, then capture
osascript -e 'tell application "System Events" to tell process "Flowbar" to click menu bar item 1 of menu bar 2' && sleep 0.5 && screencapture -x /tmp/screenshot.png
```

You can also use AppleScript to find UI elements for clicking:
```bash
osascript -e 'tell application "System Events" to tell process "Flowbar" to tell window 1 to tell group 1 to set btns to every button ...'
```

Or use `cliclick` for coordinate-based clicks (install via `brew install cliclick`). Get window position first via AppleScript.

### Setting defaults without UI
```bash
defaults write com.flowbar.app folderPath "/path/to/folder"
defaults write com.flowbar.app theme dark  # or light, system
```

## Architecture Rules

### State Management
- **Single `ActivePanel` enum** for navigation — never use separate booleans for "which view is showing"
- **`@Observable` + `@Environment`** (Swift 6 / macOS 15+ pattern, NOT the older `ObservableObject` + `@EnvironmentObject`)
- AppState uses `@Observable` with manual `UserDefaults` persistence via `didSet` (not `@AppStorage` which requires `ObservableObject`)
- Use `@ObservationIgnored` for private implementation details (watchers, tasks, flags)
- Use `@Bindable var appState = appState` inside `body` when you need `$appState.someBinding`
- TimerService should also use `@Observable` — if it still uses `ObservableObject`, migrate it

### Models are pure
- `NoteFile` and `TodoItem` are immutable value types
- No mutable runtime state on models — compute it at the view level from services

### Services don't cross boundaries
- `TimerService` does NOT touch markdown files — `complete()` returns `(todoText, sourceFile)` and the caller handles file ops via `MarkdownParser`
- `DatabaseService` is a singleton, accessed only by `TimerService`
- `MarkdownParser` is a static enum (no instance state)

### Views
- Every view reads state from `@Environment(AppState.self)` etc.
- One accent color: `FlowbarColors.accent` — sage green everywhere
- Custom `FlowbarSegmentedControl` instead of system Picker (which uses blue)
- `.regularMaterial` for backgrounds (not `.ultraThinMaterial` which is too translucent)

## Design Preferences (non-negotiable)

1. **ONE green.** `#8B9A6B` for all selection, active, checkmark, toggle states. No bright green, no different shades.
2. **No system blue.** Custom controls everywhere. If a system control sneaks in blue, replace it.
3. **Earthy, calm, minimal.** Glassmorphic but not washed out. `.regularMaterial` not `.ultraThinMaterial`.
4. **Light AND dark must both look good.** `preferredColorScheme` from settings. Test both.
5. **Overlay architecture.** Single floating panel toggled from the menu bar icon or double-Fn.
6. **Sidebar toggle shows next to title** when sidebar is hidden.
7. **Todo row layout**: source file name below title text, aligned with title start (not under the checkbox).
8. **Timer**: PAUSE (not stop) preserves state. Only COMPLETE clears and marks done. Pausing stays on timer view. Completing switches to todos to pick next task.

## Common Pitfalls

1. **`xcodebuild -runFirstLaunch`** may be needed on fresh Xcode installs — run it if you get plugin loading errors.
2. **SourceKit errors in tool output** are cross-file resolution issues — they resolve on actual build. Don't chase them.
3. **`Color` vs `ShapeStyle` in ternaries** — `FlowbarColors.accent : .tertiary` won't compile because they're different types. Use `FlowbarColors.accent : Color.secondary.opacity(0.5)` instead.
4. **`@AppStorage` doesn't work with `@Observable`** — use manual `UserDefaults` with `didSet`.
5. **Newline splitting** — always use `"\n"`, never `.newlines` (which splits on `\r\n`, `\r`, etc. and causes mismatches on write-back).
6. **FileWatcher feedback loop** — saving a file triggers the watcher which reloads content. Use an `isWriting` flag to break the cycle.
7. **N+1 database queries** — use `allTotalTimes()` batch query, not per-item `totalTime()`.
8. **Double `loadFiles()`** — if an `onChange` handler calls `loadFiles()`, don't also call it explicitly after setting a value.
9. **Always use modern Swift** — prefer `@Observable` over `ObservableObject`, `@Environment` over `@EnvironmentObject`, `some View` over `AnyView`. Check the Swift and macOS versions in project.yml and use the latest available patterns.
10. **AppState() in tests loads from UserDefaults** — the init calls `loadFiles()` using the persisted `folderPath`. In tests, always set `state.folderPath = ""` (or point to a temp dir) and `state.activePanel = .empty` before setting up test state, or you'll get interference from the user's real files.
11. **Swift Testing `#expect(try ...)` needs `throws`** — if a `#expect` contains a `try` expression, the test function must be marked `throws`. Otherwise extract the `try` to a `let` before the `#expect`.

## After Making Changes

1. **Build**: `xcodebuild ...` and verify no errors.
2. **Test visually**: Launch the app, screenshot key views, verify in both light and dark
3. Also run tests, and add/update tests as needed.
4. **Run /simplify**: Use the simplify skill to review code quality, reuse, and efficiency
5. **Commit with context**: Describe what changed AND why

## Extending the App

When adding new features:
1. Read `ARCHITECTURE.md` for the full design spec
2. Add new views under the appropriate `Views/` subdirectory
3. If adding new state, prefer extending `AppState` or creating a focused `@Observable` service
4. If adding persistence, extend `DatabaseService` with new tables/queries
5. Update the learning guide at `docs/learn-swift.html` if adding significant new patterns, check the ".claude/commands/update-learn-page.md" command for instructions

## Meta: Updating This Skill

This skill should evolve as the project evolves. Update it when:
- A new pitfall is discovered (add to Common Pitfalls)
- The architecture changes (update Architecture Rules)
- A new design preference emerges from user feedback (add to Design Preferences)
- The build/test workflow changes (update Build & Test Workflow)
- Swift/SwiftUI best practices change (e.g. migration from ObservableObject to @Observable)

To update: edit `.claude/commands/flowbar-dev.md`

When making a significant change to the codebase, always end with:
"Consider updating /flowbar-dev if this introduces new patterns or pitfalls."

---

Now, help the user with: $ARGUMENTS
