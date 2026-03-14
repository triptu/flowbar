import SwiftUI
import Combine

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
/// Owns the folder path (persisted via @AppStorage), the list of markdown NoteFiles,
/// and the currently selected file's editor text. Sets up directory and file watchers
/// so the UI stays in sync when files change on disk (e.g. edits from Obsidian).
/// An isWriting flag prevents the file watcher from reloading content we just saved.
@MainActor
final class AppState: ObservableObject {
    // MARK: - Settings
    @AppStorage("folderPath") var folderPath: String = ""
    @AppStorage("theme") var theme: AppTheme = .dark
    @AppStorage("typography") var typography: TypographySize = .default
    @AppStorage("popoverWidth") var popoverWidth: Double = 700
    @AppStorage("popoverHeight") var popoverHeight: Double = 500
    @AppStorage("sidebarVisible") var sidebarVisible: Bool = true
    @AppStorage("sidebarWidth") var sidebarWidth: Double = 200

    // MARK: - Navigation (single source of truth)
    @Published var activePanel: ActivePanel = .empty

    var selectedFile: NoteFile? {
        if case .file(let f) = activePanel { return f }
        return nil
    }

    // MARK: - Files
    @Published var noteFiles: [NoteFile] = []

    // File watching
    private var dirWatcher: FileWatcher?
    private var fileWatcher: FileWatcher?

    // MARK: - Editor
    @Published var editorContent: String = ""
    private var saveTask: DispatchWorkItem?
    private var isWriting = false

    init() {
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

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

extension AppTheme: RawRepresentable {}
extension TypographySize: RawRepresentable {}
