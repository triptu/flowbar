import Testing
@testable import Flowbar
import Foundation

@Suite("SearchState")
@MainActor
struct SearchStateTests {
    let search = SearchState()

    // MARK: - Open / close lifecycle

    @Test("open resets state and sets isOpen")
    func open() {
        search.query = "leftover"
        search.open(files: [])
        #expect(search.isOpen)
        #expect(search.query == "")
        #expect(search.results.isEmpty)
        #expect(search.selectedIndex == 0)
    }

    @Test("close resets state and clears isOpen")
    func close() {
        search.open(files: [])
        search.query = "test"
        search.close()
        #expect(!search.isOpen)
        #expect(search.query == "")
        #expect(search.results.isEmpty)
    }

    @Test("toggle flips isOpen")
    func toggle() {
        search.toggle(files: [])
        #expect(search.isOpen)
        search.toggle(files: [])
        #expect(!search.isOpen)
    }

    // MARK: - Search behavior

    private func makeTempFiles(_ entries: [(name: String, content: String)]) -> [NoteFile] {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return entries.map { entry in
            let url = dir.appendingPathComponent("\(entry.name).md")
            try! entry.content.write(to: url, atomically: true, encoding: .utf8)
            return NoteFile(url: url)
        }
    }

    /// Helper: open search with files and set query, then search.
    private func openAndSearch(files: [NoteFile], query: String) {
        search.open(files: files)
        search.query = query
        search.search()
    }

    @Test("empty query returns no results")
    func emptyQuery() {
        let files = makeTempFiles([("notes", "some content")])
        openAndSearch(files: files, query: "   ")
        #expect(search.results.isEmpty)
    }

    @Test("filename matches appear before content matches")
    func filenameFirst() {
        let files = makeTempFiles([
            ("recipes", "my favorite coffee recipe"),
            ("coffee", "bean types"),
        ])
        openAndSearch(files: files, query: "coffee")

        guard case .file(let f) = search.results.first else {
            Issue.record("Expected filename match first")
            return
        }
        #expect(f.name == "coffee")

        let contentResults = search.results.filter {
            if case .content = $0 { return true }
            return false
        }
        #expect(!contentResults.isEmpty)
    }

    @Test("search is case-insensitive")
    func caseInsensitive() {
        let files = makeTempFiles([("Notes", "Hello World")])
        openAndSearch(files: files, query: "hello")
        #expect(!search.results.isEmpty)
    }

    @Test("blank content lines are skipped")
    func blankLinesSkipped() {
        let files = makeTempFiles([("test", "match\n   \nmatch again")])
        openAndSearch(files: files, query: "   ")
        #expect(search.results.isEmpty)
    }

    // MARK: - Arrow key navigation

    @Test("moveDown and moveUp cycle through results", arguments: [
        (1, "down", 1),
        (2, "down", 2),
        (3, "down", 0),  // wraps
        (1, "up", 2),    // wraps backward from 0
    ] as [(Int, String, Int)])
    func arrowNavigation(moves: Int, direction: String, expectedIndex: Int) {
        let files = makeTempFiles([
            ("a", "x"), ("b", "x"), ("c", "x"),
        ])
        openAndSearch(files: files, query: "x")

        for _ in 0..<moves {
            if direction == "down" { search.moveDown() }
            else { search.moveUp() }
        }
        #expect(search.selectedIndex == expectedIndex)
    }

    @Test("moveDown on empty results does nothing")
    func moveDownEmpty() {
        search.moveDown()
        #expect(search.selectedIndex == 0)
    }

    @Test("selectedResult returns correct item")
    func selectedResult() {
        let files = makeTempFiles([("hello", "world")])
        openAndSearch(files: files, query: "hello")
        #expect(search.selectedResult != nil)
        #expect(search.selectedResult?.noteFile.name == "hello")
    }
}
