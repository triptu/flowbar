---
description: Build, test, and extend Flowbar — the macOS menu bar notes app. Encodes learnings about Swift/SwiftUI, the user's preferences, development workflow, and pitfalls to avoid.
argument-hint: [what to build or fix]
model: opus
---

# Flowbar Development Guide

You're working on Flowbar, a native macOS menu bar app (Swift/SwiftUI/AppKit) for quick access to a folder with markdown files on root level. The codebase is at `Flowbar/` in the current workspace.

## The User

- Doesn't know Swift deeply — keep code readable with clear module-level comments
- Obsessed with minimalism and consistency — every pixel, every color, every state matters
- Accent color is configurable (Settings → Appearance) with 7 earthy presets, each with light/dark variants. Default is sage green. No system blue.
- Treats this as a self-improving product — always think about what's reusable and extensible
- Believes that every change should be simple and if it's not, the code should be refactored until it is. Avoid complexity. Refactor first and then do the simple change.

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

**Framework:** 

- Unit and integration tests - Swift Testing (`import Testing`, `@Test`, `@Suite`, `#expect`) for, as it's more lightweight and flexible than XCTest and is a modern replacement for it.
- UI Tests - XCTest with XCUIAutomation, as Swift Testing doesn't support UI testing and XCTest is the standard for that.

**Test directory mirrors source:**
```
Tests/
  App/        AppStateNavigationTests, AppStateTests, FileOperationsTests
  Models/     ModelTests
  Services/   MarkdownParserTests, TimerServiceTests, TimerServiceLifecycleTests
UITests/
  SidebarUITests  (selection, rename flows, context menu, edge cases)
```

**Adding new test files:** Must be added to both the filesystem AND the pbxproj (PBXFileReference, PBXGroup children, PBXBuildFile, and the FlowbarTests Sources build phase).

**Unit test style rules:**
- No mocks, stubs, or fakes. Tests hit real code e2e.
- Use `@Test(arguments:)` with case arrays for truth-table tests — never one method per input/output pair.
- Use `struct` (not `class`), `init() throws` for setup (no setUp/tearDown).
- Test real behavior, not implementation details. Don't test for the sake of testing.

**UI test style rules:**
- XCTest with XCUIAutomation (`final class`, `setUpWithError`/`tearDownWithError`).
- Launch with `-uitest-folder <tempDir>` to inject a test folder and auto-show the panel.
- Consolidate into few tests that cover full flows — each launch/teardown cycle adds ~3s overhead.
- Use `waitForExistence(timeout:)` and `waitForNonExistence(timeout:)` — never `Thread.sleep`.
- Access elements via accessibility identifiers (`sidebar-row-<id>`, `rename-field`, `content-area`, `sidebar-footer-*`).
- Sidebar rows are `app.groups["sidebar-row-<id>"]`, footer buttons are `app.buttons["sidebar-footer-*"]`, rename field is `app.textFields["rename-field"]`.

