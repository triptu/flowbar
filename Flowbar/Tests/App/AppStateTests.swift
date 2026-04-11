import Testing
@testable import Flowbar
import Foundation

@Suite("AppState file lifecycle")
@MainActor
struct AppStateFileLifecycleTests {

    private var tempDir: URL
    private var state: AppState

    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("flowbar-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        for (name, content) in [("alpha", "# Alpha\nSome content"), ("beta", "# Beta\n- [ ] Task one")] {
            try content.write(
                to: tempDir.appendingPathComponent("\(name).md"),
                atomically: true, encoding: .utf8
            )
        }

        state = AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)
        state.settings.folderPath = tempDir.path
        state.loadFiles()
    }

    @Test("loadFiles discovers markdown files in folder")
    func loadFilesDiscovery() {
        #expect(state.sidebar.noteFiles.count == 2)
        #expect(state.sidebar.noteFiles.map(\.id).contains("alpha"))
        #expect(state.sidebar.noteFiles.map(\.id).contains("beta"))
    }

    @Test("loadFiles ignores non-markdown files")
    func loadFilesIgnoresNonMd() throws {
        try "not markdown".write(
            to: tempDir.appendingPathComponent("readme.txt"),
            atomically: true, encoding: .utf8
        )
        state.loadFiles()
        #expect(!state.sidebar.noteFiles.map(\.id).contains("readme"))
    }

    @Test("loadFiles sorts alphabetically")
    func loadFilesSorted() {
        #expect(state.sidebar.noteFiles[0].id == "alpha")
        #expect(state.sidebar.noteFiles[1].id == "beta")
    }

    @Test("selectFile loads content from disk into editorContent")
    func selectFileLoadsContent() {
        let alpha = state.sidebar.noteFiles.first { $0.id == "alpha" }!
        state.selectFile(alpha)

        #expect(state.editor.editorContent == "# Alpha\nSome content")
        #expect(state.sidebar.selectedFile?.id == "alpha")
        #expect(state.sidebar.activePanel == .file(alpha))
    }

    @Test("selecting a different file switches editorContent")
    func switchFiles() {
        let alpha = state.sidebar.noteFiles.first { $0.id == "alpha" }!
        let beta = state.sidebar.noteFiles.first { $0.id == "beta" }!

        state.selectFile(alpha)
        #expect(state.editor.editorContent.hasPrefix("# Alpha"))

        state.selectFile(beta)
        #expect(state.editor.editorContent.hasPrefix("# Beta"))
    }

    @Test("saveFileContent writes editorContent to disk")
    func saveFileContent() async throws {
        let alpha = state.sidebar.noteFiles.first { $0.id == "alpha" }!
        state.selectFile(alpha)
        state.editor.editorContent = "# Alpha\nEdited content"
        state.saveFileContent()

        // saveFileContent debounces 0.5s via DispatchQueue.main.asyncAfter
        try await Task.sleep(for: .seconds(0.8))

        let onDisk = try String(contentsOf: alpha.url, encoding: .utf8)
        #expect(onDisk == "# Alpha\nEdited content")
    }

    @Test("loadFiles with empty folderPath yields no files")
    func emptyFolderPath() {
        state.settings.folderPath = ""
        state.loadFiles()
        #expect(state.sidebar.noteFiles.isEmpty)
    }

    @Test("loadFiles with nonexistent path yields no files")
    func nonexistentPath() {
        state.settings.folderPath = "/tmp/definitely-not-a-real-folder-\(UUID().uuidString)"
        state.loadFiles()
        #expect(state.sidebar.noteFiles.isEmpty)
    }
}

@Suite("AppState subfolder support")
@MainActor
struct AppStateSubfolderTests {

    private var tempDir: URL
    private var state: AppState

    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("flowbar-subfolder-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Root files
        try "# Root Note".write(to: tempDir.appendingPathComponent("root.md"), atomically: true, encoding: .utf8)

        // Subfolder with files
        let sub = tempDir.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try "# Sub Note".write(to: sub.appendingPathComponent("child.md"), atomically: true, encoding: .utf8)

        // Nested subfolder
        let deep = sub.appendingPathComponent("deep")
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)
        try "# Deep Note".write(to: deep.appendingPathComponent("leaf.md"), atomically: true, encoding: .utf8)

