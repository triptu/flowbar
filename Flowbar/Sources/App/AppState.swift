import SwiftUI
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

/// Central source of truth for the app's navigation, file list, and editor content.
///
/// Owns the folder path (persisted via UserDefaults), the list of markdown NoteFiles,
/// and the currently selected file's editor text. Sets up directory and file watchers
/// so the UI stays in sync when files change on disk (e.g. edits from Obsidian).
/// An isWriting flag prevents the file watcher from reloading content we just saved.
@Observable
@MainActor
final class AppState {
    // MARK: - Settings (persisted to UserDefaults)
    var folderPath: String {
        didSet { UserDefaults.standard.set(folderPath, forKey: "folderPath") }
    }
    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }
    var typography: TypographySize {
        didSet { UserDefaults.standard.set(typography.rawValue, forKey: "typography") }
    }
    /// Per-Space window frames: [SpaceID: [x, y, width, height]]
    @ObservationIgnored var windowFrames: [String: [Double]] {
        didSet { UserDefaults.standard.set(windowFrames, forKey: "windowFrames") }
    }
    var sidebarVisible: Bool {
        didSet { if sidebarVisible != oldValue { UserDefaults.standard.set(sidebarVisible, forKey: "sidebarVisible") } }
    }
    var sidebarWidth: Double {
        didSet { if sidebarWidth != oldValue { UserDefaults.standard.set(sidebarWidth, forKey: "sidebarWidth") } }
    }

    // MARK: - Navigation (single source of truth)
    var activePanel: ActivePanel = .empty

    var selectedFile: NoteFile? {
        if case .file(let f) = activePanel { return f }
        return nil
    }

    // MARK: - Files
    var noteFiles: [NoteFile] = []

    // File watching
    @ObservationIgnored private var dirWatcher: FileWatcher?
    @ObservationIgnored private var fileWatcher: FileWatcher?

    // MARK: - Editor
    var editorContent: String = ""
    @ObservationIgnored private var saveTask: DispatchWorkItem?
    @ObservationIgnored private var isWriting = false

    init() {
        let defaults = UserDefaults.standard
        self.folderPath = defaults.string(forKey: "folderPath") ?? ""
        self.theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .dark
        self.typography = TypographySize(rawValue: defaults.string(forKey: "typography") ?? "") ?? .default
        self.windowFrames = defaults.object(forKey: "windowFrames") as? [String: [Double]] ?? [:]
        self.sidebarVisible = defaults.object(forKey: "sidebarVisible") as? Bool ?? true
        self.sidebarWidth = defaults.object(forKey: "sidebarWidth") as? Double ?? 200
        loadFiles()
    }

    func loadFiles() {
        guard !folderPath.isEmpty else {
            noteFiles = []
            return
        }

        let url = URL(fileURLWithPath: folderPath)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            noteFiles = []
            return
        }

        noteFiles = contents
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
            .map { NoteFile(url: $0) }

        // Only create dirWatcher if it doesn't already exist (avoid fd churn)
        if dirWatcher == nil {
            dirWatcher = FileWatcher(url: url) { [weak self] in
                Task { @MainActor in
                    self?.loadFiles()
                }
            }
        }

        if case .empty = activePanel, let first = noteFiles.first {
            selectFile(first)
        }
    }

    func selectFile(_ file: NoteFile) {
        activePanel = .file(file)
        loadFileContent(file)
        watchFile(file)
    }

    func showSettings() {
        activePanel = .settings
    }

    func showTimer() {
        activePanel = .timer
    }

    // MARK: - Per-Space window frame

    /// Default window size for new Spaces
    static let defaultWindowSize = NSSize(width: 700, height: 500)

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

    func returnToFiles() {
        if let file = noteFiles.first {
            selectFile(file)
        } else {
            activePanel = .empty
        }
    }

    func loadFileContent(_ file: NoteFile) {
        if let content = try? String(contentsOf: file.url, encoding: .utf8) {
            editorContent = content
        }
    }

    func saveFileContent() {
        guard let file = selectedFile else { return }
        saveTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isWriting = true
            try? self.editorContent.write(to: file.url, atomically: true, encoding: .utf8)
            self.isWriting = false
        }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    private func watchFile(_ file: NoteFile) {
        fileWatcher = FileWatcher(url: file.url) { [weak self] in
            Task { @MainActor in
                guard let self, !self.isWriting else { return }
                guard let current = self.selectedFile, current.id == file.id else { return }
                self.loadFileContent(file)
            }
        }
    }

    func openInObsidian() {
        guard let file = selectedFile else { return }
        let vaultPath = URL(fileURLWithPath: folderPath).deletingLastPathComponent()
        let vaultName = vaultPath.lastPathComponent
        let relativePath = file.url.lastPathComponent
        let encoded = relativePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? relativePath
        let folderName = URL(fileURLWithPath: folderPath).lastPathComponent

        if let url = URL(string: "obsidian://open?vault=\(vaultName)&file=\(folderName)/\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }

    func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            sidebarVisible.toggle()
        }
    }

    func selectNextFile() {
        guard !noteFiles.isEmpty else { return }
        guard let current = selectedFile,
              let idx = noteFiles.firstIndex(where: { $0.id == current.id }) else {
            selectFile(noteFiles[0])
            return
        }
        let next = (idx + 1) % noteFiles.count
        selectFile(noteFiles[next])
    }

    func selectPreviousFile() {
        guard !noteFiles.isEmpty else { return }
        guard let current = selectedFile,
              let idx = noteFiles.firstIndex(where: { $0.id == current.id }) else {
            selectFile(noteFiles[0])
            return
        }
        let prev = (idx - 1 + noteFiles.count) % noteFiles.count
        selectFile(noteFiles[prev])
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
