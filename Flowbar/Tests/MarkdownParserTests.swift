import XCTest
@testable import Flowbar

final class MarkdownParserTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowbarTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func writeMarkdown(_ content: String, filename: String = "test.md") -> URL {
        let url = tempDir.appendingPathComponent(filename)
        try! content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - extractTodos

    func testExtractTodosFindsIncompleteTodos() {
        let url = writeMarkdown("# Notes\n- [ ] Buy milk\n- [ ] Walk dog\nSome text\n")
        let noteFile = NoteFile(url: url)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: noteFile)

        XCTAssertEqual(todos.count, 2)
        XCTAssertEqual(todos[0].text, "Buy milk")
        XCTAssertFalse(todos[0].isDone)
        XCTAssertEqual(todos[0].lineIndex, 1)
        XCTAssertEqual(todos[1].text, "Walk dog")
        XCTAssertFalse(todos[1].isDone)
        XCTAssertEqual(todos[1].lineIndex, 2)
    }

    func testExtractTodosFindsCompleteTodos() {
        let url = writeMarkdown("- [x] Done task\n- [X] Also done\n")
        let noteFile = NoteFile(url: url)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: noteFile)

        XCTAssertEqual(todos.count, 2)
        XCTAssertTrue(todos[0].isDone)
        XCTAssertEqual(todos[0].text, "Done task")
        XCTAssertTrue(todos[1].isDone)
        XCTAssertEqual(todos[1].text, "Also done")
    }

    func testExtractTodosMixedContent() {
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
        let noteFile = NoteFile(url: url)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: noteFile)

        XCTAssertEqual(todos.count, 3)
        XCTAssertFalse(todos[0].isDone)
        XCTAssertTrue(todos[1].isDone)
        XCTAssertFalse(todos[2].isDone)
    }

    func testExtractTodosEmptyFile() {
        let url = writeMarkdown("")
        let noteFile = NoteFile(url: url)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: noteFile)

        XCTAssertTrue(todos.isEmpty)
    }

    func testExtractTodosNoTodos() {
        let url = writeMarkdown("# Just a header\nSome text\n- Regular item\n")
        let noteFile = NoteFile(url: url)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: noteFile)

        XCTAssertTrue(todos.isEmpty)
    }

    func testExtractTodosNonexistentFile() {
        let url = tempDir.appendingPathComponent("nonexistent.md")
        let noteFile = NoteFile(url: url)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: noteFile)

        XCTAssertTrue(todos.isEmpty)
    }

    func testExtractTodosPreservesLineIndex() {
        let content = "Line 0\nLine 1\n- [ ] Task at line 2\nLine 3\n- [ ] Task at line 4\n"
        let url = writeMarkdown(content)
        let noteFile = NoteFile(url: url)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: noteFile)

        XCTAssertEqual(todos[0].lineIndex, 2)
        XCTAssertEqual(todos[1].lineIndex, 4)
    }

    func testExtractTodosWithIndentation() {
        let content = "  - [ ] Indented task\n    - [x] Deeply indented\n"
        let url = writeMarkdown(content)
        let noteFile = NoteFile(url: url)
        let todos = MarkdownParser.extractTodos(from: url, noteFile: noteFile)

        XCTAssertEqual(todos.count, 2)
        XCTAssertEqual(todos[0].text, "Indented task")
        XCTAssertEqual(todos[1].text, "Deeply indented")
    }

    // MARK: - toggleTodo

    func testToggleTodoIncompleteToComplete() {
        let url = writeMarkdown("- [ ] My task\n")
        let result = MarkdownParser.toggleTodo(at: 0, in: url)

        XCTAssertTrue(result)
        let content = try! String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("- [x] My task"))
    }

    func testToggleTodoCompleteToIncomplete() {
        let url = writeMarkdown("- [x] Done task\n")
        let result = MarkdownParser.toggleTodo(at: 0, in: url)

        XCTAssertTrue(result)
        let content = try! String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("- [ ] Done task"))
    }

    func testToggleTodoUppercaseX() {
        let url = writeMarkdown("- [X] Done task\n")
        let result = MarkdownParser.toggleTodo(at: 0, in: url)

        XCTAssertTrue(result)
        let content = try! String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("- [ ] Done task"))
    }

    func testToggleTodoNonTodoLine() {
        let url = writeMarkdown("Regular text\n")
        let result = MarkdownParser.toggleTodo(at: 0, in: url)

        XCTAssertFalse(result)
    }

    func testToggleTodoOutOfBounds() {
        let url = writeMarkdown("- [ ] Only line\n")
        let result = MarkdownParser.toggleTodo(at: 10, in: url)

        XCTAssertFalse(result)
    }

    func testToggleTodoPreservesOtherLines() {
        let content = "# Header\n- [ ] Task\n- [x] Done\nParagraph\n"
        let url = writeMarkdown(content)
        _ = MarkdownParser.toggleTodo(at: 1, in: url)

        let result = try! String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(result.contains("# Header"))
        XCTAssertTrue(result.contains("- [x] Task"))
        XCTAssertTrue(result.contains("- [x] Done"))
        XCTAssertTrue(result.contains("Paragraph"))
    }

    // MARK: - markTodoDone

    func testMarkTodoDoneByText() {
        let content = "- [ ] First\n- [ ] Second\n- [ ] Third\n"
        let url = writeMarkdown(content)
        MarkdownParser.markTodoDone(text: "Second", in: url)

        let result = try! String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(result.contains("- [ ] First"))
        XCTAssertTrue(result.contains("- [x] Second"))
        XCTAssertTrue(result.contains("- [ ] Third"))
    }

    func testMarkTodoDoneAlreadyDone() {
        let content = "- [x] Already done\n"
        let url = writeMarkdown(content)
        MarkdownParser.markTodoDone(text: "Already done", in: url)

        let result = try! String(contentsOf: url, encoding: .utf8)
        // Should remain unchanged since it's already done
        XCTAssertTrue(result.contains("- [x] Already done"))
    }

    func testMarkTodoDoneNonexistentText() {
        let content = "- [ ] Existing task\n"
        let url = writeMarkdown(content)
        MarkdownParser.markTodoDone(text: "Not here", in: url)

        let result = try! String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(result.contains("- [ ] Existing task"))
    }
}
