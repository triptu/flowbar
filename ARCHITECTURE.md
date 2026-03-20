Flowbar is a macOS menu bar app for browsing and editing markdown notes in a directory. It also has a focus timer that tracks time against todos extracted from those notes.

## Codemap

```
Flowbar/Sources/
├── App/            AppDelegate (creates singletons, Fn-key listener),
│                   AppState (folder, file list, navigation),
│                   EditorState (editor text, auto-save debounce),
│                   SidebarState (selection, file list, rename),
│                   SettingsState (user preferences),
│                   FlowbarApp (SwiftUI @main entry point)
│
├── Models/         NoteFile, TodoItem — immutable value types
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
│                   SidebarView (file list, inline RenameField, context menu),
│                   NoteContentView (preview/edit toggle),
│                   MarkdownPreviewView (rendered markdown with clickable todos),
│                   MarkdownEditorView (NSTextView with bullet auto-continuation),
│                   TitleBarView (active-task label + elapsed time in title bar),
│                   SettingsView,
│                   Timer/ (TimerContainerView, TimerHomeView, TimerTodosView),
│                   Components/ (TodoRow, SidebarFooter, SidebarToggleButton)
│
└── Theme/          Colors (AccentColor presets + FlowbarColors), Typography — design tokens
```

## How things connect

**AppDelegate** creates three `@Observable` singletons on launch — `AppState`, `TimerService`, `WindowManager`. `WindowManager.showPanel()` injects them into the SwiftUI view tree via `.environment()`. AppState owns three sub-states: `EditorState`, `SidebarState`, `SettingsState`. `DatabaseService` is a fourth singleton (static `shared`) used by TimerService for persistence.

**Notes data flow:** AppState loads the folder and builds `[NoteFile]` → FileWatcher monitors the directory for external changes → sidebar displays files → user selects one → EditorState loads content → MarkdownPreviewView renders it with clickable checkboxes (default) or MarkdownEditorView for raw editing (⌘E toggle) → edits auto-save with 500ms debounce → FileWatcher detects external changes and reloads.

**Timer data flow:** User picks a todo → TimerService.start() creates a DB session → timer ticks update `elapsed` → user hits Complete → view calls MarkdownParser to check it off in the .md file.


## UI Tests

`FlowbarUITests` target (XCTest/XCUIAutomation) launches the app with `-uitest-folder <path>` to inject a temp directory and auto-show the panel. Tests verify the full rename flow, context menu, selection, and edge cases. Accessibility identifiers (`sidebar-row-<id>`, `rename-field`, `content-area`, `sidebar-footer-*`) are set on views for element queries.

## Invariants

- **No dependencies.** SQLite via the C API, no Swift packages.
- **Immutable models.** NoteFile and TodoItem carry no mutable state. Runtime state (like "is this todo's timer running?") is computed at the view level from TimerService.
- **Single navigation state.** One `ActivePanel` enum — impossible to get into inconsistent states like "settings open but also a file selected."
- **Source of truth is markdown files.** Todos and the file list are views into .md files. No creating/deleting todos from the timer UI.
