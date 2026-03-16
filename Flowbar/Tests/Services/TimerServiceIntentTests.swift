import Testing
@testable import Flowbar
import Foundation

@Suite("TimerService intents")
@MainActor
struct TimerServiceIntentTests {

    private var timer: TimerService
    private var tempDir: URL

    init() throws {
        timer = TimerService()
        if timer.hasActiveSession { timer.clear() }
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowbarIntentTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    private func noteFile(_ name: String = "tasks") -> NoteFile {
        NoteFile(url: tempDir.appendingPathComponent("\(name).md"))
    }

    private func writeTodos(_ content: String, filename: String = "tasks.md") throws -> URL {
        let url = tempDir.appendingPathComponent(filename)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func readFile(_ url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Screen state

    @Test("start keeps screen on todos")
    func startScreenStaysTodos() {
        timer.start(todoText: "A", sourceFile: "tasks")
        #expect(timer.screen == .todos)
        timer.clear()
    }

    @Test("clear sets screen to todos")
    func stopScreenTodos() {
        timer.start(todoText: "A", sourceFile: "tasks")
        timer.toggleScreen()
        #expect(timer.screen == .home)
        timer.clear()
        #expect(timer.screen == .todos)
    }

    @Test("complete sets screen to todos")
    func completeScreenTodos() {
        timer.start(todoText: "A", sourceFile: "tasks")
        timer.toggleScreen()
        _ = timer.complete()
        #expect(timer.screen == .todos)
    }

    // MARK: - Bug 1: paused → stop/complete navigation

    @Test("clear while paused sets screen to todos")
    func stopWhilePausedScreen() {
        timer.start(todoText: "A", sourceFile: "tasks")
        timer.toggleScreen()
        timer.pause()
        timer.clear()
        #expect(timer.screen == .todos)
        #expect(!timer.hasActiveSession)
    }

    @Test("complete while paused sets screen to todos")
    func completeWhilePausedScreen() {
        timer.start(todoText: "A", sourceFile: "tasks")
        timer.toggleScreen()
        timer.pause()
        let result = timer.complete()
        #expect(timer.screen == .todos)
        #expect(!timer.hasActiveSession)
        #expect(result?.todoText == "A")
    }

    // MARK: - startTodo intent

    @Test("startTodo on new item starts timer")
    func startTodoNew() throws {
        _ = try writeTodos("- [ ] Buy milk\n")
        let nf = noteFile()
        let todo = TodoItem(text: "Buy milk", isDone: false, sourceFile: nf, lineIndex: 0)

        timer.startTodo(todo)
        #expect(timer.isRunning)
        #expect(timer.currentTodoText == "Buy milk")
        timer.clear()
    }

    @Test("startTodo on same item toggles play/pause")
    func startTodoSameToggles() throws {
        let nf = noteFile()
        let todo = TodoItem(text: "Buy milk", isDone: false, sourceFile: nf, lineIndex: 0)

        timer.startTodo(todo)
        #expect(timer.isRunning)

        timer.startTodo(todo)
        #expect(timer.isPaused)

        timer.startTodo(todo)
        #expect(timer.isRunning)

        timer.clear()
    }

    @Test("startTodo on done item untoggles markdown first")
    func startTodoDoneItem() throws {
        let url = try writeTodos("- [x] Done task\n")
        let nf = noteFile()
        let todo = TodoItem(text: "Done task", isDone: true, sourceFile: nf, lineIndex: 0)

        timer.startTodo(todo)

        let content = try readFile(url)
        #expect(content.contains("- [ ] Done task"))
        #expect(timer.isRunning)
        #expect(timer.currentTodoText == "Done task")
        timer.clear()
    }

    @Test("startTodo on different item stops previous")
    func startTodoDifferentItem() {
        let nf = noteFile()
        let first = TodoItem(text: "First", isDone: false, sourceFile: nf, lineIndex: 0)
        let second = TodoItem(text: "Second", isDone: false, sourceFile: nf, lineIndex: 1)

        timer.startTodo(first)
        timer.startTodo(second)

        #expect(timer.currentTodoText == "Second")
        #expect(timer.isRunning)
        timer.clear()
    }

    // MARK: - toggleTodo intent

    @Test("toggleTodo on tracked item clears timer then toggles")
    func toggleTodoTracked() throws {
        let url = try writeTodos("- [ ] Active task\n")
        let nf = noteFile()
        let todo = TodoItem(text: "Active task", isDone: false, sourceFile: nf, lineIndex: 0)

        timer.startTodo(todo)
        #expect(timer.isRunning)

        timer.toggleTodo(todo)
        #expect(!timer.hasActiveSession)
        let content = try readFile(url)
        #expect(content.contains("- [x] Active task"))
    }

    @Test("toggleTodo on untracked item just toggles markdown")
    func toggleTodoUntracked() throws {
        let url = try writeTodos("- [ ] Other task\n- [ ] Active task\n")
        let nf = noteFile()
        let other = TodoItem(text: "Other task", isDone: false, sourceFile: nf, lineIndex: 0)
        let active = TodoItem(text: "Active task", isDone: false, sourceFile: nf, lineIndex: 1)

        timer.startTodo(active)
        timer.toggleTodo(other)

        #expect(timer.isRunning)
        #expect(timer.currentTodoText == "Active task")
        let content = try readFile(url)
        #expect(content.contains("- [x] Other task"))
        #expect(content.contains("- [ ] Active task"))
        timer.clear()
    }

    // MARK: - completeAndMarkDone intent

    @Test("completeAndMarkDone marks todo done and clears state")
    func completeAndMarkDone() throws {
        let url = try writeTodos("- [ ] Ship feature\n")
        let nf = noteFile()
        let todo = TodoItem(text: "Ship feature", isDone: false, sourceFile: nf, lineIndex: 0)

        timer.startTodo(todo)
        timer.completeAndMarkDone(folderPath: tempDir.path)

        #expect(!timer.hasActiveSession)
        #expect(timer.screen == .todos)
        let content = try readFile(url)
        #expect(content.contains("- [x] Ship feature"))
    }

    @Test("completeAndMarkDone while paused works correctly")
    func completeAndMarkDoneWhilePaused() throws {
        let url = try writeTodos("- [ ] Paused task\n")
        let nf = noteFile()
        let todo = TodoItem(text: "Paused task", isDone: false, sourceFile: nf, lineIndex: 0)

        timer.startTodo(todo)
        timer.pause()
        timer.completeAndMarkDone(folderPath: tempDir.path)

        #expect(!timer.hasActiveSession)
        #expect(timer.screen == .todos)
        let content = try readFile(url)
        #expect(content.contains("- [x] Paused task"))
    }

    // MARK: - Bug 3: duplicate text uses lineIndex

    @Test("completeAndMarkDone with duplicate text marks correct line via lineIndex")
    func completeAndMarkDoneDuplicate() throws {
        let url = try writeTodos("- [ ] Same task\n- [ ] Same task\n")
        let nf = noteFile()
        // Start tracking the second occurrence (lineIndex 1)
        let todo = TodoItem(text: "Same task", isDone: false, sourceFile: nf, lineIndex: 1)

        timer.startTodo(todo)
        timer.completeAndMarkDone(folderPath: tempDir.path)

        let content = try readFile(url)
        let lines = content.components(separatedBy: "\n")
        #expect(lines[0] == "- [ ] Same task")  // first unchanged
        #expect(lines[1] == "- [x] Same task")  // second marked done
    }

    @Test("completeAndMarkDone falls back to text match when lineIndex is stale")
    func completeAndMarkDoneStaleLineIndex() throws {
        let url = try writeTodos("- [ ] Original task\n")
        let nf = noteFile()
        let todo = TodoItem(text: "Original task", isDone: false, sourceFile: nf, lineIndex: 0)

        timer.startTodo(todo)
        // Simulate external edit: line 0 is now different, but task moved to line 1
        try "- [ ] Inserted line\n- [ ] Original task\n".write(to: url, atomically: true, encoding: .utf8)
        timer.completeAndMarkDone(folderPath: tempDir.path)

        let content = try readFile(url)
        #expect(content.contains("- [ ] Inserted line"))
        #expect(content.contains("- [x] Original task"))
    }

    // MARK: - toggleScreen

    @Test("toggleScreen flips between todos and home")
    func toggleScreenFlips() {
        #expect(timer.screen == .todos)
        timer.toggleScreen()
        #expect(timer.screen == .home)
        timer.toggleScreen()
        #expect(timer.screen == .todos)
    }
}
