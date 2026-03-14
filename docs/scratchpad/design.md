# Flowbar — Design Document

## Overview
A native macOS menu bar app for quick access to a folder of markdown notes from an Obsidian vault. Minimalist, dark glassmorphic aesthetic. Think: frosted dark glass floating over your desktop.

## Architecture

### Tech Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI + AppKit (NSStatusItem, NSPopover, NSPanel)
- **Storage**: SQLite via sqlite3 C API (for timer history, app state)
- **Markdown**: Native SwiftUI text editing (plain text with syntax awareness)
- **Min Target**: macOS 14 (Sonoma)

### App Structure
```
Flowbar/
├── App/
│   ├── FlowbarApp.swift          # Entry point, menu bar setup
│   ├── AppState.swift             # Global observable state
│   └── AppDelegate.swift          # NSApplicationDelegate for menu bar
├── Views/
│   ├── MainView.swift             # Split view container
│   ├── SidebarView.swift          # File list + footer
│   ├── ContentView.swift          # Note header + editor
│   ├── SettingsView.swift         # Settings panel
│   ├── TimerHomeView.swift        # Stopwatch display
│   ├── TimerTodosView.swift       # Todos list with timers
│   └── Components/
│       ├── SidebarFooter.swift    # Settings + Timer buttons
│       └── TodoRow.swift          # Single todo item
├── Models/
│   ├── NoteFile.swift             # Markdown file model
│   ├── TodoItem.swift             # Extracted todo model
│   └── TimerSession.swift         # Timer run record
├── Services/
│   ├── FileWatcher.swift          # DispatchSource file monitoring
│   ├── MarkdownParser.swift       # Todo extraction from .md files
│   ├── DatabaseService.swift      # SQLite operations
│   └── TimerService.swift         # Stopwatch logic
├── Window/
│   ├── PopoverManager.swift       # NSPopover management
│   ├── FloatingPanel.swift        # NSPanel for overlay mode
│   └── WindowSizeManager.swift    # Size persistence
└── Theme/
    ├── Colors.swift               # Color palette
    └── Typography.swift           # Font definitions
```

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

### Glassmorphism
- Use `.ultraThinMaterial` / `.regularMaterial` backgrounds
- Subtle rounded corners (12px)
- No heavy borders, just subtle light edges

## Window Behavior

### Menu Bar Popover
- Opens as NSPopover anchored below status item
- Default size: 700×500, resizable by dragging edges
- Size persisted in UserDefaults
- Sidebar collapsible (Cmd+B)

### Floating Overlay (Pop-out)
- Converts to NSPanel (level: .floating, styleMask: .utilityWindow)
- Appears on all spaces/fullscreen apps
- Has traffic light controls
- Top bar with drag region
- Animated transition from popover → panel
- "Dock back" animates panel → popover position

## Features

### 1. Sidebar
- Lists all `.md` files from configured directory
- Names shown without `.md` extension
- Selected item highlighted with accent color pill
- Footer: Settings icon | Timer icon (tab-style toggle)

### 2. Note Content
- Header: filename (bold, large) | Obsidian icon | Pop-out icon
- Body: Plain text editor with markdown content
- Auto-saves on edit (debounced 500ms)
- File watching for external changes

### 3. Settings
- Obsidian Folder Path (text field + Browse button via NSOpenPanel)
- Appearance: Light | Dark | System (segmented control)
- Typography: Small | Default | Large (segmented control)
- Global Keyboard Shortcut: Record button (double-tap Fn default)

### 4. Timer System (Stopwatch)
Three views, animated transitions:

**Timer Home (no timer running)**:
- Clean empty state, prompt to start from todos

**Timer Running**:
- Task title (large, centered)
- Time counting up below (MM:SS format)
- STOP button (pauses, returns to home)
- COMPLETE button (stops timer, marks todo done in .md file)

**Todos List** (toggle via list icon top-right):
- Search field + hide-done toggle
- List of todos extracted from ALL markdown files
- Each row: state circle | title | play/pause button
- Footer per row: source filename (clickable) | cumulative time
- Starting a new timer auto-stops any running timer
- Source of truth = markdown files, no add/delete here

### 5. Todo Extraction
Parse all `.md` files for:
- `- [ ] task text` → incomplete
- `- [x] task text` → complete
Track source file for each todo.

## Database Schema (SQLite)

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

## Keyboard Shortcuts
- `Cmd+B`: Toggle sidebar
- `Cmd+,`: Open settings
- Global shortcut (configurable): Toggle app visibility
- `Esc`: Close popover / dock floating window

## Build & Test Strategy
- Build after each major feature
- Screenshot verification at milestones
- Test file watching, timer accuracy, window transitions
