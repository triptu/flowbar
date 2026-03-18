export interface EdgeMap {
  [nodeName: string]: string[];
}

export const EDGES: EdgeMap = {
  AppDelegate: ["e-ad-as", "e-ad-ts", "e-ad-pm"],
  AppState: ["e-ad-as", "e-as-nf", "e-as-fw", "e-mv-as"],
  TimerService: ["e-ad-ts", "e-ts-db"],
  WindowManager: ["e-ad-pm", "e-pm-fp", "e-mv-pm"],
  NoteFile: ["e-as-nf"],
  FileWatcher: ["e-as-fw"],
  DatabaseService: ["e-ts-db"],
  FloatingPanel: ["e-pm-fp"],
  MainView: ["e-mv-as", "e-mv-pm", "e-mv-sb", "e-mv-nc", "e-mv-sv", "e-mv-tc"],
  SidebarView: ["e-mv-sb"],
  NoteContentView: ["e-mv-nc"],
  SettingsView: ["e-mv-sv"],
  TimerContainerView: ["e-mv-tc", "e-tc-th", "e-tc-tt"],
  TimerHomeView: ["e-tc-th", "e-mp-th"],
  TimerTodosView: ["e-tc-tt", "e-tt-tr", "e-mp-tt"],
  TodoRow: ["e-tt-tr"],
  MarkdownParser: ["e-mp-tt", "e-mp-th"],
};

export const NODE_TOOLTIPS: Record<string, string> = {
  AppDelegate:
    "The app's entry point. Receives lifecycle callbacks from macOS (launch, quit). Creates AppState, TimerService, WindowManager, and sets up global + local double-Fn keyboard shortcuts.",
  AppState:
    "Thin coordinator (@Observable) holding three sub-states: SettingsState, SidebarState, and EditorState. Cross-cutting methods like selectFile and loadFiles live here. Views access sub-state via appState.settings, appState.sidebar, appState.editor.",
  TimerService:
    "Manages the focus timer and owns screen routing (todos vs home). Tracks elapsed time, start/pause/complete. Provides compound intents (startTodo, toggleTodo, completeAndMarkDone) so views stay dumb. Persists sessions to SQLite via an injectable DatabaseService.",
  WindowManager:
    "Controls the menu bar icon and the floating overlay panel. Manages the status bar icon (custom drawn logo), left-click toggle, right-click context menu, animated show/hide transitions, and per-Space window frame persistence. Sets up native title bar controls (sidebar toggle, active task label) on the panel. Conforms to NSWindowDelegate to track panel close events.",
  NoteFile:
    "A simple data model (struct) representing a single markdown file. Holds the URL, display name, and a unique ID.",
  FileWatcher:
    "Monitors files/directories for changes using GCD's DispatchSource. Triggers a callback when a file is written, renamed, or deleted.",
  DatabaseService:
    "SQLite wrapper that stores timer sessions and app key-value state. Uses a shared singleton for production, but accepts a custom path (or :memory:) for test isolation. Handles session CRUD, pause/resume persistence, and aggregate time queries.",
  FloatingPanel:
    "A custom NSPanel subclass for the overlay window. Uses fullSizeContentView for a seamless title bar, repositions traffic light buttons, and hosts native title bar elements: a sidebar toggle NSButton and a centered SwiftUI active task label (via NSHostingView). Also includes TitleBarButton, an NSButton subclass that overrides mouseDownCanMoveWindow to receive clicks in the title bar.",
  MainView:
    "The root SwiftUI view. Contains the sidebar, content area, and switches between notes, settings, and timer views. Registers a hidden Cmd+B shortcut for sidebar toggle.",
  SidebarView:
    "Displays the list of markdown files as a navigable sidebar. The sidebar sits below the native title bar, which hosts its own toggle button and active task label.",
  NoteContentView:
    "Toggleable edit/preview mode for notes. In edit mode, shows MarkdownEditorView (an NSTextView wrapper with auto-continuing bullets). In preview mode, shows MarkdownPreviewView with clickable checkboxes and styled headings. Cmd+E toggles between modes.",
  SettingsView:
    "User preferences UI \u2014 theme, typography, accent color, vault folder picker, keyboard shortcut reference.",
  TimerContainerView:
    "Parent view for the timer feature. Reads TimerService.screen to switch between the timer home and todo list sub-views with animated transitions.",
  TimerHomeView: "Shows the active timer with elapsed time, pause/resume/complete controls.",
  TimerTodosView:
    "Lists all todos extracted from markdown files with search, hide-done filter, and source file filter. Each todo can start a focus timer.",
  TodoRow:
    "A single todo item row with checkbox, text, accumulated time, and a play button to start timing.",
  MarkdownParser:
    "Utility enum (namespace) with static methods to parse markdown into blocks for preview rendering, extract todos, and toggle todo checkboxes. The MarkdownBlock enum models headings, todos, bullets, code blocks, blockquotes, and paragraphs.",
};

export const FILE_MAP: Record<string, string> = {
  AppDelegate: "App/AppDelegate.swift",
  AppState: "App/AppState.swift",
  TimerService: "Services/TimerService.swift",
  WindowManager: "Window/WindowManager.swift",
  FloatingPanel: "Window/FloatingPanel.swift",
  TitleBarLabel: "Views/TitleBarView.swift",
  MainView: "Views/MainView.swift",
  NoteContentView: "Views/NoteContentView.swift",
  NoteFile: "Models/NoteFile.swift",
  FileWatcher: "Services/FileWatcher.swift",
  MarkdownParser: "Services/MarkdownParser.swift",
};
