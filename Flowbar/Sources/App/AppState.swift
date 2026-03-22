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

/// Thin coordinator that holds the three sub-states and provides cross-cutting methods.
///
/// Views access sub-state via `appState.settings`, `appState.sidebar`, `appState.editor`.
/// Methods that touch multiple sub-states (selectFile, createNewFile, trashFile, etc.) live here.
@Observable
@MainActor
final class AppState {
    let settings: SettingsState
    let sidebar: SidebarState
    let editor: EditorState
    let search: SearchState

    init(defaults: UserDefaults = .standard) {
        self.settings = SettingsState(defaults: defaults)
        self.sidebar = SidebarState(defaults: defaults)
        self.editor = EditorState()
        self.search = SearchState()
        loadFiles()
    }

    // MARK: - Folder path (atomic set + reload)

    func setFolderPath(_ path: String) {
        settings.folderPath = path
        loadFiles()
    }

    // MARK: - File loading

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

    // MARK: - File selection (crosses sidebar + editor)

    func selectFile(_ file: NoteFile) {
        let isSameFile = sidebar.selectedFile?.id == file.id
        sidebar.activePanel = .file(file)
        if !isSameFile {
            editor.loadFileContent(file)
        }
        editor.watchFile(file) { [weak self] in
            guard let self else { return }
            guard let current = self.sidebar.selectedFile, current.id == file.id else { return }
            self.editor.loadFileContent(file, resetEditing: false)
        }
    }

    // MARK: - Navigation (delegate to sidebar, some cross-cutting)

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

    func selectNextFile() { selectAdjacentFile(offset: 1) }
    func selectPreviousFile() { selectAdjacentFile(offset: -1) }

    private func selectAdjacentFile(offset: Int) {
        let files = sidebar.noteFiles
        guard !files.isEmpty else { return }
        guard let current = sidebar.selectedFile,
              let idx = files.firstIndex(where: { $0.id == current.id }) else {
            selectFile(files[0])
            return
        }
        let target = (idx + offset + files.count) % files.count
        selectFile(files[target])
    }

    // MARK: - Editor save (crosses sidebar + editor)

    func saveFileContent() {
        editor.saveFileContent(for: sidebar.selectedFile)
    }

    // MARK: - File operations (cross sidebar + editor + settings)

    func createNewFile() {
        guard !settings.folderPath.isEmpty else { return }
        let folderURL = URL(fileURLWithPath: settings.folderPath)
        var name = "untitled"
        var counter = 1
        while FileManager.default.fileExists(atPath: folderURL.appendingPathComponent("\(name).md").path) {
            name = "untitled-\(counter)"
            counter += 1
        }
        let fileURL = folderURL.appendingPathComponent("\(name).md")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        editor.suppressNextDirectoryEvent()
        loadFiles()
        if let newFile = sidebar.noteFiles.first(where: { $0.id == name }) {
            selectFile(newFile)
            startRename(newFile)
        }
    }

    func commitRename() {
        guard let fileID = sidebar.renamingFileID,
              let file = sidebar.noteFiles.first(where: { $0.id == fileID }) else {
            sidebar.renamingFileID = nil
            return
        }
        sidebar.renamingFileID = nil
        moveFile(file, toDisplayName: sidebar.renameText)
    }

    func startRename(_ file: NoteFile) {
        sidebar.startRename(file)
    }

    func cancelRename() {
        sidebar.cancelRename()
    }

    /// Convenience for callers (and tests) that already know the file and new name.
    func renameFile(_ file: NoteFile, to newName: String) {
        moveFile(file, toDisplayName: newName)
    }

    /// Shared rename logic: validates the new name, moves the file on disk, reloads, and re-selects.
    private func moveFile(_ file: NoteFile, toDisplayName displayName: String) {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != file.id else { return }
        let newURL = file.url.deletingLastPathComponent().appendingPathComponent("\(trimmed).md")
        guard !FileManager.default.fileExists(atPath: newURL.path) else { return }
        do {
            try FileManager.default.moveItem(at: file.url, to: newURL)
            let wasSelected = sidebar.selectedFile?.id == file.id
            editor.suppressNextDirectoryEvent()
            loadFiles()
            if wasSelected, let renamed = sidebar.noteFiles.first(where: { $0.id == trimmed }) {
                selectFile(renamed)
            }
        } catch {}
    }

    func trashFile(_ file: NoteFile) {
        let wasSelected = sidebar.selectedFile?.id == file.id
        do {
            try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
        } catch {
            return
        }
        editor.suppressNextDirectoryEvent()
        loadFiles()
        if wasSelected {
            if let first = sidebar.noteFiles.first {
                selectFile(first)
            } else {
                sidebar.activePanel = .empty
            }
        }
    }

    // MARK: - External app integration

    func openInObsidian() {
        guard let file = sidebar.selectedFile else { return }
        openInObsidian(file)
    }

    func openInObsidian(_ file: NoteFile) {
        let vaultPath = URL(fileURLWithPath: settings.folderPath).deletingLastPathComponent()
        let vaultName = vaultPath.lastPathComponent
        let relativePath = file.url.lastPathComponent
        let encoded = relativePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? relativePath
        let folderName = URL(fileURLWithPath: settings.folderPath).lastPathComponent

        if let url = URL(string: "obsidian://open?vault=\(vaultName)&file=\(folderName)/\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }

    func revealInFinder(_ file: NoteFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }
}
