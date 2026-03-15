import Foundation
import Observation

/// Manages the stopwatch timer for tracking time spent on todos.
///
/// Supports start, pause, resume, and complete. Persists sessions to SQLite via DatabaseService.
/// Does NOT modify markdown files — the caller is responsible for marking todos done.
/// Views observe properties to update the UI; hasActiveSession and isTracking()
/// provide convenient checks without duplicating the isRunning/isPaused logic everywhere.
@Observable
@MainActor
final class TimerService {
    var isRunning = false
    var isPaused = false
    var currentTodoText = ""
    var currentSourceFile = ""
    var elapsed: TimeInterval = 0

    /// True when a timer session exists (running or paused)
    var hasActiveSession: Bool { isRunning || isPaused }

    @ObservationIgnored private var sessionId: Int64?
    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var pausedElapsed: TimeInterval = 0
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private let db = DatabaseService.shared

    init() {
        restoreActiveSession()
    }

    private func restoreActiveSession() {
        if let session = db.activeSession() {
            sessionId = session.id
            currentTodoText = session.todoText
            currentSourceFile = session.sourceFile
            if let paused = session.pausedElapsed {
                // Was paused — restore as paused with saved elapsed
                pausedElapsed = paused
                elapsed = paused
                isPaused = true
            } else {
                // Was running — resume ticking with accumulated base
                pausedElapsed = session.accumulated
                startedAt = session.startedAt
                isRunning = true
                startTicking()
            }
        }
    }

    func start(todoText: String, sourceFile: String) {
        if hasActiveSession { stopSession() }
        sessionId = db.startSession(todoText: todoText, sourceFile: sourceFile)
        currentTodoText = todoText
        currentSourceFile = sourceFile
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
    func stop() {
        guard hasActiveSession, let id = sessionId else { return }
        db.endSession(id: id, completed: false)
        cleanup()
    }

    /// Ends the session and marks it as completed in the database.
    /// Returns the (todoText, sourceFile) so the caller can mark the todo done in the markdown.
    @discardableResult
    func complete() -> (todoText: String, sourceFile: String)? {
        guard hasActiveSession, let id = sessionId else { return nil }
        let result = (todoText: currentTodoText, sourceFile: currentSourceFile)
        db.endSession(id: id, completed: true)
        cleanup()
        return result
    }

    /// Check if a specific todo is being tracked (running or paused)
    func isTracking(todoText: String, sourceFile: String) -> Bool {
        hasActiveSession && currentTodoText == todoText && currentSourceFile == sourceFile
    }

    private func stopSession() {
        if let id = sessionId { db.endSession(id: id, completed: false) }
        timer?.invalidate()
        timer = nil
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

    /// Today's completed sessions grouped by todo, most recent first
    func todaySessions() -> [(todoText: String, totalDuration: TimeInterval)] {
        db.todaySessions()
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
