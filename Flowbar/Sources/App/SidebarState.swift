import SwiftUI
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

    /// Non-nil when a sidebar row is in inline-rename mode
    var renamingFileID: String?
    /// The live text in the rename field — stored here so any caller can commit
    var renameText = ""

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.sidebarVisible = defaults.object(forKey: "sidebarVisible") as? Bool ?? true
        self.sidebarWidth = defaults.object(forKey: "sidebarWidth") as? Double ?? 200
    }

    // MARK: - Navigation helpers

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

    // MARK: - Rename helpers

    func startRename(_ file: NoteFile) {
        renameText = file.name
        renamingFileID = file.id
    }

    func cancelRename() {
        renamingFileID = nil
    }
}