**Running UI tests:**
```bash
xcodebuild -scheme FlowbarUITests -destination 'platform=macOS' test 2>&1 | grep -E '(passed|failed|Executed|SUCCEEDED|FAILED)'
```

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
defaults write com.flowbar.app accentColor ocean  # sage, ocean, lavender, amber, clay, slate, rose
```

## Architecture Rules

### State Management
- **Single `ActivePanel` enum** for navigation — never use separate booleans for "which view is showing"
- **`@Observable` + `@Environment`** (Swift 6 / macOS 15+ pattern, NOT the older `ObservableObject` + `@EnvironmentObject`)
- AppState uses `@Observable` with manual `UserDefaults` persistence via `didSet` (not `@AppStorage` which requires `ObservableObject`). The `defaults` instance is injectable — `init(defaults:)` defaults to `.standard` but tests pass a throwaway suite.
- Use `@ObservationIgnored` for private implementation details (watchers, tasks, flags)
- Use `@Bindable var appState = appState` inside `body` when you need `$appState.someBinding`

### Models are pure
- `NoteFile` and `TodoItem` are immutable value types
- No mutable runtime state on models — compute it at the view level from services

### Services don't cross boundaries
- `TimerService` does NOT touch markdown files — `complete()` returns `(todoText, sourceFile)` and the caller handles file ops via `MarkdownParser`
- `DatabaseService` is a singleton, accessed only by `TimerService`
- `MarkdownParser` is a static enum (no instance state)

### Views
- Every view reads state from `@Environment(AppState.self)` etc.
- Accent color via `appState.accent` (computed from `appState.accentColor.color`) — reactive, updates all views immediately when changed. 7 presets (sage, ocean, lavender, amber, clay, slate, rose) with adaptive light/dark variants in `AccentColor` enum. Always use `appState.accent` in views, never a static.
- Custom `FlowbarSegmentedControl` instead of system Picker (which uses blue)
- `.regularMaterial` for backgrounds (not `.ultraThinMaterial` which is too translucent)

## Design Preferences (non-negotiable)

1. **One accent, user's choice.** `appState.accent` for all selection, active, checkmark, toggle states. The user picks from 7 earthy presets in Settings → Appearance. Each preset has light/dark adaptive variants. Default is sage. Never hardcode a specific color for accent purposes — always use `appState.accent` (reactive) or `appState.accentColor.nsColor` for AppKit contexts.
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
10. **AppState in tests must use isolated UserDefaults** — use `AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)` so tests don't read or pollute the app's real settings. Never use `AppState()` (bare) in tests.
11. **Accent color must go through `appState.accent`** — never use a static for accent color. `appState.accent` is a computed property (`accentColor.color`) on `@Observable AppState`, so all views reactively update when the user changes their color. For AppKit contexts (e.g. `NSViewRepresentable`), use `appState.accentColor.nsColor` and pass it as a parameter.
12. **Swift Testing `#expect(try ...)` needs `throws`** — if a `#expect` contains a `try` expression, the test function must be marked `throws`. Otherwise extract the `try` to a `let` before the `#expect`.
13. **NSViewRepresentable reuse across state toggles** — if a view goes `visible → hidden → visible`, SwiftUI may reuse the old `NSView` and `Coordinator` with stale state. Use `.id(sessionCounter)` to force fresh creation each time.
14. **Double-click fires single-tap too** — SwiftUI's `onTapGesture(count: 2)` and `onTapGesture(count: 1)` both fire on a double-click. Guard the single-tap handler to skip when the double-tap action is active.
15. **Preview is default, edit is opt-in** — NoteContentView shows MarkdownPreviewView by default. `EditorState.isEditing` toggles to MarkdownEditorView (⌘E). Resets to preview on file switch. Checkbox toggles in preview modify `editorContent` directly and trigger save — no file I/O round-trip.
16. **MarkdownEditorView is NSViewRepresentable** — wraps NSTextView for bullet/todo auto-continuation on Enter. The Coordinator intercepts `insertNewline:` via `doCommandBy:`. When updating text from SwiftUI→NSTextView, guard with `isUpdating` flag to avoid feedback loops (similar to FileWatcher's `isWriting` pattern).

## After Making Changes

1. **Build**: `xcodebuild ...` and verify no errors.
2. **Test visually**: Launch the app, screenshot key views, verify in both light and dark
3. Also run tests, and add/update tests as needed. Don't run the ui tests as they're slow to run unless you changed UI code in which case run only the relevant ones.
4. **Run /simplify**: Use the simplify skill to review code quality, reuse, and efficiency
5. **Commit with context**: Describe what changed AND why

## Extending the App

When adding new features:
1. Read `ARCHITECTURE.md` for the full design spec
2. Add new views under the appropriate `Views/` subdirectory
3. If adding new state, prefer extending `AppState` or creating a focused `@Observable` service
4. If adding persistence, extend `DatabaseService` with new tables/queries

## Meta: Updating This Skill

This skill should evolve as the project evolves. Update it when:
- A new pitfall is discovered (add to Common Pitfalls)
- The architecture changes (update Architecture Rules)
- A new design preference emerges from user feedback (add to Design Preferences)
- The build/test workflow changes (update Build & Test Workflow)
- Swift/SwiftUI best practices change (e.g. migration from ObservableObject to @Observable)

To update: edit `.claude/skills/flowbar-dev.md`

When making a significant change to the codebase which warrants updates, always end with:
"Consider updating /flowbar-dev if this introduces new patterns or pitfalls.", Followed by your suggestions for what to add or change in this guide. Explain why the update is needed and how it helps future development. And propose to do it.

---

Now, help the user with: $ARGUMENTS
