---
description: Build, test, and extend Flowbar — a macOS menu bar app for notes, todos, and stopwatch. Use this skill for any Flowbar development task including building features, fixing bugs, writing tests, or understanding the codebase. Triggers on mentions of Flowbar, the menu bar app, or Swift/SwiftUI work in this project.
argument-hint: [what to build or fix]
model: opus
---

# Flowbar Development Guide

Flowbar is a native macOS menu bar app (Swift 6 / SwiftUI / AppKit, macOS 15+) for quick access to a folder of markdown files. Codebase is at `Flowbar/` in the current workspace.

The user doesn't know Swift deeply — keep code readable with clear module-level comments. They care intensely about minimalism and consistency: every pixel, color, and state matters. If a change isn't simple, refactor until it is.

## Coding Rules

- Extremely simple, "skimmable" code — bias for fewer lines, no clever tricks
- Minimize state: use discriminated unions, narrow types, few arguments
- Don't make things optional if they're actually required; use asserts when loading data
- Exhaustively handle enums, fail on unknown types
- No defensive code — trust the types
- Early returns, pure functions, don't over-extract into tiny functions
- Remove anything not strictly required by the change

## Build & Test

### Build
```bash
cd Flowbar
xcodebuild -project Flowbar.xcodeproj -scheme Flowbar -configuration Debug build 2>&1 | grep -E "error:|BUILD" | grep -v "DVT\|xcodebuild\|IDESimulator" | tail -5
```

If `project.yml` was modified, regenerate first: `xcodegen generate && xcodebuild ...`

### Test


Use /run-tests skill for tests. You can run unit tests, ui tests or both.

### Run


Use /local-rebuild skill for building andn running locally.

### Visual verification
Use the `/screenshot` skill to capture and inspect the running app.

### Test frameworks
- **Unit tests**: Swift Testing (`import Testing`, `@Test`, `@Suite`, `#expect`)
- **UI tests**: XCTest with XCUIAutomation (Swift Testing doesn't support UI testing)

### Adding test files
Must be added to both filesystem AND pbxproj (PBXFileReference, PBXGroup children, PBXBuildFile, FlowbarTests Sources build phase). Directory mirrors source: `Tests/App/`, `Tests/Models/`, `Tests/Services/`, `UITests/`.

### Unit test style
- No mocks, stubs, or fakes — tests hit real code e2e
- `@Test(arguments:)` with case arrays for truth-table tests, never one method per case
- `struct` (not `class`), `init() throws` for setup (no setUp/tearDown)
- Test real behavior, not implementation details

### UI test style
- `final class` with `setUpWithError`/`tearDownWithError`
- Launch with `-uitest-folder <tempDir>` to inject a test folder and auto-show the panel
- Consolidate into few tests covering full flows (each launch cycle ~3s overhead)
- `waitForExistence(timeout:)` / `waitForNonExistence(timeout:)` — never `Thread.sleep`
- Sidebar rows: `app.groups["sidebar-row-<id>"]`, footer: `app.buttons["sidebar-footer-*"]`, rename: `app.textFields["rename-field"]`

## Architecture

### State
- Central `AppState` with `@Observable` + `@Environment` (NOT `ObservableObject` + `@EnvironmentObject`)
- Single `ActivePanel` enum for navigation — no separate booleans
- `UserDefaults` persistence via `didSet` (not `@AppStorage`, incompatible with `@Observable`). Injectable via `init(defaults:)` for testing.
- `@ObservationIgnored` for private implementation details (watchers, tasks, flags)
- `@Bindable var appState = appState` inside `body` when you need `$appState.someBinding`

### Models
`NoteFile` and `TodoItem` are immutable value types. No mutable runtime state on models — compute at the view level from services.

### Services
- `TimerService` doesn't touch markdown files — `complete()` returns `(todoText, sourceFile)`, caller handles file ops via `MarkdownParser`
- `DatabaseService` is a singleton, accessed only by `TimerService`
- `MarkdownParser` is a static enum (no instance state)

### Views
- Read state from `@Environment(AppState.self)`
- `.regularMaterial` for backgrounds (not `.ultraThinMaterial`)
- Preview is default, edit is opt-in — `EditorState.isEditing` toggles to MarkdownEditorView (⌘E), resets on file switch
- `MarkdownEditorView` is NSViewRepresentable wrapping NSTextView for bullet/todo auto-continuation on Enter

## Design Preferences (non-negotiable)

1. **One accent, user's choice.** `appState.accent` for SwiftUI, `appState.accentColor.nsColor` for AppKit. Never hardcode colors — it's reactive via `@Observable`.
2. **No system blue.** Custom controls everywhere. Replace any system control that sneaks in blue.
3. **Earthy, calm, minimal.** Glassmorphic but not washed out.
4. **Light AND dark must look good.** `preferredColorScheme` from settings. Test both.
5. **Overlay architecture.** Single floating panel from menu bar icon or double-Fn.
6. **Sidebar toggle next to title** when sidebar is hidden.
7. **Todo row**: source file name below title, aligned with title start (not under checkbox).
8. **Timer**: PAUSE preserves state, COMPLETE clears and marks done. Pause stays on timer view, complete switches to todos.

## Common Pitfalls

1. **SourceKit errors in tool output** resolve on actual build. Don't chase them.
2. **Newline splitting** — use `"\n"`, never `.newlines` (splits on `\r\n`, `\r` too, causes write-back mismatches).
3. **FileWatcher feedback loop** — saving triggers reload. Use `isWriting` flag to break the cycle.
4. **N+1 queries** — use `allTotalTimes()` batch, not per-item `totalTime()`.
5. **Double `loadFiles()`** — if `onChange` calls `loadFiles()`, don't also call it explicitly after setting a value.
6. **AppState in tests** — use `AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)`. Never bare `AppState()`.
7. **`#expect(try ...)` needs `throws`** — mark the test function `throws`, or extract the `try` to a `let` before `#expect`.
8. **NSViewRepresentable reuse** — SwiftUI reuses stale NSView/Coordinator across `visible → hidden → visible`. Use `.id(sessionCounter)` to force fresh creation.
9. **Double-click fires single-tap** — guard single-tap handler to skip when double-tap is active.
10. **NSViewRepresentable feedback loops** — guard SwiftUI→NSTextView updates with `isUpdating` flag (same pattern as FileWatcher's `isWriting`).

## After Making Changes

1. Build and verify no errors
2. Launch the app, screenshot key views, verify both light and dark
3. Run tests and add/update as needed (skip UI tests unless you changed UI code)
4. Run `/simplify` to review code quality
5. Commit with context: what changed AND why

After significant changes, consider whether this skill needs updating with new patterns or pitfalls.

---

Now, help the user with: $ARGUMENTS
