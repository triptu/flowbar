import SwiftUI
import Observation

enum AppTheme: String, CaseIterable {
    case light, dark, system
}

enum ActivePanel: Equatable {
    case file(NoteFile)
    case dailyNote
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

    // MARK: - Daily Note

    var dailyNoteContent: String = ""
    var dailyNoteHeadings: [(level: Int, text: String)] = []
    var dailyNoteSelectedHeading: String?
    @ObservationIgnored private var dailyNoteWatcher: FileWatcher?

    /// The filtered content to display — full note or just the selected heading's section.
    var dailyNoteDisplayContent: String {
        guard let heading = dailyNoteSelectedHeading else { return dailyNoteContent }
        return MarkdownParser.sectionContent(for: heading, in: dailyNoteContent)
    }

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

    // MARK: - Daily Note

    var dailyNoteExists: Bool = false

    var dailyNoteURL: URL? {
        guard !settings.folderPath.isEmpty else { return nil }
        let filename = settings.dailyNoteFilename()
        return URL(fileURLWithPath: settings.folderPath).appendingPathComponent("\(filename).md")
    }

    func showDailyNote() {
        guard !settings.folderPath.isEmpty else { return }
        dailyNoteSelectedHeading = nil
        sidebar.activePanel = .dailyNote
        guard let fileURL = dailyNoteURL else { return }
        dailyNoteExists = FileManager.default.fileExists(atPath: fileURL.path)
        guard dailyNoteExists else { return }
        loadDailyNoteContent(from: fileURL)
        watchDailyNote(at: fileURL)
    }

    func createDailyNote() {
        guard let fileURL = dailyNoteURL else { return }
        let content = resolveTemplate(for: fileURL)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        dailyNoteExists = true
        loadDailyNoteContent(from: fileURL)
        watchDailyNote(at: fileURL)
    }

    private func resolveTemplate(for fileURL: URL) -> String {
        let templatePath = settings.dailyNoteTemplatePath
        guard !templatePath.isEmpty,
              let raw = try? String(contentsOfFile: templatePath, encoding: .utf8) else {
            return ""
        }
        let title = fileURL.deletingPathExtension().lastPathComponent
        let now = Date()
        // Substitute Obsidian template tokens
        var result = raw
            .replacingOccurrences(of: "{{title}}", with: title)
            .replacingOccurrences(of: "{{date}}", with: settings.dailyNoteFilename(for: now))
            .replacingOccurrences(of: "{{time}}", with: formatTime(now))
        // {{date:FORMAT}} — replace each occurrence
        if let regex = try? NSRegularExpression(pattern: #"\{\{date:(.+?)\}\}"#) {
            let nsResult = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsResult.length))
            for match in matches.reversed() {
                let fmtRange = match.range(at: 1)
                let fmt = nsResult.substring(with: fmtRange)
                let replacement = settings.dailyNoteFilename(for: now, format: fmt)
                result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
            }
        }
        return result
    }

    private func formatTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }

    private func watchDailyNote(at fileURL: URL) {
        dailyNoteWatcher = FileWatcher(url: fileURL) { [weak self] in
            Task { @MainActor in
                self?.loadDailyNoteContent(from: fileURL)
            }
        }
    }

    private func loadDailyNoteContent(from url: URL) {
        dailyNoteContent = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        dailyNoteHeadings = MarkdownParser.extractHeadings(from: dailyNoteContent)
    }

    func selectDailyNoteHeading(_ heading: String?) {
        dailyNoteSelectedHeading = heading
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
