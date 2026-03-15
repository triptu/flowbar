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
        state.folderPath = tempDir.path
        state.loadFiles()
    }

    @Test("loadFiles discovers markdown files in folder")
    func loadFilesDiscovery() {
        #expect(state.noteFiles.count == 2)
        #expect(state.noteFiles.map(\.id).contains("alpha"))
        #expect(state.noteFiles.map(\.id).contains("beta"))
    }

    @Test("loadFiles ignores non-markdown files")
    func loadFilesIgnoresNonMd() throws {
        try "not markdown".write(
            to: tempDir.appendingPathComponent("readme.txt"),
            atomically: true, encoding: .utf8
        )
        state.loadFiles()
        #expect(!state.noteFiles.map(\.id).contains("readme"))
    }

    @Test("loadFiles sorts alphabetically")
    func loadFilesSorted() {
        #expect(state.noteFiles[0].id == "alpha")
        #expect(state.noteFiles[1].id == "beta")
    }

    @Test("selectFile loads content from disk into editorContent")
    func selectFileLoadsContent() {
        let alpha = state.noteFiles.first { $0.id == "alpha" }!
        state.selectFile(alpha)

        #expect(state.editorContent == "# Alpha\nSome content")
        #expect(state.selectedFile?.id == "alpha")
        #expect(state.activePanel == .file(alpha))
    }

    @Test("selecting a different file switches editorContent")
    func switchFiles() {
        let alpha = state.noteFiles.first { $0.id == "alpha" }!
        let beta = state.noteFiles.first { $0.id == "beta" }!

        state.selectFile(alpha)
        #expect(state.editorContent.hasPrefix("# Alpha"))

        state.selectFile(beta)
        #expect(state.editorContent.hasPrefix("# Beta"))
    }

    @Test("saveFileContent writes editorContent to disk")
    func saveFileContent() async throws {
        let alpha = state.noteFiles.first { $0.id == "alpha" }!
        state.selectFile(alpha)
        state.editorContent = "# Alpha\nEdited content"
        state.saveFileContent()

        // saveFileContent debounces 0.5s via DispatchQueue.main.asyncAfter
        try await Task.sleep(for: .seconds(0.8))

        let onDisk = try String(contentsOf: alpha.url, encoding: .utf8)
        #expect(onDisk == "# Alpha\nEdited content")
    }

    @Test("loadFiles with empty folderPath yields no files")
    func emptyFolderPath() {
        state.folderPath = ""
        state.loadFiles()
        #expect(state.noteFiles.isEmpty)
    }

    @Test("loadFiles with nonexistent path yields no files")
    func nonexistentPath() {
        state.folderPath = "/tmp/definitely-not-a-real-folder-\(UUID().uuidString)"
        state.loadFiles()
        #expect(state.noteFiles.isEmpty)
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
        state.folderPath = tempDir.path
        state.loadFiles()
    }

    @Test("showSettings switches to settings panel")
    func showSettings() {
        state.showSettings()
        #expect(state.activePanel == .settings)
        #expect(state.selectedFile == nil)
    }

    @Test("showTimer switches to timer panel")
    func showTimer() {
        state.showTimer()
        #expect(state.activePanel == .timer)
        #expect(state.selectedFile == nil)
    }

    @Test("returnToFiles goes back to first file")
    func returnToFiles() {
        state.showSettings()
        state.returnToFiles()
        #expect(state.selectedFile?.id == "note")
    }

    @Test("returnToFiles with no files goes to empty")
    func returnToFilesEmpty() {
        state.folderPath = ""
        state.loadFiles()
        state.returnToFiles()
        #expect(state.activePanel == .empty)
    }
}

@Suite("AppState window frame persistence")
@MainActor
struct AppStateWindowFrameTests {

    private var state: AppState

    init() {
        state = AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)
        state.folderPath = ""
    }

    @Test("save and restore window frame per Space")
    func saveAndRestore() {
        let frame = NSRect(x: 100, y: 200, width: 700, height: 500)
        state.saveWindowFrame(frame, forSpace: 42)

        let restored = state.windowFrame(forSpace: 42)
        #expect(restored == frame)
    }

    @Test("windowFrame returns nil for unknown Space")
    func unknownSpace() {
        #expect(state.windowFrame(forSpace: 9999) == nil)
    }

    @Test("different Spaces have independent frames")
    func perSpaceFrames() {
        let frame1 = NSRect(x: 0, y: 0, width: 400, height: 300)
        let frame2 = NSRect(x: 100, y: 100, width: 800, height: 600)
        state.saveWindowFrame(frame1, forSpace: 1)
        state.saveWindowFrame(frame2, forSpace: 2)

        #expect(state.windowFrame(forSpace: 1) == frame1)
        #expect(state.windowFrame(forSpace: 2) == frame2)
    }
}
