import Testing
@testable import Flowbar
import Foundation

@Suite("MarkdownParser")
struct MarkdownParserTests {

    private var tempDir: URL

    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowbarTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    private func writeMarkdown(_ content: String, filename: String = "test.md") -> URL {
        let url = tempDir.appendingPathComponent(filename)
        try! content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - extractTodos

    @Test("extractTodos finds incomplete todos")
    func extractIncompleteTodos() {
        let url = writeMarkdown("# Notes\n- [ ] Buy milk\n- [ ] Walk dog\nSome text\n")
        let todos = MarkdownParser.extractTodos(from: url, noteFile: NoteFile(url: url))

        #expect(todos.count == 2)
        #expect(todos[0].text == "Buy milk")
        #expect(!todos[0].isDone)
        #expect(todos[0].lineIndex == 1)
        #expect(todos[1].text == "Walk dog")
        #expect(todos[1].lineIndex == 2)
    }

    @Test("extractTodos finds complete todos")
    func extractCompleteTodos() {
        let url = writeMarkdown("- [x] Done task\n- [X] Also done\n")
        let todos = MarkdownParser.extractTodos(from: url, noteFile: NoteFile(url: url))

        #expect(todos.count == 2)
        #expect(todos[0].isDone)
        #expect(todos[0].text == "Done task")
        #expect(todos[1].isDone)
        #expect(todos[1].text == "Also done")
    }

    @Test("extractTodos with mixed content")
    func extractMixedContent() {
        let content = """
        # Header
        Some paragraph text

        - [ ] Incomplete task
        - [x] Complete task
        - Regular list item
        - [ ] Another incomplete

        More text
        """
        let url = writeMarkdown(content)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: NoteFile(url: url))

        #expect(todos.count == 3)
        #expect(!todos[0].isDone)
        #expect(todos[1].isDone)
        #expect(!todos[2].isDone)
    }

    @Test("extractTodos returns empty for no-todo inputs", arguments: [
        "",
        "# Just a header\nSome text\n- Regular item\n",
    ])
    func extractTodosEmpty(content: String) {
        let url = writeMarkdown(content)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: NoteFile(url: url))
        #expect(todos.isEmpty)
    }

    @Test("extractTodos returns empty for nonexistent file")
    func extractTodosNonexistent() {
        let url = tempDir.appendingPathComponent("nonexistent.md")
        let todos = MarkdownParser.extractTodos(from: url, noteFile: NoteFile(url: url))
        #expect(todos.isEmpty)
    }

    @Test("extractTodos preserves line indices")
    func extractTodosLineIndex() {
        let url = writeMarkdown("Line 0\nLine 1\n- [ ] Task at line 2\nLine 3\n- [ ] Task at line 4\n")
        let todos = MarkdownParser.extractTodos(from: url, noteFile: NoteFile(url: url))
        #expect(todos[0].lineIndex == 2)
        #expect(todos[1].lineIndex == 4)
    }

    @Test("extractTodos handles indented tasks")
    func extractTodosIndented() {
        let url = writeMarkdown("  - [ ] Indented task\n    - [x] Deeply indented\n")
        let todos = MarkdownParser.extractTodos(from: url, noteFile: NoteFile(url: url))

        #expect(todos.count == 2)
        #expect(todos[0].text == "Indented task")
        #expect(todos[1].text == "Deeply indented")
    }

    // MARK: - toggleTodo

    @Test("toggleTodo flips incomplete to complete")
    func toggleIncompleteToComplete() throws {
        let url = writeMarkdown("- [ ] My task\n")
        #expect(MarkdownParser.toggleTodo(at: 0, in: url))
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("- [x] My task"))
    }

    @Test("toggleTodo flips complete to incomplete", arguments: [
        "- [x] Done task",
        "- [X] Done task",
    ])
    func toggleCompleteToIncomplete(line: String) throws {
        let url = writeMarkdown(line + "\n")
        #expect(MarkdownParser.toggleTodo(at: 0, in: url))
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("- [ ] Done task"))
    }

    @Test("toggleTodo returns false for non-todo line")
    func toggleNonTodo() {
        let url = writeMarkdown("Regular text\n")
        #expect(!MarkdownParser.toggleTodo(at: 0, in: url))
    }

    @Test("toggleTodo returns false for out-of-bounds index")
    func toggleOutOfBounds() {
        let url = writeMarkdown("- [ ] Only line\n")
        #expect(!MarkdownParser.toggleTodo(at: 10, in: url))
    }

    @Test("toggleTodo preserves surrounding lines")
    func togglePreservesOtherLines() throws {
        let url = writeMarkdown("# Header\n- [ ] Task\n- [x] Done\nParagraph\n")
        _ = MarkdownParser.toggleTodo(at: 1, in: url)

        let result = try String(contentsOf: url, encoding: .utf8)
        #expect(result.contains("# Header"))
        #expect(result.contains("- [x] Task"))
        #expect(result.contains("- [x] Done"))
        #expect(result.contains("Paragraph"))
    }

    // MARK: - markTodoDone

    @Test("markTodoDone marks matching text")
    func markDoneByText() throws {
        let url = writeMarkdown("- [ ] First\n- [ ] Second\n- [ ] Third\n")
        MarkdownParser.markTodoDone(text: "Second", in: url)

        let result = try String(contentsOf: url, encoding: .utf8)
        #expect(result.contains("- [ ] First"))
        #expect(result.contains("- [x] Second"))
        #expect(result.contains("- [ ] Third"))
    }

    @Test("markTodoDone leaves already-done unchanged")
    func markDoneAlreadyDone() throws {
        let url = writeMarkdown("- [x] Already done\n")
        MarkdownParser.markTodoDone(text: "Already done", in: url)
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("- [x] Already done"))
    }

    @Test("markTodoDone ignores nonexistent text")
    func markDoneNonexistent() throws {
        let url = writeMarkdown("- [ ] Existing task\n")
        MarkdownParser.markTodoDone(text: "Not here", in: url)
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("- [ ] Existing task"))
    }
}
