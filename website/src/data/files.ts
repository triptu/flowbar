export const FILES: Record<string, string> = {
  "App/FlowbarApp.swift": `import SwiftUI

@main
struct FlowbarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}`,

  "App/AppDelegate.swift": `import AppKit
import SwiftUI

/// App entry point that wires together the core services and the menu bar item.
///
/// Creates AppState, TimerService, and WindowManager on launch, then sets up
/// the double-Fn global keyboard shortcut to toggle the overlay from anywhere.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager: WindowManager!
    var appState: AppState!
    var timerService: TimerService!
    private var globalFnMonitor: Any?
    private var localFnMonitor: Any?
    private var lastFnPress: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()
        timerService = TimerService()
        windowManager = WindowManager(appState: appState, timerService: timerService)
        setupDoubleFnShortcut()
    }

    private func handleFnEvent(_ event: NSEvent) {
        let fnPressed = event.modifierFlags.contains(.function)
        let otherMods: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
        guard event.modifierFlags.intersection(otherMods).isEmpty else { return }

        if fnPressed {
            let now = Date()
            if let last = lastFnPress, now.timeIntervalSince(last) < 0.4 {
                lastFnPress = nil
                windowManager.togglePanel()
            } else {
                lastFnPress = now
            }
        }
    }

    private func setupDoubleFnShortcut() {
        // Global monitor fires when another app is focused
        globalFnMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return }
            DispatchQueue.main.async { self.handleFnEvent(event) }
        }
        // Local monitor fires when Flowbar itself is focused
        localFnMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFnEvent(event)
            return event
        }
    }
}`,

  "App/AppState.swift": `import SwiftUI
import Observation

enum AppTheme: String, CaseIterable {
    case light, dark, system
}

enum ActivePanel: Equatable {
    case file(NoteFile)
    case settings
    case timer
    case empty
}

/// Thin coordinator that holds the three sub-states and provides cross-cutting methods.
///
/// Views access sub-state via appState.settings, appState.sidebar, appState.editor.
/// Methods that touch multiple sub-states (selectFile, createNewFile, etc.) live here.
@Observable
@MainActor
final class AppState {
    let settings: SettingsState
    let sidebar: SidebarState
    let editor: EditorState

    init(defaults: UserDefaults = .standard) {
        self.settings = SettingsState(defaults: defaults)
        self.sidebar = SidebarState(defaults: defaults)
        self.editor = EditorState()
        loadFiles()
    }

    func setFolderPath(_ path: String) {
        settings.folderPath = path
        loadFiles()
    }

    func loadFiles() {
        guard !settings.folderPath.isEmpty else {
            sidebar.noteFiles = []
            return
        }

        let url = URL(fileURLWithPath: settings.folderPath)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            sidebar.noteFiles = []
            return
        }

        sidebar.noteFiles = contents
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
            .map { NoteFile(url: $0) }

        editor.watchDirectory(at: url) { [weak self] in
            Task { @MainActor in
                self?.loadFiles()
            }
        }

        if case .empty = sidebar.activePanel, let first = sidebar.noteFiles.first {
            selectFile(first)
        }
    }

    func selectFile(_ file: NoteFile) {
        sidebar.activePanel = .file(file)
        editor.loadFileContent(file)
        editor.watchFile(file) { [weak self] in
            guard let self else { return }
            guard let current = self.sidebar.selectedFile, current.id == file.id else { return }
            self.editor.loadFileContent(file)
        }
    }

    func showSettings() { sidebar.showSettings() }
    func showTimer() { sidebar.showTimer() }
    func toggleSidebar() { sidebar.toggleSidebar() }

    func returnToFiles() {
        if let file = sidebar.noteFiles.first {
            selectFile(file)
        } else {
            sidebar.activePanel = .empty
        }
    }

    func saveFileContent() {
        editor.saveFileContent(for: sidebar.selectedFile)
    }

    func openInObsidian() {
        guard let file = sidebar.selectedFile else { return }
        let vaultPath = URL(fileURLWithPath: settings.folderPath).deletingLastPathComponent()
        let vaultName = vaultPath.lastPathComponent
        let relativePath = file.url.lastPathComponent
        let encoded = relativePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? relativePath
        let folderName = URL(fileURLWithPath: settings.folderPath).lastPathComponent

        if let url = URL(string: "obsidian://open?vault=\\(vaultName)&file=\\(folderName)/\\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}`,

  "App/SettingsState.swift": `import SwiftUI
import Observation

/// Persisted user preferences — theme, typography, accent color, folder path, window frames.
///
/// Each property writes to UserDefaults via didSet. The defaults instance is injectable
/// so tests can pass a throwaway suite.
@Observable
@MainActor
final class SettingsState {
    @ObservationIgnored let defaults: UserDefaults

    var folderPath: String {
        didSet { defaults.set(folderPath, forKey: "folderPath") }
    }
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: "theme") }
    }
    var typography: TypographySize {
        didSet { defaults.set(typography.rawValue, forKey: "typography") }
    }
    var accentColor: AccentColor {
        didSet { defaults.set(accentColor.rawValue, forKey: "accentColor") }
    }

    /// Reactive accent color — views should use this instead of reading from a static.
    var accent: Color { accentColor.color }

    /// Per-Space window frames: [SpaceID: [x, y, width, height]]
    @ObservationIgnored var windowFrames: [String: [Double]] {
        didSet { defaults.set(windowFrames, forKey: "windowFrames") }
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    static let defaultWindowSize = NSSize(width: 700, height: 500)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.folderPath = defaults.string(forKey: "folderPath") ?? ""
        self.theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .dark
        self.typography = TypographySize(rawValue: defaults.string(forKey: "typography") ?? "") ?? .default
        self.accentColor = AccentColor(rawValue: defaults.string(forKey: "accentColor") ?? "") ?? .sage
        self.windowFrames = defaults.object(forKey: "windowFrames") as? [String: [Double]] ?? [:]
    }

    func windowFrame(forSpace spaceID: Int) -> NSRect? {
        guard let vals = windowFrames[String(spaceID)], vals.count == 4 else { return nil }
        return NSRect(x: vals[0], y: vals[1], width: vals[2], height: vals[3])
    }

    func saveWindowFrame(_ frame: NSRect, forSpace spaceID: Int) {
        let newVal = [
            Double(frame.origin.x), Double(frame.origin.y),
            Double(frame.width), Double(frame.height)
        ]
        let key = String(spaceID)
        guard windowFrames[key] != newVal else { return }
        windowFrames[key] = newVal
    }
}`,

  "App/EditorState.swift": `import SwiftUI
import Observation

/// Manages the active file's text content, debounced saving, and file watchers.
///
/// Watches the currently-open file for external edits (e.g. from Obsidian).
/// An isWriting flag prevents the watcher from reloading content we just saved.
/// Also owns the directory watcher that refreshes the file list when files change on disk.
@Observable
@MainActor
final class EditorState {
    var editorContent: String = ""
    var isEditing = false

    @ObservationIgnored private var saveTask: DispatchWorkItem?
    @ObservationIgnored private var isWriting = false
    @ObservationIgnored private var dirWatcher: FileWatcher?
    @ObservationIgnored private var dirWatcherURL: URL?
    @ObservationIgnored private var dirWatcherSuppressCount = 0
    @ObservationIgnored private var fileWatcher: FileWatcher?
    @ObservationIgnored private var externalChangeHandler: (() -> Void)?

    func loadFileContent(_ file: NoteFile) {
        saveTask?.cancel()
        saveTask = nil
        isWriting = false
        isEditing = false

        if let content = try? String(contentsOf: file.url, encoding: .utf8) {
            editorContent = content
        }
    }

    func saveFileContent(for file: NoteFile?) {
        guard let file else { return }
        saveTask?.cancel()
        isWriting = true
        let contentToSave = editorContent
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            DispatchQueue.global(qos: .utility).async { [weak self] in
                try? contentToSave.write(to: file.url, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.rearmFileWatcher(file)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        self?.isWriting = false
                    }
                }
            }
        }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    func watchFile(_ file: NoteFile, onExternalChange: @escaping () -> Void) {
        externalChangeHandler = onExternalChange
        rearmFileWatcher(file)
    }

    private func rearmFileWatcher(_ file: NoteFile) {
        let handler = externalChangeHandler
        fileWatcher = FileWatcher(url: file.url) { [weak self] in
            Task { @MainActor in
                guard let self, !self.isWriting else { return }
                handler?()
            }
        }
    }

    func suppressNextDirectoryEvent() {
        dirWatcherSuppressCount += 1
    }

    func watchDirectory(at url: URL, onDirectoryChange: @escaping () -> Void) {
        guard dirWatcherURL != url else { return }
        dirWatcherURL = url
        dirWatcher = FileWatcher(url: url) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.dirWatcherSuppressCount > 0 {
                    self.dirWatcherSuppressCount -= 1
                    return
                }
                onDirectoryChange()
            }
        }
    }
}`,

  "App/SidebarState.swift": `import SwiftUI
import Observation

/// UI navigation, sidebar layout, file list, and rename state.
///
/// Owns the file list, active panel selection, sidebar visibility/width,
/// and inline-rename state. Does NOT own file content or persistence —
/// those live in EditorState and SettingsState respectively.
@Observable
@MainActor
final class SidebarState {
    @ObservationIgnored let defaults: UserDefaults

    // MARK: - Sidebar layout (persisted)

    var sidebarVisible: Bool {
        didSet { if sidebarVisible != oldValue { defaults.set(sidebarVisible, forKey: "sidebarVisible") } }
    }
    var sidebarWidth: Double {
        didSet { if sidebarWidth != oldValue { defaults.set(sidebarWidth, forKey: "sidebarWidth") } }
    }

    // MARK: - Navigation (single source of truth)

    var activePanel: ActivePanel = .empty

    var selectedFile: NoteFile? {
        if case .file(let f) = activePanel { return f }
        return nil
    }

    // MARK: - Files

    var noteFiles: [NoteFile] = []

    // MARK: - Rename

    var renamingFileID: String?
    var renameText = ""
    var renameSessionID = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.sidebarVisible = defaults.object(forKey: "sidebarVisible") as? Bool ?? true
        self.sidebarWidth = defaults.object(forKey: "sidebarWidth") as? Double ?? 200
    }

    func showSettings() {
        activePanel = .settings
    }

    func showTimer() {
        activePanel = .timer
    }

    func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            sidebarVisible.toggle()
        }
    }

    func startRename(_ file: NoteFile) {
        renameText = file.name
        renameSessionID += 1
        renamingFileID = file.id
    }

    func cancelRename() {
        renamingFileID = nil
    }
}`,

  "Models/NoteFile.swift": `import Foundation

/// Represents a single markdown file in the configured folder.
/// Used throughout the app for sidebar listing, note editing, and todo source tracking.
struct NoteFile: Identifiable, Hashable {
    let id: String       // filename without .md extension
    let url: URL         // full file path
    var name: String { id }

    init(url: URL) {
        self.url = url
        self.id = url.deletingPathExtension().lastPathComponent
    }
}`,

  "Services/FileWatcher.swift": `import Foundation

/// Watches a single file or directory for filesystem changes using GCD dispatch sources.
///
/// Used by EditorState to watch the notes directory (for new/deleted files) and the
/// currently selected file (for external edits, e.g. from Obsidian). Each watcher
/// opens a file descriptor and fires the onChange callback on the main queue.
@MainActor
final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let onChange: @MainActor () -> Void

    init(url: URL, onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
        startWatching(url: url)
    }

    deinit {
        source?.cancel()
    }

    func startWatching(url: URL) {
        stopWatching()
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: .main
        )
        source?.setEventHandler { [weak self] in
            self?.onChange()
        }
        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }
        source?.resume()
    }

    func stopWatching() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }
}`,

  "Services/MarkdownParser.swift": `import Foundation

/// A parsed markdown block for rendering in the preview.
enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case todo(isDone: Bool, text: String, lineIndex: Int, indent: Int)
    case bullet(text: String, indent: Int)
    case numbered(number: Int, text: String, indent: Int)
    case codeBlock(String)
    case blockquote(String)
    case horizontalRule
    case paragraph(String)
    case empty
}

/// Reads and writes markdown files to extract/toggle todos.
///
/// Also parses markdown into blocks for preview rendering.
/// All methods are static — no instance state.
/// Uses "\\n" splitting consistently to match how files are written back.
enum MarkdownParser {

    // MARK: - Block parsing

    static func parseBlocks(from content: String) -> [MarkdownBlock] {
        let lines = content.components(separatedBy: "\\n")
        var blocks: [MarkdownBlock] = []
        var inCodeBlock = false
        var codeLines: [String] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code fence toggle
            if trimmed.hasPrefix("\\\`\\\`\\\`") {
                if inCodeBlock {
                    blocks.append(.codeBlock(codeLines.joined(separator: "\\n")))
                    codeLines = []
                }
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock {
                codeLines.append(line)
                continue
            }

            let indent = line.prefix(while: { $0 == " " || $0 == "\\t" }).count

            if trimmed.isEmpty {
                blocks.append(.empty)
            } else if let (level, text) = parseHeading(trimmed) {
                blocks.append(.heading(level: level, text: text))
            } else if trimmed.hasPrefix("- [ ] ") {
                blocks.append(.todo(isDone: false, text: String(trimmed.dropFirst(6)), lineIndex: index, indent: indent))
            } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                blocks.append(.todo(isDone: true, text: String(trimmed.dropFirst(6)), lineIndex: index, indent: indent))
            } else if isHorizontalRule(trimmed) {
                blocks.append(.horizontalRule)
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(.bullet(text: String(trimmed.dropFirst(2)), indent: indent))
            } else if let (num, text) = parseNumberedList(trimmed) {
                blocks.append(.numbered(number: num, text: text, indent: indent))
            } else if trimmed.hasPrefix("> ") {
                blocks.append(.blockquote(String(trimmed.dropFirst(2))))
            } else {
                blocks.append(.paragraph(trimmed))
            }
        }

        // Close unclosed code block
        if inCodeBlock && !codeLines.isEmpty {
            blocks.append(.codeBlock(codeLines.joined(separator: "\\n")))
        }

        return blocks
    }

    private static func parseHeading(_ line: String) -> (Int, String)? {
        let hashes = line.prefix(while: { $0 == "#" })
        let level = hashes.count
        guard level >= 1, level <= 6, line.dropFirst(level).hasPrefix(" ") else { return nil }
        return (level, String(line.dropFirst(level + 1)))
    }

    private static func parseNumberedList(_ line: String) -> (Int, String)? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let numStr = String(line[line.startIndex..<dotIndex])
        guard let num = Int(numStr),
              line.index(after: dotIndex) < line.endIndex,
              line[line.index(after: dotIndex)...].hasPrefix(" ") else { return nil }
        let textStart = line.index(dotIndex, offsetBy: 2)
        return (num, String(line[textStart...]))
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let stripped = line.filter { $0 != " " }
        return stripped.count >= 3 && stripped.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" })
            && Set(stripped).count == 1
    }

    // MARK: - Line-level todo toggle

    /// Toggles a single line between - [ ] and - [x]. Returns the toggled line, or nil if not a todo.
    static func toggleTodoLine(_ line: String) -> String? {
        if line.contains("- [ ] ") {
            return line.replacingOccurrences(of: "- [ ] ", with: "- [x] ")
        } else if line.contains("- [x] ") || line.contains("- [X] ") {
            return line.replacingOccurrences(of: "- [x] ", with: "- [ ] ")
                .replacingOccurrences(of: "- [X] ", with: "- [ ] ")
        }
        return nil
    }

    // MARK: - Todo extraction
    static func extractTodos(from url: URL, noteFile: NoteFile) -> [TodoItem] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let lines = content.components(separatedBy: "\\n")
        var todos: [TodoItem] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- [ ] ") {
                let text = String(trimmed.dropFirst(6))
                todos.append(TodoItem(text: text, isDone: false, sourceFile: noteFile, lineIndex: index))
            } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                let text = String(trimmed.dropFirst(6))
                todos.append(TodoItem(text: text, isDone: true, sourceFile: noteFile, lineIndex: index))
            }
        }
        return todos
    }

    static func toggleTodo(at lineIndex: Int, in url: URL) -> Bool {
        guard var content = try? String(contentsOf: url, encoding: .utf8) else { return false }
        var lines = content.components(separatedBy: "\\n")
        guard lineIndex < lines.count,
              let toggled = toggleTodoLine(lines[lineIndex]) else { return false }
        lines[lineIndex] = toggled
        content = lines.joined(separator: "\\n")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    /// Toggle a todo at the given line index, but only if the line is still - [ ] <text>.
    static func toggleTodoIfMatches(text: String, at lineIndex: Int, in url: URL) -> Bool {
        guard var content = try? String(contentsOf: url, encoding: .utf8) else { return false }
        var lines = content.components(separatedBy: "\\n")
        guard lineIndex < lines.count else { return false }
        let trimmed = lines[lineIndex].trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- [ ] ") && String(trimmed.dropFirst(6)) == text else { return false }
        lines[lineIndex] = lines[lineIndex].replacingOccurrences(of: "- [ ] ", with: "- [x] ")
        content = lines.joined(separator: "\\n")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    /// Find a specific incomplete todo by text and mark it done. Single read+write.
    static func markTodoDone(text: String, in url: URL) {
        guard var content = try? String(contentsOf: url, encoding: .utf8) else { return }
        var lines = content.components(separatedBy: "\\n")
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- [ ] ") && String(trimmed.dropFirst(6)) == text {
                lines[index] = line.replacingOccurrences(of: "- [ ] ", with: "- [x] ")
                content = lines.joined(separator: "\\n")
                try? content.write(to: url, atomically: true, encoding: .utf8)
                return
            }
        }
    }
}`,

  "Services/TimerService.swift": `import Foundation
import Observation

/// Manages the stopwatch timer for tracking time spent on todos.
///
/// Owns all timer state, screen routing, and compound intents (startTodo, toggleTodo,
/// completeAndMarkDone). Views should be dumb — read state and call intent methods.
/// Persists sessions to SQLite via DatabaseService. Side-effects on markdown files
/// happen here so behavior is testable in one place.
@Observable
@MainActor
final class TimerService {
    enum Screen { case todos, home }

    var isRunning = false
    var isPaused = false
    var currentTodoText = ""
    var currentSourceFile = ""
    var elapsed: TimeInterval = 0
    var screen: Screen = .todos

    /// True when a timer session exists (running or paused)
    var hasActiveSession: Bool { isRunning || isPaused }

    @ObservationIgnored private var sessionId: Int64?
    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var pausedElapsed: TimeInterval = 0
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var currentLineIndex: Int?
    @ObservationIgnored private let db: DatabaseService

    init(db: DatabaseService = .shared) {
        self.db = db
        restoreActiveSession()
    }

    private func restoreActiveSession() {
        if let session = db.activeSession() {
            sessionId = session.id
            currentTodoText = session.todoText
            currentSourceFile = session.sourceFile
            if let paused = session.pausedElapsed {
                pausedElapsed = paused
                elapsed = paused
                isPaused = true
            } else {
                pausedElapsed = session.accumulated
                startedAt = session.startedAt
                isRunning = true
                startTicking()
            }
            screen = .home
        }
    }

    // MARK: - Primitive state transitions

    func start(todoText: String, sourceFile: String) {
        if hasActiveSession { stopSession() }
        sessionId = db.startSession(todoText: todoText, sourceFile: sourceFile)
        currentTodoText = todoText
        currentSourceFile = sourceFile
        currentLineIndex = nil
        startedAt = Date()
        elapsed = 0
        pausedElapsed = 0
        isRunning = true
        isPaused = false
        startTicking()
    }

    func pause() {
        guard isRunning, let id = sessionId else { return }
        timer?.invalidate()
        timer = nil
        pausedElapsed = elapsed
        isRunning = false
        isPaused = true
        db.pauseSession(id: id, elapsed: elapsed)
    }

    func resume() {
        guard isPaused, let id = sessionId else { return }
        startedAt = Date()
        isRunning = true
        isPaused = false
        db.resumeSession(id: id)
        startTicking()
    }

    /// Toggle between running and paused states. No-op if no active session.
    func togglePlayPause() {
        if isRunning { pause() } else if isPaused { resume() }
    }

    /// Ends the session without marking the todo done. Clears all state.
    func clear() {
        guard hasActiveSession, let id = sessionId else { return }
        db.endSession(id: id, completed: false, finalElapsed: elapsed)
        cleanup()
    }

    /// Check if a specific todo is being tracked (running or paused)
    func isTracking(todoText: String, sourceFile: String) -> Bool {
        hasActiveSession && currentTodoText == todoText && currentSourceFile == sourceFile
    }

    func toggleScreen() {
        screen = (screen == .todos) ? .home : .todos
    }

    /// Ends the session as completed in the database and clears state.
    @discardableResult
    func complete() -> (todoText: String, sourceFile: String)? {
        guard hasActiveSession, let id = sessionId else { return nil }
        let result = (todoText: currentTodoText, sourceFile: currentSourceFile)
        db.endSession(id: id, completed: true, finalElapsed: elapsed)
        cleanup()
        return result
    }

    // MARK: - Compound intents (absorb view-layer business logic)

    /// Start tracking a todo. If already tracking this one, toggle play/pause.
    /// If the todo is done, un-mark it first.
    func startTodo(_ todo: TodoItem) {
        if isTracking(todoText: todo.text, sourceFile: todo.sourceFile.id) {
            togglePlayPause()
        } else {
            if todo.isDone {
                _ = MarkdownParser.toggleTodo(at: todo.lineIndex, in: todo.sourceFile.url)
            }
            start(todoText: todo.text, sourceFile: todo.sourceFile.id)
            currentLineIndex = todo.lineIndex
        }
    }

    /// Toggle a todo's checkbox. If toggling off the currently tracked todo, stop the timer.
    func toggleTodo(_ todo: TodoItem) {
        if !todo.isDone && isTracking(todoText: todo.text, sourceFile: todo.sourceFile.id) {
            clear()
        }
        _ = MarkdownParser.toggleTodo(at: todo.lineIndex, in: todo.sourceFile.url)
    }

    /// Complete the active session, mark the todo done in the markdown file, and clear state.
    func completeAndMarkDone(folderPath: String) {
        let lineIndex = currentLineIndex
        guard let result = complete() else { return }

        let fileURL = URL(fileURLWithPath: folderPath)
            .appendingPathComponent(result.sourceFile + ".md")
        if let idx = lineIndex, MarkdownParser.toggleTodoIfMatches(text: result.todoText, at: idx, in: fileURL) {
            // Done — single file read+write
        } else {
            MarkdownParser.markTodoDone(text: result.todoText, in: fileURL)
        }
    }

    // MARK: - Private helpers

    private func stopSession() {
        if let id = sessionId { db.endSession(id: id, completed: false, finalElapsed: elapsed) }
        timer?.invalidate()
        timer = nil
    }

    private func cleanup() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        sessionId = nil
        startedAt = nil
        elapsed = 0
        pausedElapsed = 0
        currentTodoText = ""
        currentSourceFile = ""
        currentLineIndex = nil
        screen = .todos
    }

    private func startTicking() {
        timer?.invalidate()
        let base = pausedElapsed
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.startedAt else { return }
                self.elapsed = base + Date().timeIntervalSince(start)
            }
        }
    }

    // MARK: - Queries

    func totalTime(forTodo text: String, sourceFile: String) -> TimeInterval {
        db.totalTime(forTodo: text, sourceFile: sourceFile)
    }

    /// Batch query: get total time for all todos at once (avoids N+1)
    func allTotalTimes() -> [String: TimeInterval] {
        db.allTotalTimes()
    }

    /// Today's completed sessions grouped by todo, most recent first
    func todaySessions() -> [(todoText: String, sourceFile: String, totalDuration: TimeInterval)] {
        db.todaySessions()
    }

    nonisolated static func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
}`,

  "Views/MainView.swift": `import SwiftUI

/// Root view that combines the sidebar and content area.
///
/// Title bar content (sidebar toggle, active task label) is handled natively
/// by FloatingPanel. This view just manages the sidebar and content panels.
struct MainView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        HStack(spacing: 0) {
            if appState.sidebar.sidebarVisible {
                SidebarView()
                    .frame(width: CGFloat(appState.sidebar.sidebarWidth))
                    .transition(.move(edge: .leading).combined(with: .opacity))

                SidebarDivider()
            }

            Group {
                switch appState.sidebar.activePanel {
                case .settings:
                    SettingsView()
                case .timer:
                    TimerContainerView()
                case .file:
                    NoteContentView()
                case .empty:
                    emptyState
                }
            }
            .accessibilityIdentifier("content-area")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            Rectangle().fill(.regularMaterial).ignoresSafeArea(.all, edges: .top)
        }
        .preferredColorScheme(appState.settings.preferredColorScheme)
        .background(keyboardShortcuts)
    }

    @ViewBuilder
    private var keyboardShortcuts: some View {
        Group {
            Button("") { appState.toggleSidebar() }
                .keyboardShortcut("b", modifiers: .command)
            Button("") { appState.selectPreviousFile() }
                .keyboardShortcut(.leftArrow, modifiers: [.option, .command])
            Button("") { appState.selectNextFile() }
                .keyboardShortcut(.rightArrow, modifiers: [.option, .command])
            Button("") { appState.showSettings() }
                .keyboardShortcut(",", modifiers: .command)
            Button("") { appState.editor.isEditing.toggle() }
                .keyboardShortcut("e", modifiers: .command)
            Button("") { appState.showTimer() }
                .keyboardShortcut("t", modifiers: [.option, .command])
        }
        .hidden()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Select a folder in Settings")
                .foregroundStyle(.secondary)
        }
    }
}`,

  "Views/NoteContentView.swift": `import SwiftUI

struct NoteContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            noteHeader
            Divider().opacity(0.2)

            if appState.editor.isEditing {
                MarkdownEditorView(
                    text: Binding(
                        get: { appState.editor.editorContent },
                        set: { appState.editor.editorContent = $0 }
                    ),
                    font: .systemFont(ofSize: appState.settings.typography.bodySize),
                    onTextChange: { appState.saveFileContent() }
                )
            } else {
                MarkdownPreviewView(
                    content: appState.editor.editorContent,
                    bodySize: appState.settings.typography.bodySize,
                    accentColor: appState.settings.accent,
                    onToggleTodo: { lineIndex in
                        toggleTodoInContent(at: lineIndex)
                    }
                )
            }
        }
    }

    private func toggleTodoInContent(at lineIndex: Int) {
        var lines = appState.editor.editorContent.components(separatedBy: "\\n")
        guard lineIndex < lines.count,
              let toggled = MarkdownParser.toggleTodoLine(lines[lineIndex]) else { return }
        lines[lineIndex] = toggled
        appState.editor.editorContent = lines.joined(separator: "\\n")
        appState.saveFileContent()
    }

    private var noteHeader: some View {
        HStack(spacing: 10) {
            Text(appState.sidebar.selectedFile?.name ?? "")
                .font(.system(size: appState.settings.typography.titleSize, weight: .bold))

            Spacer()

            // Edit/Preview toggle
            Button(action: { appState.editor.isEditing.toggle() }) {
                Image(systemName: appState.editor.isEditing ? "eye" : "pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button(action: { appState.openInObsidian() }) {
                ObsidianIcon()
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, appState.sidebar.sidebarVisible ? 20 : FloatingPanel.trafficLightWidth)
        .padding(.trailing, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}`,

  "Views/MarkdownEditorView.swift": `import SwiftUI
import AppKit

/// NSTextView wrapper that auto-continues bullets and todos on Enter.
///
/// When the user presses Return on a line starting with - [ ] , - , * , or 1. ,
/// the next line automatically gets the same prefix (with incremented numbers for ordered lists).
/// Pressing Return on an empty bullet/todo line removes it instead of continuing.
struct MarkdownEditorView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var onTextChange: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.font = font
        textView.string = text
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text && !context.coordinator.isUpdating {
            context.coordinator.isUpdating = true
            textView.string = text
            textView.font = font
            context.coordinator.isUpdating = false
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditorView
        weak var textView: NSTextView?
        var isUpdating = false

        init(_ parent: MarkdownEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = textView.string
            parent.onTextChange()
            isUpdating = false
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                return handleNewline(textView)
            }
            return false
        }

        private func handleNewline(_ textView: NSTextView) -> Bool {
            let nsText = textView.string as NSString
            let cursorLocation = textView.selectedRange().location
            let lineRange = nsText.lineRange(for: NSRange(location: cursorLocation, length: 0))
            let currentLine = nsText.substring(with: lineRange).replacingOccurrences(of: "\\n", with: "")

            let leadingWhitespace = String(currentLine.prefix(while: { $0 == " " || $0 == "\\t" }))
            let trimmed = currentLine.trimmingCharacters(in: .whitespaces)

            // Empty bullet/todo — remove the prefix and just insert newline
            let emptyPrefixes = ["-", "- [ ]", "- [x]", "- [X]", "*"]
            if emptyPrefixes.contains(trimmed) || isEmptyNumberedItem(trimmed) {
                textView.setSelectedRange(lineRange)
                textView.insertText("\\n", replacementRange: textView.selectedRange())
                return true
            }

            // Determine continuation prefix
            var prefix = ""
            if trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                prefix = leadingWhitespace + "- [ ] "
            } else if trimmed.hasPrefix("- ") {
                prefix = leadingWhitespace + "- "
            } else if trimmed.hasPrefix("* ") {
                prefix = leadingWhitespace + "* "
            } else if let nextNum = nextNumberedPrefix(trimmed) {
                prefix = leadingWhitespace + nextNum
            }

            if !prefix.isEmpty {
                textView.insertText("\\n" + prefix, replacementRange: textView.selectedRange())
                return true
            }

            return false
        }

        private func isEmptyNumberedItem(_ line: String) -> Bool {
            guard let dotIndex = line.firstIndex(of: ".") else { return false }
            let numPart = String(line[line.startIndex..<dotIndex])
            guard Int(numPart) != nil else { return false }
            let rest = line[line.index(after: dotIndex)...]
            return rest.isEmpty || rest == " "
        }

        private func nextNumberedPrefix(_ line: String) -> String? {
            guard let dotIndex = line.firstIndex(of: ".") else { return nil }
            let numStr = String(line[line.startIndex..<dotIndex])
            guard let num = Int(numStr),
                  line.index(after: dotIndex) < line.endIndex,
                  line[line.index(after: dotIndex)...].hasPrefix(" ") else { return nil }
            return "\\(num + 1). "
        }
    }
}`,

  "Views/MarkdownPreviewView.swift": `import SwiftUI

/// Renders markdown content as native SwiftUI views with clickable checkboxes and styled headings.
struct MarkdownPreviewView: View {
    let content: String
    let bodySize: CGFloat
    let accentColor: Color
    let onToggleTodo: (Int) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(MarkdownParser.parseBlocks(from: content).enumerated()), id: \\.offset) { _, block in
                    blockView(block)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Block views

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)
        case .todo(let isDone, let text, let lineIndex, let indent):
            todoView(isDone: isDone, text: text, lineIndex: lineIndex, indent: indent)
        case .bullet(let text, let indent):
            bulletView(text: text, indent: indent)
        case .numbered(let number, let text, let indent):
            numberedView(number: number, text: text, indent: indent)
        case .codeBlock(let code):
            codeBlockView(code)
        case .blockquote(let text):
            blockquoteView(text)
        case .horizontalRule:
            Divider().padding(.vertical, 4)
        case .paragraph(let text):
            inlineMarkdown(text)
                .font(.system(size: bodySize))
        case .empty:
            Spacer().frame(height: bodySize * 0.5)
        }
    }

    private func todoView(isDone: Bool, text: String, lineIndex: Int, indent: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Button(action: { onToggleTodo(lineIndex) }) {
                Image(systemName: isDone ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isDone ? accentColor : .secondary)
                    .font(.system(size: bodySize))
            }
            .buttonStyle(.plain)

            inlineMarkdown(text)
                .font(.system(size: bodySize))
                .strikethrough(isDone)
                .foregroundStyle(isDone ? .secondary : .primary)
        }
        .padding(.leading, indentPadding(indent))
        .padding(.vertical, 1)
    }

    private func bulletView(text: String, indent: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\\u{2022}")
                .foregroundStyle(.secondary)
            inlineMarkdown(text)
                .font(.system(size: bodySize))
        }
        .padding(.leading, indentPadding(indent))
    }

    /// Converts character-level indent (spaces/tabs) to padding.
    private func indentPadding(_ indent: Int) -> CGFloat {
        CGFloat(indent / 2) * 12
    }

    private func codeBlockView(_ code: String) -> some View {
        Text(code)
            .font(.system(size: bodySize - 1, design: .monospaced))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.vertical, 4)
    }

    private func blockquoteView(_ text: String) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(accentColor.opacity(0.5))
                .frame(width: 3)
            inlineMarkdown(text)
                .font(.system(size: bodySize))
                .foregroundStyle(.secondary)
                .padding(.leading, 10)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Inline markdown

    private func inlineMarkdown(_ text: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed)
        } else {
            return Text(text)
        }
    }
}`,

  "Views/TitleBarView.swift": `import SwiftUI

/// Active task label displayed centered in the native title bar.
/// Hosted as an NSHostingView added to the title bar view hierarchy by FloatingPanel.
struct TitleBarLabel: View {
    @Environment(TimerService.self) var timerService
    @Environment(AppState.self) var appState

    private var isTimerPanel: Bool {
        if case .timer = appState.sidebar.activePanel { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if timerService.hasActiveSession {
                    HStack(spacing: 6) {
                        Text(TimerService.formatTime(timerService.elapsed))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(truncated(timerService.currentTodoText, limit: 25))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                } else {
                    Text("No active task")
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.system(size: 13))
            .contentShape(Rectangle())
            .onTapGesture { appState.showTimer() }
            .frame(maxWidth: .infinity)

            if isTimerPanel {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        timerService.toggleScreen()
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11))
                        .foregroundStyle(timerService.screen == .todos ? .primary : .secondary)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(timerService.screen == .todos ? appState.settings.accent : Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
        }
        .padding(.leading, appState.sidebar.sidebarVisible ? CGFloat(appState.sidebar.sidebarWidth) + 5 : 0)
    }

    private func truncated(_ text: String, limit: Int) -> String {
        text.count > limit ? String(text.prefix(limit)) + "…" : text
    }
}`,

  "Window/WindowManager.swift": `import AppKit
import SwiftUI
import Observation

/// Manages the menu bar status item and the floating overlay panel.
///
/// Owns the NSStatusItem (menu bar icon). Clicking the icon or pressing
/// double-Fn toggles the overlay panel on/off. Remembers window position
/// and size per desktop Space. Injected via .environment().
@Observable
@MainActor
final class WindowManager: NSObject {
    let statusItem: NSStatusItem

    @ObservationIgnored private var panel: FloatingPanel?
    @ObservationIgnored private var appState: AppState
    @ObservationIgnored private var timerService: TimerService
    @ObservationIgnored private var statusMenu: NSMenu
    @ObservationIgnored private var rightClickMonitor: Any?
    @ObservationIgnored private var isHiding = false

    init(appState: AppState, timerService: TimerService) {
        self.appState = appState
        self.timerService = timerService
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusMenu = NSMenu()
        super.init()

        let openItem = NSMenuItem(title: "Open Flowbar", action: #selector(openFromMenu), keyEquivalent: "")
        openItem.target = self
        statusMenu.addItem(openItem)
        statusMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Flowbar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)

        if let button = statusItem.button {
            button.image = Self.makeMenuBarIcon()
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }

        // Handle right-click separately via event monitor
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { [weak self] event in
            guard let self, let button = self.statusItem.button else { return event }
            let pointInButton = button.convert(event.locationInWindow, from: nil)
            if button.bounds.contains(pointInButton) {
                self.statusItem.menu = self.statusMenu
                button.performClick(nil)
                self.statusItem.menu = nil
                return nil
            }
            return event
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        togglePanel()
    }

    @objc private func openFromMenu() {
        showPanel()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func togglePanel() {
        guard !isHiding else { return }
        if let panel, panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        let spaceID = activeSpaceID()

        // If panel already exists, just bring it forward (it's on all Spaces)
        if let panel {
            panel.alphaValue = 1
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Load saved frame for this Space, or center with default size
        let frame: NSRect
        if let saved = appState.settings.windowFrame(forSpace: spaceID) {
            frame = saved
        } else {
            let size = SettingsState.defaultWindowSize
            let screen = NSScreen.main ?? NSScreen.screens.first!
            frame = NSRect(
                x: screen.frame.midX - size.width / 2,
                y: screen.frame.midY - size.height / 2,
                width: size.width, height: size.height
            )
        }

        let newPanel = FloatingPanel(contentRect: frame, spaceID: spaceID) { [weak self] frame, spaceID in
            self?.appState.settings.saveWindowFrame(frame, forSpace: spaceID)
        }
        let mainView = MainView()
            .environment(appState)
            .environment(timerService)
            .environment(self)
        newPanel.setContent(mainView)
        newPanel.addSidebarToggle { [weak self] in
            self?.appState.toggleSidebar()
        }
        let taskLabel = TitleBarLabel()
            .environment(timerService)
        newPanel.addActiveTaskLabel(taskLabel)
        newPanel.delegate = self
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        panel = newPanel
    }

    func hidePanel() {
        guard let panelToClose = panel else { return }
        isHiding = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            panelToClose.animator().alphaValue = 0
        }) { [weak self] in
            panelToClose.close()
            self?.isHiding = false
        }
    }

    /// Draws the Flowbar logo (river stone with flow groove) as a menu bar template image.
    /// macOS auto-colors template images to match the system appearance.
    private static func makeMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let scale = min(rect.width, rect.height) / 24.0
            let transform = NSAffineTransform()
            transform.scale(by: scale)

            let path = NSBezierPath()
            path.move(to: NSPoint(x: 12, y: 2.5))
            path.curve(to: NSPoint(x: 2.5, y: 12),
                       controlPoint1: NSPoint(x: 7, y: 2.5),
                       controlPoint2: NSPoint(x: 2.5, y: 7))
            path.curve(to: NSPoint(x: 12, y: 21.5),
                       controlPoint1: NSPoint(x: 2.5, y: 17),
                       controlPoint2: NSPoint(x: 7, y: 21.5))
            path.curve(to: NSPoint(x: 21.5, y: 12),
                       controlPoint1: NSPoint(x: 17, y: 21.5),
                       controlPoint2: NSPoint(x: 21.5, y: 17))
            path.curve(to: NSPoint(x: 12, y: 2.5),
                       controlPoint1: NSPoint(x: 21.5, y: 7),
                       controlPoint2: NSPoint(x: 17, y: 2.5))
            path.close()

            let groove = NSBezierPath()
            groove.move(to: NSPoint(x: 3.8, y: 11.2))
            groove.curve(to: NSPoint(x: 10.5, y: 10.8),
                         controlPoint1: NSPoint(x: 7, y: 8.8),
                         controlPoint2: NSPoint(x: 7, y: 8.8))
            groove.curve(to: NSPoint(x: 13.5, y: 12.2),
                         controlPoint1: NSPoint(x: 12, y: 11.8),
                         controlPoint2: NSPoint(x: 12, y: 11.8))
            groove.curve(to: NSPoint(x: 20.2, y: 10.8),
                         controlPoint1: NSPoint(x: 17, y: 13),
                         controlPoint2: NSPoint(x: 17, y: 13))
            groove.line(to: NSPoint(x: 20.2, y: 12.8))
            groove.curve(to: NSPoint(x: 13.5, y: 14.2),
                         controlPoint1: NSPoint(x: 17, y: 15),
                         controlPoint2: NSPoint(x: 17, y: 15))
            groove.curve(to: NSPoint(x: 10.5, y: 12.8),
                         controlPoint1: NSPoint(x: 12, y: 13.8),
                         controlPoint2: NSPoint(x: 12, y: 13.8))
            groove.curve(to: NSPoint(x: 3.8, y: 13.2),
                         controlPoint1: NSPoint(x: 7, y: 10.8),
                         controlPoint2: NSPoint(x: 7, y: 10.8))
            groove.close()

            path.transform(using: transform as AffineTransform)
            groove.transform(using: transform as AffineTransform)

            path.append(groove)
            path.windingRule = .evenOdd
            NSColor.black.setFill()
            path.fill()

            return true
        }
        image.isTemplate = true
        return image
    }
}

// MARK: - NSWindowDelegate
/// Tracks panel close (e.g. via close button or Cmd+W) to clean up.
extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard notification.object as? FloatingPanel === panel else { return }
        panel = nil
        isHiding = false
    }
}`,

  "Window/FloatingPanel.swift": `import AppKit
import SwiftUI

/// The overlay window shown when the user clicks the menu bar icon or presses double-Fn.
///
/// Configured as an always-on-top utility panel that joins all Spaces. Saves its
/// size back via an onClose callback so dimensions persist across sessions.
/// Traffic lights, sidebar toggle, and active task label all live in the native
/// title bar view hierarchy so they receive clicks and align naturally.
class FloatingPanel: NSPanel {
    /// Horizontal offset where traffic lights start (aligned with sidebar item text).
    static let trafficLightX: CGFloat = 20
    /// Width past the traffic lights area. Used by views to inset content.
    static let trafficLightWidth: CGFloat = 80
    /// Height of the native title bar region.
    static let titleBarHeight: CGFloat = 28

    /// Called with (frame, spaceID) when the panel closes, so the caller can persist the window frame.
    private let onClose: (NSRect, Int) -> Void
    private var initialSize: NSSize = .zero
    /// The Space ID this panel was created on, used to save per-Space frame
    let spaceID: Int
    /// Hosting view for the active task label, kept for cleanup
    private var activeTaskHost: NSView?

    init(contentRect: NSRect, spaceID: Int, onClose: @escaping (NSRect, Int) -> Void) {
        self.onClose = onClose
        self.spaceID = spaceID
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        initialSize = contentRect.size
        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        minSize = NSSize(width: 400, height: 300)
    }

    func setContent(_ view: some View) {
        contentView = NSHostingView(rootView: view)
        repositionTrafficLights()
    }

    /// Add a native NSButton to the title bar view hierarchy so it receives clicks.
    /// Placed right after the traffic lights, vertically centered.
    func addSidebarToggle(action: @escaping () -> Void) {
        guard let closeButton = standardWindowButton(.closeButton),
              let titlebarView = closeButton.superview else { return }

        let button = TitleBarButton(action: action)
        button.image = NSImage(
            systemSymbolName: "sidebar.left",
            accessibilityDescription: "Toggle Sidebar"
        )
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.bezelStyle = .inline
        (button.cell as? NSButtonCell)?.highlightsBy = .contentsCellMask
        button.contentTintColor = .secondaryLabelColor

        let size: CGFloat = 20
        let x = Self.trafficLightWidth + 10
        let y = (titlebarView.bounds.height - size) / 2
        button.frame = NSRect(x: x, y: y, width: size, height: size)
        button.autoresizingMask = [.minYMargin]

        titlebarView.addSubview(button)
    }

    /// Add a SwiftUI active task label centered in the title bar.
    func addActiveTaskLabel(_ view: some View) {
        guard let closeButton = standardWindowButton(.closeButton),
              let titlebarView = closeButton.superview else { return }

        let host = NSHostingView(rootView: view)
        host.translatesAutoresizingMaskIntoConstraints = false
        host.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Transparent background so the title bar shows through
        host.layer?.backgroundColor = .clear
        titlebarView.addSubview(host)

        NSLayoutConstraint.activate([
            host.centerXAnchor.constraint(equalTo: titlebarView.centerXAnchor),
            host.centerYAnchor.constraint(equalTo: titlebarView.centerYAnchor),
            host.heightAnchor.constraint(equalTo: titlebarView.heightAnchor),
        ])

        activeTaskHost = host
    }

    /// Move traffic lights so they align horizontally with sidebar item text.
    private func repositionTrafficLights() {
        let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        let spacing: CGFloat = 20 // center-to-center
        for (i, type) in types.enumerated() {
            guard let button = standardWindowButton(type) else { continue }
            let x = Self.trafficLightX + CGFloat(i) * spacing
            button.setFrameOrigin(NSPoint(x: x, y: button.frame.origin.y))
        }
    }

    override func close() {
        onClose(frame, spaceID)
        super.close()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// NSButton that fires a closure and lives in the title bar view hierarchy.
final class TitleBarButton: NSButton {
    private let onClick: () -> Void

    init(action: @escaping () -> Void) {
        self.onClick = action
        super.init(frame: .zero)
        target = self
        self.action = #selector(handleClick)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleClick() {
        onClick()
    }

    override var mouseDownCanMoveWindow: Bool { false }
}`,
};
