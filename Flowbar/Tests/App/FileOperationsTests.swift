import Testing
@testable import Flowbar
import Foundation

@Suite("File operations (create, rename, trash)")
@MainActor
struct FileOperationsTests {

    private var tempDir: URL
    private var state: AppState

    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("flowbar-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        for name in ["alpha", "beta", "gamma"] {
            FileManager.default.createFile(
                atPath: tempDir.appendingPathComponent("\(name).md").path,
                contents: "# \(name)".data(using: .utf8)
            )
        }

        state = AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)
        state.folderPath = tempDir.path
        state.loadFiles()
    }

    // MARK: - Create

    @Test("createNewFile adds untitled.md")
    func createNewFile() {
        let countBefore = state.noteFiles.count
        state.createNewFile()

        #expect(state.noteFiles.count == countBefore + 1)
        #expect(state.selectedFile?.id == "untitled")
        #expect(state.renamingFileID == "untitled")
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("untitled.md").path))
    }

    @Test("createNewFile increments when untitled exists")
    func createNewFileIncrement() {
        state.createNewFile()
        #expect(state.selectedFile?.id == "untitled")

        state.createNewFile()
        #expect(state.selectedFile?.id == "untitled-1")
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("untitled-1.md").path))
    }

    // MARK: - Rename

    @Test("renameFile changes the filename on disk")
    func renameFile() {
        let file = state.noteFiles.first { $0.id == "alpha" }!
        state.selectFile(file)
        state.renameFile(file, to: "New Name")

        #expect(state.selectedFile?.id == "new-name")
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("new-name.md").path))
        #expect(!FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("alpha.md").path))
    }

    @Test("renameFile is no-op for same name, existing name, or blank", arguments: [
        ("alpha", "Alpha"),
        ("alpha", "Beta"),
        ("alpha", "   "),
    ] as [(String, String)])
    func renameNoOp(fileId: String, newName: String) {
        let file = state.noteFiles.first { $0.id == fileId }!
        state.selectFile(file)
        state.renamingFileID = file.id
        state.renameFile(file, to: newName)

        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("\(fileId).md").path))
    }

    // MARK: - Trash

    @Test("trashFile removes file and auto-selects another")
    func trashFile() {
        let file = state.noteFiles.first { $0.id == "alpha" }!
        state.selectFile(file)
        let countBefore = state.noteFiles.count

        state.trashFile(file)

        #expect(state.noteFiles.count == countBefore - 1)
        #expect(!FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("alpha.md").path))
        #expect(state.selectedFile != nil)
        #expect(state.selectedFile?.id != "alpha")
    }

    @Test("trashFile on non-selected file keeps current selection")
    func trashNonSelectedFile() {
        let alpha = state.noteFiles.first { $0.id == "alpha" }!
        let beta = state.noteFiles.first { $0.id == "beta" }!
        state.selectFile(alpha)

        state.trashFile(beta)

        #expect(state.selectedFile?.id == "alpha")
    }

    @Test("trashing the last file goes to empty state")
    func trashLastFile() {
        for file in state.noteFiles where file.id != "alpha" {
            state.trashFile(file)
        }
        let last = state.noteFiles.first { $0.id == "alpha" }!
        state.selectFile(last)

        state.trashFile(last)

        #expect(state.selectedFile == nil)
        #expect(state.activePanel == .empty)
    }
}