        state = AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)
        state.settings.folderPath = tempDir.path
        state.loadFiles()
    }

    @Test("loadFiles discovers files in subfolders")
    func discoversSubfolderFiles() {
        let ids = state.sidebar.noteFiles.map(\.id)
        #expect(ids.contains("root"))
        #expect(ids.contains("sub/child"))
        #expect(ids.contains("sub/deep/leaf"))
        #expect(state.sidebar.noteFiles.count == 3)
    }

    @Test("sidebarItems has folders before files, sorted")
    func sidebarItemsStructure() {
        // Root level: sub/ folder, then root.md file
        #expect(state.sidebar.sidebarItems.count == 2)
        if case .folder(let name, _, let children) = state.sidebar.sidebarItems[0] {
            #expect(name == "sub")
            // sub/ has: deep/ folder, then child.md
            #expect(children.count == 2)
            if case .folder(let deepName, _, _) = children[0] {
                #expect(deepName == "deep")
            }
            if case .file(let note) = children[1] {
                #expect(note.name == "child")
            }
        }
        if case .file(let note) = state.sidebar.sidebarItems[1] {
            #expect(note.name == "root")
        }
    }

    @Test("selectFile works for subfolder files")
    func selectSubfolderFile() {
        let child = state.sidebar.noteFiles.first { $0.id == "sub/child" }!
        state.selectFile(child)
        #expect(state.editor.editorContent == "# Sub Note")
        #expect(state.sidebar.selectedFile?.id == "sub/child")
    }

    @Test("createNewFile in subfolder creates file there")
    func createFileInSubfolder() {
        state.createNewFile(inFolder: "sub")
        #expect(state.sidebar.selectedFile?.id == "sub/untitled")
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("sub/untitled.md").path))
        #expect(state.sidebar.expandedFolders.contains("sub"))
    }

    @Test("createNewFolder creates directory on disk")
    func createFolder() {
        state.createNewFolder()
        let folderPath = tempDir.appendingPathComponent("untitled-folder").path
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: folderPath, isDirectory: &isDir))
        #expect(isDir.boolValue)
    }

    @Test("createNewFolder in subfolder creates nested folder")
    func createNestedFolder() {
        state.createNewFolder(inFolder: "sub")
        let folderPath = tempDir.appendingPathComponent("sub/untitled-folder").path
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: folderPath, isDirectory: &isDir))
        #expect(isDir.boolValue)
        #expect(state.sidebar.expandedFolders.contains("sub"))
    }

    @Test("renameFile works for subfolder files")
    func renameSubfolderFile() {
        let child = state.sidebar.noteFiles.first { $0.id == "sub/child" }!
        state.selectFile(child)
        state.renameFile(child, to: "renamed")
        #expect(state.sidebar.selectedFile?.id == "sub/renamed")
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("sub/renamed.md").path))
    }

    @Test("trashFolder removes folder and contents")
    func trashFolder() {
        let child = state.sidebar.noteFiles.first { $0.id == "sub/child" }!
        state.selectFile(child)
        state.trashFolder(relativePath: "sub")
        #expect(!FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("sub").path))
        // Only root.md should remain
        #expect(state.sidebar.noteFiles.count == 1)
        #expect(state.sidebar.noteFiles[0].id == "root")
    }

    @Test("NoteFile.name returns display name not relative path")
    func noteFileDisplayName() {
        let child = state.sidebar.noteFiles.first { $0.id == "sub/child" }!
        #expect(child.name == "child")
    }

    @Test("folder expand/collapse toggle")
    func folderToggle() {
        #expect(!state.sidebar.expandedFolders.contains("sub"))
        state.sidebar.toggleFolder("sub")
        #expect(state.sidebar.expandedFolders.contains("sub"))
        state.sidebar.toggleFolder("sub")
        #expect(!state.sidebar.expandedFolders.contains("sub"))
    }

    @Test("renameFolder renames on disk and reloads")
    func renameFolder() {
        state.sidebar.expandedFolders.insert("sub")
        state.renameFolder(relativePath: "sub", to: "docs")
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("docs").path))
        #expect(!FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("sub").path))
        #expect(state.sidebar.noteFiles.contains { $0.id == "docs/child" })
        // Expanded state transfers to new name
        #expect(state.sidebar.expandedFolders.contains("docs"))
        #expect(!state.sidebar.expandedFolders.contains("sub"))
    }

    @Test("renameFolder no-ops for same name or empty")
    func renameFolderNoOp() {
        state.renameFolder(relativePath: "sub", to: "sub")
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("sub").path))
        state.renameFolder(relativePath: "sub", to: "  ")
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("sub").path))
    }

    @Test("renameFolder skips if target exists")
    func renameFolderConflict() throws {
        let other = tempDir.appendingPathComponent("other")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)
        state.renameFolder(relativePath: "sub", to: "other")
        // Both should still exist — rename was skipped
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("sub").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("other").path))
    }

    @Test("commitFolderRename uses renameText")
    func commitFolderRename() {
        state.startFolderRename("sub")
        #expect(state.sidebar.renamingFolderPath == "sub")
        #expect(state.sidebar.renameText == "sub")
        state.sidebar.renameText = "renamed-folder"
        state.commitFolderRename()
        #expect(state.sidebar.renamingFolderPath == nil)
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("renamed-folder").path))
    }
}

