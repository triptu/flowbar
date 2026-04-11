Flowbar is a macOS menu bar app for browsing and editing markdown notes in a directory. It also has a focus timer that tracks time against todos extracted from those notes.

## Codemap

```
Flowbar/Sources/
├── App/            AppDelegate (creates singletons, configurable global shortcut listener),
│                   AppState (folder, recursive file/folder scanning, file/folder operations, navigation),
│                   EditorState (editor text, auto-save debounce),
│                   GlobalShortcut (shortcut model — presets + custom, persistence, display),
│                   SearchState (search query, cached file contents, results),
│                   SidebarState (selection, file/folder tree, expand/collapse, rename),
│                   SettingsState (user preferences),
│                   FlowbarApp (SwiftUI @main entry point)
│
├── Models/         NoteFile, TodoItem (immutable value types), SidebarItem (folder/file tree node)
│
├── Services/       TimerService (stopwatch + SQLite sessions),
│                   DatabaseService (SQLite via C API, singleton),
│                   FileWatcher (GCD dispatch source on file descriptors),
│                   MarkdownParser (static methods, todo extraction/toggle)
│
├── Window/         WindowManager (NSStatusBar icon, panel toggle),
│                   FloatingPanel (NSPanel subclass, always-on-top overlay)
│
├── Views/          MainView (sidebar + content switch on ActivePanel),
│                   SidebarView (folder/file tree, inline RenameField, context menus),
│                   NoteContentView (preview/edit toggle),
│                   MarkdownPreviewView (rendered markdown with clickable todos),
│                   MarkdownEditorView (NSTextView with bullet auto-continuation),
│                   SearchOverlayView (⌘F/⌘K Spotlight-style search overlay),
│                   TitleBarView (active-task label + elapsed time in title bar),
│                   SettingsView,
│                   Timer/ (TimerContainerView, TimerHomeView, TimerTodosView),
│                   Components/ (TodoRow, SidebarFooter, SidebarToggleButton,
│                               ShortcutRecorderView)
│
└── Theme/          Colors (AccentColor presets + FlowbarColors), Typography — design tokens
```

## How things connect

**AppDelegate** creates three `@Observable` singletons on launch — `AppState`, `TimerService`, `WindowManager` — and installs the global shortcut listener. The shortcut is configurable via `SettingsState.globalShortcut`. When the setting changes, `onShortcutChanged` callback tears down and rebuilds the event monitors. `WindowManager.showPanel()` injects singletons into the SwiftUI view tree via `.environment()`. AppState owns four sub-states: `EditorState`, `SearchState`, `SidebarState`, `SettingsState`. `DatabaseService` is a fourth singleton (static `shared`) used by TimerService for persistence.

**Notes data flow:** AppState recursively scans the folder, building a `[SidebarItem]` tree (for the sidebar) and a flat `[NoteFile]` list (for search/todos) → FileWatcher monitors the root directory for external changes → sidebar displays the tree with expandable folders → user selects a file → EditorState loads content → MarkdownPreviewView renders it with clickable checkboxes (default) or MarkdownEditorView for raw editing (⌘E toggle) → edits auto-save with 500ms debounce → FileWatcher detects external changes and reloads.

**Timer data flow:** User picks a todo → TimerService.start() creates a DB session → timer ticks update `elapsed` → user hits Complete → view calls MarkdownParser to check it off in the .md file.

**Search data flow:** ⌘F/⌘K opens SearchOverlayView → SearchState caches all file contents on open → typing updates query and runs search against cache → results shown as filename matches first, then content matches (capped at 50) → arrow keys navigate, Enter/click selects file and closes overlay → clicking outside dismisses.


## UI Tests

`FlowbarUITests` target (XCTest/XCUIAutomation) launches the app with `-uitest-folder <path>` to inject a temp directory and auto-show the panel. Tests verify the full rename flow, context menu, selection, and edge cases. Accessibility identifiers (`sidebar-row-<id>`, `sidebar-folder-<relativePath>`, `rename-field`, `content-area`, `sidebar-footer-*`) are set on views for element queries.

## Invariants

- **No dependencies.** SQLite via the C API, no Swift packages.
- **Immutable models.** NoteFile and TodoItem carry no mutable state. Runtime state (like "is this todo's timer running?") is computed at the view level from TimerService.
- **Single navigation state.** One `ActivePanel` enum — impossible to get into inconsistent states like "settings open but also a file selected."
- **Source of truth is markdown files.** Todos and the file list are views into .md files. No creating/deleting todos from the timer UI.
