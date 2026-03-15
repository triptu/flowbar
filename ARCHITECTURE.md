## How things connect

**AppDelegate** creates three singletons on launch:
1. `AppState` — owns the folder path, file list, editor text, navigation state
2. `TimerService` — owns the stopwatch, talks to SQLite for persistence
3. `WindowManager` — owns the menu bar icon and the floating overlay panel

These get injected via `.environment()` into the SwiftUI view tree. Views read from them, call methods on them, and SwiftUI handles the reactivity.

**Data flow for notes:** AppState reads the folder → creates NoteFile list → sidebar shows them → user clicks one → AppState loads its content into `editorContent` → TextEditor binds to it → edits auto-save with 500ms debounce → FileWatcher detects external changes and reloads.

**Data flow for timer:** User picks a todo in TimerTodosView → TimerService.start() creates a DB session → timer ticks update `elapsed` → UI reflects it → user hits Complete → TimerService returns the todo info → view calls MarkdownParser to check it off in the .md file.

## Database Schema (SQLite)

Timer sessions are stored in DB.

```sql
CREATE TABLE timer_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    todo_text TEXT NOT NULL,
    source_file TEXT NOT NULL,
    started_at REAL NOT NULL,      -- Unix timestamp
    ended_at REAL,                 -- NULL if running
    completed BOOLEAN DEFAULT 0    -- Was task marked done?
);

CREATE TABLE app_state (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
```

## Design decisions

- **No dependencies.** SQLite via the C API, no Swift packages. Keeps the build fast and the binary small. Used for timer history, app state.
- **One accent color.** Sage green (#8B9A6B) everywhere — selection, checkmarks, active states. No system blue.
- **Immutable models.** NoteFile and TodoItem are value types with no mutable state. Runtime state (like "is this todo's timer running?") is computed at the view level from TimerService.
- **Single navigation state.** One `ActivePanel` enum instead of separate booleans — impossible to get into inconsistent states like "settings showing but also a file selected."
- **Source of truth is markdown files.** The timer and todos list are just views into the .md files. No adding/deleting todos from the UI — you edit the .md file and the app reflects it. This keeps things simple and robust.

## Design System

### Color Palette (Dark Mode — Primary)
- **Background**: Ultra-dark with glassmorphism (NSVisualEffectView .hudWindow material)
- **Sidebar BG**: Slightly lighter than main, still translucent
- **Accent/Selected**: Earthy olive/sage green `#8B9A6B` (muted, calm)
- **Text Primary**: `#E8E8E8` (warm white)
- **Text Secondary**: `#8A8A8A` (muted gray)
- **Text Muted**: `#5A5A5A`
- **Dividers**: `#2A2A2A` with 0.5 opacity
- **Checkmark green**: Same sage `#8B9A6B`
- **Timer active dot**: Brighter green `#7CB342`

### Color Palette (Light Mode)
- **Background**: Light frosted glass
- **Accent**: Same sage green family `#6B7A4B`
- **Text Primary**: `#1A1A1A`
- **Text Secondary**: `#6A6A6A`

### Typography
- **Default font**: System font (SF Pro)
- **Sizes**: Small=12, Default=14, Large=16
- **Title**: 24pt bold
- **Sidebar items**: 15pt regular
- **Timer display**: 48pt monospaced light
