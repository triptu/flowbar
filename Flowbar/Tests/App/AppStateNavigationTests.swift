import Testing
@testable import Flowbar
import Foundation

@Suite("AppState navigation")
@MainActor
struct AppStateNavigationTests {

    private func makeAppState(fileNames: [String]) -> AppState {
        let state = AppState(defaults: UserDefaults(suiteName: "com.flowbar.tests-\(UUID().uuidString)")!)
        state.sidebar.activePanel = .empty
        state.sidebar.noteFiles = fileNames.map { NoteFile(url: URL(fileURLWithPath: "/tmp/\($0).md")) }
        return state
    }

    @Test("selectNextFile cycles forward", arguments: [
        (["a", "b", "c"], 0, "b"),
        (["a", "b", "c"], 1, "c"),
        (["a", "b", "c"], 2, "a"),
    ] as [([String], Int, String)])
    func selectNextFile(files: [String], startIndex: Int, expectedId: String) {
        let state = makeAppState(fileNames: files)
        state.selectFile(state.sidebar.noteFiles[startIndex])
        state.selectNextFile()
        #expect(state.sidebar.selectedFile?.id == expectedId)
    }

    @Test("selectPreviousFile cycles backward", arguments: [
        (["a", "b", "c"], 2, "b"),
        (["a", "b", "c"], 1, "a"),
        (["a", "b", "c"], 0, "c"),
    ] as [([String], Int, String)])
    func selectPreviousFile(files: [String], startIndex: Int, expectedId: String) {
        let state = makeAppState(fileNames: files)
        state.selectFile(state.sidebar.noteFiles[startIndex])
        state.selectPreviousFile()
        #expect(state.sidebar.selectedFile?.id == expectedId)
    }

    @Test("selectNextFile with no selection selects first")
    func nextFileNoSelection() {
        let state = makeAppState(fileNames: ["a", "b", "c"])
        state.selectNextFile()
        #expect(state.sidebar.selectedFile?.id == "a")
    }

    @Test("selectPreviousFile with no selection selects first")
    func previousFileNoSelection() {
        let state = makeAppState(fileNames: ["a", "b", "c"])
        state.selectPreviousFile()
        #expect(state.sidebar.selectedFile?.id == "a")
    }

    @Test("selectNextFile on empty list stays nil")
    func nextFileEmptyList() {
        let state = makeAppState(fileNames: [])
        state.selectNextFile()
        #expect(state.sidebar.selectedFile == nil)
    }

    @Test("selectPreviousFile on empty list stays nil")
    func previousFileEmptyList() {
        let state = makeAppState(fileNames: [])
        state.selectPreviousFile()
        #expect(state.sidebar.selectedFile == nil)
    }

    @Test("single file stays selected for both directions")
    func singleFile() {
        let state = makeAppState(fileNames: ["only"])
        state.selectFile(state.sidebar.noteFiles[0])

        state.selectNextFile()
        #expect(state.sidebar.selectedFile?.id == "only")

        state.selectPreviousFile()
        #expect(state.sidebar.selectedFile?.id == "only")
    }
}