@Suite("AppState panel navigation")
@MainActor
struct AppStatePanelTests {

    private var state: AppState

    init() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("flowbar-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try "# Test".write(
            to: tempDir.appendingPathComponent("note.md"),
            atomically: true, encoding: .utf8
        )

        state = AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)
        state.settings.folderPath = tempDir.path
        state.loadFiles()
    }

    @Test("showSettings switches to settings panel")
    func showSettings() {
        state.showSettings()
        #expect(state.sidebar.activePanel == .settings)
        #expect(state.sidebar.selectedFile == nil)
    }

    @Test("showTimer switches to timer panel")
    func showTimer() {
        state.showTimer()
        #expect(state.sidebar.activePanel == .timer)
        #expect(state.sidebar.selectedFile == nil)
    }

    @Test("returnToFiles goes back to first file")
    func returnToFiles() {
        state.showSettings()
        state.returnToFiles()
        #expect(state.sidebar.selectedFile?.id == "note")
    }

    @Test("returnToFiles with no files goes to empty")
    func returnToFilesEmpty() {
        state.settings.folderPath = ""
        state.loadFiles()
        state.returnToFiles()
        #expect(state.sidebar.activePanel == .empty)
    }
}

@Suite("AppState window frame persistence")
@MainActor
struct AppStateWindowFrameTests {

    private var state: AppState

    init() {
        state = AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)
        state.settings.folderPath = ""
    }

    @Test("save and restore window frame per Space")
    func saveAndRestore() {
        let frame = NSRect(x: 100, y: 200, width: 700, height: 500)
        state.settings.saveWindowFrame(frame, forSpace: 42)

        let restored = state.settings.windowFrame(forSpace: 42)
        #expect(restored == frame)
    }

    @Test("windowFrame returns nil for unknown Space")
    func unknownSpace() {
        #expect(state.settings.windowFrame(forSpace: 9999) == nil)
    }

    @Test("different Spaces have independent frames")
    func perSpaceFrames() {
        let frame1 = NSRect(x: 0, y: 0, width: 400, height: 300)
        let frame2 = NSRect(x: 100, y: 100, width: 800, height: 600)
        state.settings.saveWindowFrame(frame1, forSpace: 1)
        state.settings.saveWindowFrame(frame2, forSpace: 2)

        #expect(state.settings.windowFrame(forSpace: 1) == frame1)
        #expect(state.settings.windowFrame(forSpace: 2) == frame2)
    }
}
