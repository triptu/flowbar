import XCTest
@testable import Flowbar

@MainActor
final class AppStateNavigationTests: XCTestCase {

    private func makeAppState(fileNames: [String]) -> AppState {
        let state = AppState()
        state.noteFiles = fileNames.map { NoteFile(url: URL(fileURLWithPath: "/tmp/\($0).md")) }
        return state
    }

    // MARK: - selectNextFile

    func testSelectNextFileFromFirst() {
        let state = makeAppState(fileNames: ["a", "b", "c"])
        state.selectFile(state.noteFiles[0])

        state.selectNextFile()

        XCTAssertEqual(state.selectedFile?.id, "b")
    }

    func testSelectNextFileFromMiddle() {
        let state = makeAppState(fileNames: ["a", "b", "c"])
        state.selectFile(state.noteFiles[1])

        state.selectNextFile()

        XCTAssertEqual(state.selectedFile?.id, "c")
    }

    func testSelectNextFileFromLastWrapsToFirst() {
        let state = makeAppState(fileNames: ["a", "b", "c"])
        state.selectFile(state.noteFiles[2])

        state.selectNextFile()

        XCTAssertEqual(state.selectedFile?.id, "a")
    }

    func testSelectNextFileWithNoSelection() {
        let state = makeAppState(fileNames: ["a", "b", "c"])

        state.selectNextFile()

        XCTAssertEqual(state.selectedFile?.id, "a")
    }

    func testSelectNextFileEmptyList() {
        let state = makeAppState(fileNames: [])

        state.selectNextFile()

        XCTAssertNil(state.selectedFile)
    }

    // MARK: - selectPreviousFile

    func testSelectPreviousFileFromLast() {
        let state = makeAppState(fileNames: ["a", "b", "c"])
        state.selectFile(state.noteFiles[2])

        state.selectPreviousFile()

        XCTAssertEqual(state.selectedFile?.id, "b")
    }

    func testSelectPreviousFileFromMiddle() {
        let state = makeAppState(fileNames: ["a", "b", "c"])
        state.selectFile(state.noteFiles[1])

        state.selectPreviousFile()

        XCTAssertEqual(state.selectedFile?.id, "a")
    }

    func testSelectPreviousFileFromFirstWrapsToLast() {
        let state = makeAppState(fileNames: ["a", "b", "c"])
        state.selectFile(state.noteFiles[0])

        state.selectPreviousFile()

        XCTAssertEqual(state.selectedFile?.id, "c")
    }

    func testSelectPreviousFileWithNoSelectionSelectsFirst() {
        let state = makeAppState(fileNames: ["a", "b", "c"])

        state.selectPreviousFile()

        XCTAssertEqual(state.selectedFile?.id, "a")
    }

    func testSelectPreviousFileEmptyList() {
        let state = makeAppState(fileNames: [])

        state.selectPreviousFile()

        XCTAssertNil(state.selectedFile)
    }

    // MARK: - Single file edge case

    func testSelectNextFileSingleFile() {
        let state = makeAppState(fileNames: ["only"])
        state.selectFile(state.noteFiles[0])

        state.selectNextFile()

        XCTAssertEqual(state.selectedFile?.id, "only")
    }

    func testSelectPreviousFileSingleFile() {
        let state = makeAppState(fileNames: ["only"])
        state.selectFile(state.noteFiles[0])

        state.selectPreviousFile()

        XCTAssertEqual(state.selectedFile?.id, "only")
    }
}
