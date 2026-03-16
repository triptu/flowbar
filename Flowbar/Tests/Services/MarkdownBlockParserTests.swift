import Testing
@testable import Flowbar

@Suite("MarkdownParser block parsing")
struct MarkdownBlockParserTests {

    // MARK: - Headings

    @Test("parses heading levels", arguments: [
        ("# Title", 1, "Title"),
        ("## Section", 2, "Section"),
        ("### Sub", 3, "Sub"),
        ("###### Deep", 6, "Deep"),
    ])
    func headings(input: String, level: Int, text: String) {
        let blocks = MarkdownParser.parseBlocks(from: input)
        #expect(blocks == [.heading(level: level, text: text)])
    }

    @Test("ignores invalid headings", arguments: [
        "#NoSpace",
        "####### Seven hashes",
    ])
    func invalidHeadings(input: String) {
        let blocks = MarkdownParser.parseBlocks(from: input)
        guard case .paragraph = blocks.first else {
            Issue.record("Expected paragraph, got \(blocks.first!)")
            return
        }
    }

    // MARK: - Todos

    @Test("parses todos with indent", arguments: [
        ("- [ ] Task", false, "Task", 0),
        ("  - [ ] Nested", false, "Nested", 2),
        ("    - [x] Deep done", true, "Deep done", 4),
        ("- [X] Capital X", true, "Capital X", 0),
    ])
    func todosWithIndent(input: String, isDone: Bool, text: String, indent: Int) {
        let blocks = MarkdownParser.parseBlocks(from: input)
        #expect(blocks == [.todo(isDone: isDone, text: text, lineIndex: 0, indent: indent)])
    }

    @Test("nested todos under a parent preserve indent levels")
    func nestedTodoTree() {
        let content = "- [ ] Parent\n  - [ ] Child\n    - [ ] Grandchild"
        let blocks = MarkdownParser.parseBlocks(from: content)
        #expect(blocks == [
            .todo(isDone: false, text: "Parent", lineIndex: 0, indent: 0),
            .todo(isDone: false, text: "Child", lineIndex: 1, indent: 2),
            .todo(isDone: false, text: "Grandchild", lineIndex: 2, indent: 4),
        ])
    }

    // MARK: - Bullets

    @Test("parses bullets with indent", arguments: [
        ("- Item", "Item", 0),
        ("  - Nested", "Nested", 2),
        ("    - Deep", "Deep", 4),
        ("* Star bullet", "Star bullet", 0),
        ("  * Nested star", "Nested star", 2),
    ])
    func bulletsWithIndent(input: String, text: String, indent: Int) {
        let blocks = MarkdownParser.parseBlocks(from: input)
        #expect(blocks == [.bullet(text: text, indent: indent)])
    }

    @Test("nested bullet list preserves hierarchy")
    func nestedBulletList() {
        let content = "- Top\n  - Middle\n    - Bottom"
        let blocks = MarkdownParser.parseBlocks(from: content)
        #expect(blocks == [
            .bullet(text: "Top", indent: 0),
            .bullet(text: "Middle", indent: 2),
            .bullet(text: "Bottom", indent: 4),
        ])
    }

    // MARK: - Numbered lists

    @Test("parses numbered lists with indent", arguments: [
        ("1. First", 1, "First", 0),
        ("2. Second", 2, "Second", 0),
        ("  1. Nested", 1, "Nested", 2),
    ])
    func numberedWithIndent(input: String, number: Int, text: String, indent: Int) {
        let blocks = MarkdownParser.parseBlocks(from: input)
        #expect(blocks == [.numbered(number: number, text: text, indent: indent)])
    }

    // MARK: - Code blocks

    @Test("parses fenced code block")
    func codeBlock() {
        let content = "```\nlet x = 1\nprint(x)\n```"
        let blocks = MarkdownParser.parseBlocks(from: content)
        #expect(blocks == [.codeBlock("let x = 1\nprint(x)")])
    }

    @Test("unclosed code block still captured")
    func unclosedCodeBlock() {
        let content = "```\nsome code"
        let blocks = MarkdownParser.parseBlocks(from: content)
        #expect(blocks == [.codeBlock("some code")])
    }

    // MARK: - Blockquotes

    @Test("parses blockquote")
    func blockquote() {
        let blocks = MarkdownParser.parseBlocks(from: "> A quote")
        #expect(blocks == [.blockquote("A quote")])
    }

    // MARK: - Horizontal rules

    @Test("parses horizontal rules", arguments: ["---", "***", "___", "- - -"])
    func horizontalRules(input: String) {
        let blocks = MarkdownParser.parseBlocks(from: input)
        #expect(blocks == [.horizontalRule])
    }

    // MARK: - Mixed content

    @Test("mixed document preserves order and types")
    func mixedDocument() {
        let content = """
        # Title

        Some paragraph.

        - [ ] Todo
          - [ ] Nested todo
        - Bullet
          - Nested bullet

        > Quote

        ```
        code
        ```

        ---
        """
        let blocks = MarkdownParser.parseBlocks(from: content)
        #expect(blocks == [
            .heading(level: 1, text: "Title"),
            .empty,
            .paragraph("Some paragraph."),
            .empty,
            .todo(isDone: false, text: "Todo", lineIndex: 4, indent: 0),
            .todo(isDone: false, text: "Nested todo", lineIndex: 5, indent: 2),
            .bullet(text: "Bullet", indent: 0),
            .bullet(text: "Nested bullet", indent: 2),
            .empty,
            .blockquote("Quote"),
            .empty,
            .codeBlock("code"),
            .empty,
            .horizontalRule,
        ])
    }

    // MARK: - Empty and edge cases

    @Test("empty string produces single empty block")
    func emptyString() {
        let blocks = MarkdownParser.parseBlocks(from: "")
        #expect(blocks == [.empty])
    }

    @Test("line indices are correct for todos in mixed content")
    func todoLineIndices() {
        let content = "# Title\nSome text\n- [ ] First\n\n- [x] Second"
        let blocks = MarkdownParser.parseBlocks(from: content)
        let todos = blocks.compactMap { block -> (lineIndex: Int, indent: Int)? in
            if case .todo(_, _, let lineIndex, let indent) = block { return (lineIndex, indent) }
            return nil
        }
        #expect(todos.count == 2)
        #expect(todos[0] == (lineIndex: 2, indent: 0))
        #expect(todos[1] == (lineIndex: 4, indent: 0))
    }
}
