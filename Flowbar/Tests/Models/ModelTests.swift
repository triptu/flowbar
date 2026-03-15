import Testing
@testable import Flowbar
import Foundation

@Suite("NoteFile")
struct NoteFileTests {

    @Test("formatName", arguments: [
        ("notes", "Notes"),
        ("daily-journal", "Daily Journal"),
        ("My-Notes", "My Notes"),
        ("", ""),
    ] as [(String, String)])
    func formatName(input: String, expected: String) {
        #expect(NoteFile.formatName(input) == expected)
    }

    @Test("init derives id and name from URL")
    func initFromURL() {
        let file = NoteFile(url: URL(fileURLWithPath: "/tmp/test-file.md"))
        #expect(file.id == "test-file")
        #expect(file.name == "Test File")
    }

    @Test("equality by URL")
    func equality() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        #expect(NoteFile(url: url) == NoteFile(url: url))
    }
}

@Suite("TodoItem")
struct TodoItemTests {

    @Test("id combines source file, line, and text")
    func id() {
        let noteFile = NoteFile(url: URL(fileURLWithPath: "/tmp/notes.md"))
        let todo = TodoItem(text: "Buy milk", isDone: false, sourceFile: noteFile, lineIndex: 3)
        #expect(todo.id == "notes:3:Buy milk")
    }

    @Test("stores all properties")
    func properties() {
        let noteFile = NoteFile(url: URL(fileURLWithPath: "/tmp/tasks.md"))
        let todo = TodoItem(text: "Walk dog", isDone: true, sourceFile: noteFile, lineIndex: 5)
        #expect(todo.text == "Walk dog")
        #expect(todo.isDone)
        #expect(todo.sourceFile == noteFile)
        #expect(todo.lineIndex == 5)
    }
}

@Suite("ActivePanel")
struct ActivePanelTests {

    @Test("enum equality")
    func equality() {
        let file = NoteFile(url: URL(fileURLWithPath: "/tmp/test.md"))
        #expect(ActivePanel.settings == ActivePanel.settings)
        #expect(ActivePanel.timer == ActivePanel.timer)
        #expect(ActivePanel.empty == ActivePanel.empty)
        #expect(ActivePanel.file(file) == ActivePanel.file(file))
        #expect(ActivePanel.settings != ActivePanel.timer)
    }
}

@Suite("AppTheme")
struct AppThemeTests {

    @Test("raw values", arguments: [
        (AppTheme.light, "light"),
        (AppTheme.dark, "dark"),
        (AppTheme.system, "system"),
    ] as [(AppTheme, String)])
    func rawValues(theme: AppTheme, expected: String) {
        #expect(theme.rawValue == expected)
    }

    @Test("allCases")
    func allCases() {
        #expect(AppTheme.allCases == [.light, .dark, .system])
    }
}

@Suite("TypographySize")
struct TypographySizeTests {

    @Test("sizes per variant", arguments: [
        (TypographySize.small,   12.0, 20.0, 13.0, 48.0),
        (TypographySize.default, 14.0, 24.0, 15.0, 48.0),
        (TypographySize.large,   16.0, 28.0, 17.0, 48.0),
    ] as [(TypographySize, CGFloat, CGFloat, CGFloat, CGFloat)])
    func sizes(variant: TypographySize, body: CGFloat, title: CGFloat, sidebar: CGFloat, timer: CGFloat) {
        #expect(variant.bodySize == body)
        #expect(variant.titleSize == title)
        #expect(variant.sidebarSize == sidebar)
        #expect(variant.timerSize == timer)
    }

    @Test("allCases")
    func allCases() {
        #expect(TypographySize.allCases == [.small, .default, .large])
    }
}
