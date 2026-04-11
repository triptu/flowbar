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
        sidebar.expandedFolders.removeAll()
        loadFiles()
    }

    // MARK: - File loading

    func loadFiles() {
        guard !settings.folderPath.isEmpty else {
            sidebar.noteFiles = []
            sidebar.sidebarItems = []
            return
        }

        let rootURL = URL(fileURLWithPath: settings.folderPath)
        let rootComponents = rootURL.standardizedFileURL.pathComponents
        let (items, files) = scanDirectory(rootURL, rootComponents: rootComponents)
        sidebar.sidebarItems = items
        sidebar.noteFiles = files

        editor.watchDirectory(at: rootURL) { [weak self] in
            Task { @MainActor in
                self?.loadFiles()
            }
        }

        if case .empty = sidebar.activePanel, let first = sidebar.noteFiles.first {
            selectFile(first)
        }
    }

    /// Recursively scan a directory, returning (tree items for sidebar, flat file list for search/todos).
    private func scanDirectory(_ url: URL, rootComponents: [String]) -> ([SidebarItem], [NoteFile]) {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return ([], []) }

        let sorted = contents.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }

        var items: [SidebarItem] = []
        var files: [SidebarItem] = []
        var allFiles: [NoteFile] = []

        for item in sorted {
            if item.hasDirectoryPath {
                let (children, childFiles) = scanDirectory(item, rootComponents: rootComponents)
                let itemComponents = item.standardizedFileURL.pathComponents
                let relativePath = itemComponents.dropFirst(rootComponents.count).joined(separator: "/")
                items.append(.folder(name: item.lastPathComponent, relativePath: relativePath, children: children))
                allFiles.append(contentsOf: childFiles)
            } else if item.pathExtension == "md" {
                let note = NoteFile(url: item, rootComponents: rootComponents)
                files.append(.file(note))
                allFiles.append(note)
            }
        }

        items.append(contentsOf: files)
        return (items, allFiles)
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

    func createNewFile(inFolder relativePath: String? = nil) {
        guard !settings.folderPath.isEmpty else { return }
        let rootURL = URL(fileURLWithPath: settings.folderPath)
        let targetURL = relativePath.map { rootURL.appendingPathComponent($0) } ?? rootURL
        var name = "untitled"
        var counter = 1
        while FileManager.default.fileExists(atPath: targetURL.appendingPathComponent("\(name).md").path) {
            name = "untitled-\(counter)"
            counter += 1
        }
        let fileURL = targetURL.appendingPathComponent("\(name).md")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        editor.suppressNextDirectoryEvent()
        if let relativePath { sidebar.expandedFolders.insert(relativePath) }
        loadFiles()
        let expectedID = NoteFile(url: fileURL, rootComponents: rootURL.standardizedFileURL.pathComponents).id
        if let newFile = sidebar.noteFiles.first(where: { $0.id == expectedID }) {
            selectFile(newFile)
            startRename(newFile)
        }
    }

    func createNewFolder(inFolder relativePath: String? = nil) {
        guard !settings.folderPath.isEmpty else { return }
        let rootURL = URL(fileURLWithPath: settings.folderPath)
        let parentURL = relativePath.map { rootURL.appendingPathComponent($0) } ?? rootURL
        var name = "untitled-folder"
        var counter = 1
        while FileManager.default.fileExists(atPath: parentURL.appendingPathComponent(name).path) {
            name = "untitled-folder-\(counter)"
            counter += 1
        }
        let folderURL = parentURL.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        editor.suppressNextDirectoryEvent()
        if let relativePath { sidebar.expandedFolders.insert(relativePath) }
        loadFiles()
        // Compute the new folder's relative path and start rename
        let rootComponents = rootURL.standardizedFileURL.pathComponents
        let folderComponents = folderURL.standardizedFileURL.pathComponents
        let newRelativePath = folderComponents.dropFirst(rootComponents.count).joined(separator: "/")
        startFolderRename(newRelativePath)
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

    func startFolderRename(_ relativePath: String) {
        sidebar.startFolderRename(relativePath)
    }

    func commitFolderRename() {
        guard let oldPath = sidebar.renamingFolderPath else { return }
        sidebar.renamingFolderPath = nil
        renameFolder(relativePath: oldPath, to: sidebar.renameText)
    }

    func renameFolder(relativePath: String, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        let oldName = URL(fileURLWithPath: relativePath).lastPathComponent
        guard !trimmed.isEmpty, trimmed != oldName else { return }
        let rootURL = URL(fileURLWithPath: settings.folderPath)
        let oldURL = rootURL.appendingPathComponent(relativePath)
        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(trimmed)
        guard !FileManager.default.fileExists(atPath: newURL.path) else { return }
        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            editor.suppressNextDirectoryEvent()
            // Update expanded state to use new path
            if sidebar.expandedFolders.contains(relativePath) {
                sidebar.expandedFolders.remove(relativePath)
                let parentPath = URL(fileURLWithPath: relativePath).deletingLastPathComponent().path
                let newRelative = parentPath == "." || parentPath == "/" ? trimmed : parentPath + "/" + trimmed
                sidebar.expandedFolders.insert(newRelative)
            }
            loadFiles()
        } catch {}
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
        guard !trimmed.isEmpty, trimmed != file.name else { return }
        let newURL = file.url.deletingLastPathComponent().appendingPathComponent("\(trimmed).md")
        guard !FileManager.default.fileExists(atPath: newURL.path) else { return }
        do {
            try FileManager.default.moveItem(at: file.url, to: newURL)
            let wasSelected = sidebar.selectedFile?.id == file.id
            editor.suppressNextDirectoryEvent()
            loadFiles()
            let rootComponents = URL(fileURLWithPath: settings.folderPath).standardizedFileURL.pathComponents
            let expectedID = NoteFile(url: newURL, rootComponents: rootComponents).id
            if wasSelected, let renamed = sidebar.noteFiles.first(where: { $0.id == expectedID }) {
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

    func trashFolder(relativePath: String) {
        let folderURL = URL(fileURLWithPath: settings.folderPath).appendingPathComponent(relativePath)
        let wasSelectedInFolder = sidebar.selectedFile.map { $0.id.hasPrefix(relativePath + "/") } ?? false
        do {
            try FileManager.default.trashItem(at: folderURL, resultingItemURL: nil)
        } catch {
            return
        }
        editor.suppressNextDirectoryEvent()
        sidebar.expandedFolders.remove(relativePath)
        loadFiles()
        if wasSelectedInFolder {
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
        let folderName = URL(fileURLWithPath: settings.folderPath).lastPathComponent
        let relativePath = file.id + ".md"
        let encoded = relativePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? relativePath

        if let url = URL(string: "obsidian://open?vault=\(vaultName)&file=\(folderName)/\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }

    func revealInFinder(_ file: NoteFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    func revealFolderInFinder(relativePath: String) {
        let url = URL(fileURLWithPath: settings.folderPath).appendingPathComponent(relativePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
