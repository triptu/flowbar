import Foundation
import Observation

/// Manages the stopwatch timer for tracking time spent on todos.
///
/// Owns all timer state, screen routing, and compound intents (startTodo, toggleTodo,
/// completeAndMarkDone). Views should be dumb — read state and call intent methods.
/// Persists sessions to SQLite via DatabaseService. Side-effects on markdown files
/// happen here so behavior is testable in one place.
@Observable
@MainActor
final class TimerService {
    enum Screen { case todos, home }

    var isRunning = false
    var isPaused = false
    var currentTodoText = ""
    var currentSourceFile = ""
    var elapsed: TimeInterval = 0
    var screen: Screen = .todos

    /// True when a timer session exists (running or paused)
    var hasActiveSession: Bool { isRunning || isPaused }

    @ObservationIgnored private var sessionId: Int64?
    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var pausedElapsed: TimeInterval = 0
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var currentLineIndex: Int?
    @ObservationIgnored private let db: DatabaseService

    init(db: DatabaseService = .shared) {
        self.db = db
        clearStaleSession()
    }

    /// On app launch, any session left active in the DB is stale — end it so the timer starts clean.
    private func clearStaleSession() {
        if let session = db.activeSession() {
            let finalElapsed = session.pausedElapsed ?? session.accumulated
            db.endSession(id: session.id, completed: false, finalElapsed: finalElapsed)
        }
    }

    // MARK: - Primitive state transitions

    func start(todoText: String, sourceFile: String) {
        if hasActiveSession { stopSession() }
        sessionId = db.startSession(todoText: todoText, sourceFile: sourceFile)
        currentTodoText = todoText
        currentSourceFile = sourceFile
        currentLineIndex = nil
        startedAt = Date()
        elapsed = 0
        pausedElapsed = 0
        isRunning = true
        isPaused = false
        startTicking()
    }

    func pause() {
        guard isRunning, let id = sessionId else { return }
        timer?.invalidate()
        timer = nil
        flushRunningSegment()
        pausedElapsed = elapsed
        isRunning = false
        isPaused = true
        db.pauseSession(id: id, elapsed: elapsed)
    }

    func resume() {
        guard isPaused, let id = sessionId else { return }
        startedAt = Date()
        isRunning = true
        isPaused = false
        db.resumeSession(id: id)
        startTicking()
    }

    /// Toggle between running and paused states. No-op if no active session.
    func togglePlayPause() {
        if isRunning { pause() } else if isPaused { resume() }
    }

    /// Ends the session without marking the todo done. Clears all state.
    func clear() {
        guard hasActiveSession, let id = sessionId else { return }
        flushRunningSegment()
        db.endSession(id: id, completed: false, finalElapsed: elapsed)
        cleanup()
    }

    /// Check if a specific todo is being tracked (running or paused)
    func isTracking(todoText: String, sourceFile: String) -> Bool {
        hasActiveSession && currentTodoText == todoText && currentSourceFile == sourceFile
    }

    func toggleScreen() {
        screen = (screen == .todos) ? .home : .todos
    }

    /// Ends the session as completed in the database and clears state.
    /// For completing AND marking the todo done in markdown, use completeAndMarkDone instead.
    @discardableResult
    func complete() -> (todoText: String, sourceFile: String)? {
        guard hasActiveSession, let id = sessionId else { return nil }
        flushRunningSegment()
        let result = (todoText: currentTodoText, sourceFile: currentSourceFile)
        db.endSession(id: id, completed: true, finalElapsed: elapsed)
        cleanup()
        return result
    }

    // MARK: - Compound intents (absorb view-layer business logic)

    /// Start tracking a todo. If already tracking this one, toggle play/pause.
    /// If the todo is done, un-mark it first.
    func startTodo(_ todo: TodoItem) {
        if isTracking(todoText: todo.text, sourceFile: todo.sourceFile.id) {
            togglePlayPause()
        } else {
            if todo.isDone {
                _ = MarkdownParser.toggleTodo(at: todo.lineIndex, in: todo.sourceFile.url)
            }
            start(todoText: todo.text, sourceFile: todo.sourceFile.id)
            currentLineIndex = todo.lineIndex
        }
    }

    /// Toggle a todo's checkbox. If toggling off the currently tracked todo, stop the timer.
    func toggleTodo(_ todo: TodoItem) {
        if !todo.isDone && isTracking(todoText: todo.text, sourceFile: todo.sourceFile.id) {
            clear()
        }
        _ = MarkdownParser.toggleTodo(at: todo.lineIndex, in: todo.sourceFile.url)
    }

    /// Complete the active session, mark the todo done in the markdown file, and clear state.
    func completeAndMarkDone(folderPath: String) {
        let lineIndex = currentLineIndex
        guard let result = complete() else { return }

        let fileURL = URL(fileURLWithPath: folderPath)
            .appendingPathComponent(result.sourceFile + ".md")
        if let idx = lineIndex, MarkdownParser.toggleTodoIfMatches(text: result.todoText, at: idx, in: fileURL) {
            // Done — single file read+write
        } else {
            MarkdownParser.markTodoDone(text: result.todoText, in: fileURL)
        }
    }

    // MARK: - Private helpers

    private func stopSession() {
        flushRunningSegment()
        if let id = sessionId { db.endSession(id: id, completed: false, finalElapsed: elapsed) }
        timer?.invalidate()
        timer = nil
    }

    /// If the timer is running, record the current segment to time_entries and reset startedAt.
    private func flushRunningSegment() {
        guard isRunning, let start = startedAt else { return }
        let now = Date()
        guard now.timeIntervalSince(start) >= 1 else { return }
        db.recordTimeEntry(todoText: currentTodoText, sourceFile: currentSourceFile, startedAt: start, endedAt: now)
    }

    private func cleanup() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        sessionId = nil
        startedAt = nil
        elapsed = 0
        pausedElapsed = 0
        currentTodoText = ""
        currentSourceFile = ""
        currentLineIndex = nil
        screen = .todos
    }

    private func startTicking() {
        timer?.invalidate()
        let base = pausedElapsed
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.startedAt else { return }
                self.elapsed = base + Date().timeIntervalSince(start)
            }
        }
    }

    // MARK: - Queries

    func totalTime(forTodo text: String, sourceFile: String) -> TimeInterval {
        db.totalTime(forTodo: text, sourceFile: sourceFile)
    }

    /// Batch query: get total time for all todos at once (avoids N+1)
    func allTotalTimes() -> [String: TimeInterval] {
        db.allTotalTimes()
    }

    /// Today's time entries as a timeline, most recent first
    func todayTimeline() -> [(todoText: String, sourceFile: String, startedAt: Date, endedAt: Date)] {
        db.todayTimeline()
    }

    nonisolated static func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
}
