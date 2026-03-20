---
description: Build, test, and extend Flowbar — the macOS menu bar app for notes, todos and stopwatch, window opens as overlay on top. Encodes learnings about Swift/SwiftUI, the user's preferences, development workflow, and pitfalls to avoid.
argument-hint: [what to build or fix]
model: opus
---

# Flowbar Development Guide

You're working on Flowbar, a native macOS menu bar app (Swift/SwiftUI/AppKit) for quick access to a folder with markdown files on root level. The codebase is at `Flowbar/` in the current workspace.

## The User

- Doesn't know Swift deeply — keep code readable with clear module-level comments
- Obsessed with minimalism and consistency — every pixel, every color, every state matters
- Treats this as a self-improving product — always think about what's reusable and extensible
- Believes that every change should be simple and if it's not, the code should be refactored until it is. Avoid complexity. Refactor first and then do the simple change.

## Coding Rules

- write extremely simple code, it should be "skimmable" and you should still be able to understand it
- minimize possible states by reducing number of arguments, remove or narrow any state
- use discriminated unions to reduce number of states the code can be in
- exhaustively handle any objects with multiple different types, fail on unknown type 
- don't write defensive code, assume the values are always what types tell you they are
- use asserts when loading data, and always be highly opinionated about the parameters you pass around. don't let things be optional if not strictly required
- remove any changes that are not strictly required
- bias for fewer lines of code
- no complex or clever code
- don't break out into too many function, that's hard to read
- early returns are great
- pure functions are great
- never pass overrides except strictly necessary, keep argument count low
- don't make arguments optional if they are actually required

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

**Adding new test files:** Must be added to both the filesystem AND the pbxproj (PBXFileReference, PBXGroup children, PBXBuildFile, and the FlowbarTests Sources build phase). Test directory mirrors source structure (`Tests/App/`, `Tests/Models/`, `Tests/Services/`, `UITests/`).

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

### Running the app
```bash
open ~/Library/Developer/Xcode/DerivedData/Flowbar-*/Build/Products/Debug/Flowbar.app
```

### Taking Screenshots & Visual Verification

Use the `/screenshot` skill for capturing and inspecting the running app visually.

## Architecture Rules

### State Management
- central global AppState
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
- `.regularMaterial` for backgrounds (not `.ultraThinMaterial` which is too translucent)

## Design Preferences (non-negotiable)

1. **One accent, user's choice.** `appState.accent` (computed from `accentColor.color`) for all accent purposes in SwiftUI. `appState.accentColor.nsColor` for AppKit. Never hardcode colors or use statics — it's reactive via `@Observable`.
2. **No system blue.** Custom controls everywhere. If a system control sneaks in blue, replace it.
3. **Earthy, calm, minimal.** Glassmorphic but not washed out. `.regularMaterial` not `.ultraThinMaterial`.
4. **Light AND dark must both look good.** `preferredColorScheme` from settings. Test both.
5. **Overlay architecture.** Single floating panel toggled from the menu bar icon or double-Fn.
6. **Sidebar toggle shows next to title** when sidebar is hidden.
7. **Todo row layout**: source file name below title text, aligned with title start (not under the checkbox).
8. **Timer**: PAUSE (not stop) preserves state. Only COMPLETE clears and marks done. Pausing stays on timer view. Completing switches to todos to pick next task.

## Common Pitfalls

1. **SourceKit errors in tool output** are cross-file resolution issues — they resolve on actual build. Don't chase them.
2. **Newline splitting** — always use `"\n"`, never `.newlines` (which splits on `\r\n`, `\r`, etc. and causes mismatches on write-back).
3. **FileWatcher feedback loop** — saving a file triggers the watcher which reloads content. Use an `isWriting` flag to break the cycle.
4. **N+1 database queries** — use `allTotalTimes()` batch query, not per-item `totalTime()`.
5. **Double `loadFiles()`** — if an `onChange` handler calls `loadFiles()`, don't also call it explicitly after setting a value.
6. **AppState in tests must use isolated UserDefaults** — use `AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)` so tests don't read or pollute the app's real settings. Never use `AppState()` (bare) in tests.
7. **Swift Testing `#expect(try ...)` needs `throws`** — if a `#expect` contains a `try` expression, the test function must be marked `throws`. Otherwise extract the `try` to a `let` before the `#expect`.
8. **NSViewRepresentable reuse across state toggles** — if a view goes `visible → hidden → visible`, SwiftUI may reuse the old `NSView` and `Coordinator` with stale state. Use `.id(sessionCounter)` to force fresh creation each time.
9. **Double-click fires single-tap too** — SwiftUI's `onTapGesture(count: 2)` and `onTapGesture(count: 1)` both fire on a double-click. Guard the single-tap handler to skip when the double-tap action is active.
10. **Preview is default, edit is opt-in** — NoteContentView shows MarkdownPreviewView by default. `EditorState.isEditing` toggles to MarkdownEditorView (⌘E). Resets to preview on file switch.
11. **MarkdownEditorView is NSViewRepresentable** — wraps NSTextView for bullet/todo auto-continuation on Enter. Guard SwiftUI→NSTextView updates with `isUpdating` flag to avoid feedback loops.

## After Making Changes

1. **Build**: `xcodebuild ...` and verify no errors.
2. **Test visually**: Launch the app, screenshot key views, verify in both light and dark
3. Also run tests, and add/update tests as needed. Don't run the ui tests as they're slow to run unless you changed UI code in which case run only the relevant ones.
4. **Run /simplify**: Use the simplify skill to review code quality, reuse, and efficiency
5. **Commit with context**: Describe what changed AND why

After significant codebase changes, consider whether `/flowbar-dev` needs updating with new patterns or pitfalls.

---

Now, help the user with: $ARGUMENTS
