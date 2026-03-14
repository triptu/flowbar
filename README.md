# Flowbar

A native macOS menu bar app for quick access to a folder of markdown notes. Built for people who use Obsidian but want something lighter always within reach — no need to open the full app just to check a todo or jot something down.

Click the sparkle icon in your menu bar, your notes are right there. Edit them, check off todos, track time on tasks. Close the popover, it's gone. Double-tap Fn to bring it back from anywhere.

## What it does

- **Menu bar popover** — opens right under the menu bar icon, glassmorphic dark/light UI
- **Sidebar + editor** — all your .md files listed on the left, raw markdown editor on the right
- **Timer** — stopwatch to track time on todos, extracted from all your markdown files
- **Settings** — folder path, dark/light/system theme, font size, keyboard shortcut

## How to build & run

You need Xcode installed (tested on Xcode 16+, macOS 14+).

```bash
# Generate the Xcode project (only needed once, or after changing project.yml)
cd Flowbar
xcodegen generate

# Build
xcodebuild -project Flowbar.xcodeproj -scheme Flowbar -configuration Debug build

# Run the app
open ~/Library/Developer/Xcode/DerivedData/Flowbar-*/Build/Products/Debug/Flowbar.app
```

Or just open `Flowbar.xcodeproj` in Xcode and hit Run.

First launch: click the sparkle (✦) icon in your menu bar, go to Settings, and point it at your Obsidian vault folder (or any folder with .md files).

## Keyboard shortcuts

- **Double-tap Fn** — toggle the popover from anywhere
- **⌘B** — toggle sidebar

## How the code is structured

```
Sources/
├── App/                    # App lifecycle
│   ├── FlowbarApp.swift    # @main entry, just a SwiftUI App shell
│   ├── AppDelegate.swift   # Creates services, sets up menu bar + Fn shortcut
│   └── AppState.swift      # Central state: navigation, file list, editor content
├── Models/
│   ├── NoteFile.swift      # One markdown file (id, url, display name)
│   └── TodoItem.swift      # One todo extracted from markdown (text, done, source)
├── Services/
│   ├── DatabaseService.swift   # SQLite wrapper for timer session persistence
│   ├── FileWatcher.swift       # Watches a file/directory for changes via GCD
│   ├── MarkdownParser.swift    # Extracts todos from .md files, toggles checkboxes
│   └── TimerService.swift      # Stopwatch logic: start/pause/resume/complete
├── Theme/
│   ├── Colors.swift        # Single accent color (sage green), hex helper
│   └── Typography.swift    # Font size presets (small/default/large)
├── Views/
│   ├── MainView.swift      # Root: sidebar + content split view
│   ├── SidebarView.swift   # File list + footer tabs
│   ├── NoteContentView.swift   # Note header + markdown editor
│   ├── SettingsView.swift      # All settings with custom segmented controls
│   ├── Components/
│   │   ├── SidebarFooter.swift # Settings/Timer tab buttons
│   │   └── TodoRow.swift       # Single todo in the timer list
│   └── Timer/
│       ├── TimerContainerView.swift  # Switches between home and todos list
│       ├── TimerHomeView.swift       # Running timer display or idle state
│       └── TimerTodosView.swift      # All todos across files with filters
└── Window/
    ├── PopoverManager.swift    # Menu bar icon, popover, float/dock lifecycle
    └── FloatingPanel.swift     # NSPanel for the detached overlay window
```

## How things connect

**AppDelegate** creates three singletons on launch:
1. `AppState` — owns the folder path, file list, editor text, navigation state
2. `TimerService` — owns the stopwatch, talks to SQLite for persistence
3. `PopoverManager` — owns the menu bar icon and popover/panel windows

These get injected as `@EnvironmentObject` into the SwiftUI view tree. Views read from them, call methods on them, and SwiftUI handles the reactivity.

**Data flow for notes:** AppState reads the folder → creates NoteFile list → sidebar shows them → user clicks one → AppState loads its content into `editorContent` → TextEditor binds to it → edits auto-save with 500ms debounce → FileWatcher detects external changes and reloads.

**Data flow for timer:** User picks a todo in TimerTodosView → TimerService.start() creates a DB session → timer ticks update `elapsed` → UI reflects it → user hits Complete → TimerService returns the todo info → view calls MarkdownParser to check it off in the .md file.

## Design decisions

- **No dependencies.** SQLite via the C API, no Swift packages. Keeps the build fast and the binary small.
- **One accent color.** Sage green (#8B9A6B) everywhere — selection, checkmarks, active states. No system blue.
- **Raw markdown editor.** No rendered preview mode. Less friction, and Obsidian is right there if you want rich rendering (click the Obsidian icon to open the current note).
- **Immutable models.** NoteFile and TodoItem are value types with no mutable state. Runtime state (like "is this todo's timer running?") is computed at the view level from TimerService.
- **Single navigation state.** One `ActivePanel` enum instead of separate booleans — impossible to get into inconsistent states like "settings showing but also a file selected."
