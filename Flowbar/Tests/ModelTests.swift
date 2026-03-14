import XCTest
@testable import Flowbar

final class NoteFileTests: XCTestCase {

    func testFormatNameSingleWord() {
        XCTAssertEqual(NoteFile.formatName("notes"), "Notes")
    }

    func testFormatNameMultipleWords() {
        XCTAssertEqual(NoteFile.formatName("daily-journal"), "Daily Journal")
    }

    func testFormatNameAlreadyCapitalized() {
        XCTAssertEqual(NoteFile.formatName("My-Notes"), "My Notes")
    }

    func testFormatNameEmpty() {
        XCTAssertEqual(NoteFile.formatName(""), "")
    }

    func testNoteFileInit() {
        let url = URL(fileURLWithPath: "/tmp/test-file.md")
        let file = NoteFile(url: url)

        XCTAssertEqual(file.id, "test-file")
        XCTAssertEqual(file.name, "Test File")
        XCTAssertEqual(file.url, url)
    }

    func testNoteFileEquality() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let file1 = NoteFile(url: url)
        let file2 = NoteFile(url: url)

        XCTAssertEqual(file1, file2)
    }
}

final class TodoItemTests: XCTestCase {

    func testTodoItemId() {
        let noteFile = NoteFile(url: URL(fileURLWithPath: "/tmp/notes.md"))
        let todo = TodoItem(text: "Buy milk", isDone: false, sourceFile: noteFile, lineIndex: 3)

        XCTAssertEqual(todo.id, "notes:3:Buy milk")
    }

    func testTodoItemProperties() {
        let noteFile = NoteFile(url: URL(fileURLWithPath: "/tmp/tasks.md"))
        let todo = TodoItem(text: "Walk dog", isDone: true, sourceFile: noteFile, lineIndex: 5)

        XCTAssertEqual(todo.text, "Walk dog")
        XCTAssertTrue(todo.isDone)
        XCTAssertEqual(todo.sourceFile, noteFile)
        XCTAssertEqual(todo.lineIndex, 5)
    }
}

final class ActivePanelTests: XCTestCase {

    func testActivePanelEquality() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let file = NoteFile(url: url)

        XCTAssertEqual(ActivePanel.settings, ActivePanel.settings)
        XCTAssertEqual(ActivePanel.timer, ActivePanel.timer)
        XCTAssertEqual(ActivePanel.empty, ActivePanel.empty)
        XCTAssertEqual(ActivePanel.file(file), ActivePanel.file(file))
        XCTAssertNotEqual(ActivePanel.settings, ActivePanel.timer)
    }
}

final class AppThemeTests: XCTestCase {

    func testAllCases() {
        XCTAssertEqual(AppTheme.allCases, [.light, .dark, .system])
    }

    func testRawValues() {
        XCTAssertEqual(AppTheme.light.rawValue, "light")
        XCTAssertEqual(AppTheme.dark.rawValue, "dark")
        XCTAssertEqual(AppTheme.system.rawValue, "system")
    }
}

final class TypographySizeTests: XCTestCase {

    func testBodySizes() {
        XCTAssertEqual(TypographySize.small.bodySize, 12)
        XCTAssertEqual(TypographySize.default.bodySize, 14)
        XCTAssertEqual(TypographySize.large.bodySize, 16)
    }

    func testTitleSizes() {
        XCTAssertEqual(TypographySize.small.titleSize, 20)
        XCTAssertEqual(TypographySize.default.titleSize, 24)
        XCTAssertEqual(TypographySize.large.titleSize, 28)
    }

    func testSidebarSizes() {
        XCTAssertEqual(TypographySize.small.sidebarSize, 13)
        XCTAssertEqual(TypographySize.default.sidebarSize, 15)
        XCTAssertEqual(TypographySize.large.sidebarSize, 17)
    }

    func testTimerSize() {
        XCTAssertEqual(TypographySize.small.timerSize, 48)
        XCTAssertEqual(TypographySize.default.timerSize, 48)
        XCTAssertEqual(TypographySize.large.timerSize, 48)
    }

    func testAllCases() {
        XCTAssertEqual(TypographySize.allCases, [.small, .default, .large])
    }
}
