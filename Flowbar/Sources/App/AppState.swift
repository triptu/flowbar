import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case light, dark, system
}

enum BottomTab {
    case settings, timer
}

@MainActor
final class AppState: ObservableObject {
    // MARK: - Settings
    @AppStorage("folderPath") var folderPath: String = ""
    @AppStorage("theme") var theme: AppTheme = .dark
    @AppStorage("typography") var typography: TypographySize = .default
    @AppStorage("popoverWidth") var popoverWidth: Double = 700
    @AppStorage("popoverHeight") var popoverHeight: Double = 500
    @AppStorage("sidebarVisible") var sidebarVisible: Bool = true

    // MARK: - Navigation
    @Published var selectedFile: NoteFile?
    @Published var activeTab: BottomTab = .settings
    @Published var showingSettings = false
    @Published var showingTimer = false

    // MARK: - Files
    @Published var noteFiles: [NoteFile] = []

    // MARK: - Timer
    @Published var timerShowingTodos = false

    // File watching
    private var dirWatcher: FileWatcher?
    private var fileWatcher: FileWatcher?

    // MARK: - Editor
    @Published var editorContent: String = ""
    private var saveTask: DispatchWorkItem?

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

        // Watch directory for changes
        dirWatcher = FileWatcher(url: url) { [weak self] in
            Task { @MainActor in
                self?.loadFiles()
            }
        }

        // Select first file if none selected
        if selectedFile == nil, let first = noteFiles.first {
            selectFile(first)
        }
    }

    func selectFile(_ file: NoteFile) {
        selectedFile = file
        loadFileContent(file)
        watchFile(file)
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
            try? self.editorContent.write(to: file.url, atomically: true, encoding: .utf8)
        }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    private func watchFile(_ file: NoteFile) {
        fileWatcher = FileWatcher(url: file.url) { [weak self] in
            Task { @MainActor in
                guard let self, let current = self.selectedFile, current.id == file.id else { return }
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
}

// Make enums RawRepresentable for AppStorage
extension AppTheme: RawRepresentable {
    // Already has String rawValue
}

extension TypographySize: RawRepresentable {
    // Already has String rawValue
}
