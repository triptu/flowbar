import Foundation
import Combine
import SwiftUI

/// Manages the stopwatch timer for tracking time spent on todos.
///
/// Supports start, pause, resume, and complete. Persists sessions to SQLite via DatabaseService.
/// Does NOT modify markdown files — the caller is responsible for marking todos done.
/// Views observe @Published properties to update the UI; hasActiveSession and isTracking()
/// provide convenient checks without duplicating the isRunning/isPaused logic everywhere.
@MainActor
final class TimerService: ObservableObject {
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentTodoText = ""
    @Published var currentSourceFile = ""
    @Published var elapsed: TimeInterval = 0

    /// True when a timer session exists (running or paused)
    var hasActiveSession: Bool { isRunning || isPaused }

    private var sessionId: Int64?
    private var startedAt: Date?
    private var pausedElapsed: TimeInterval = 0
    private var timer: Timer?
    private let db = DatabaseService.shared

    init() {
        restoreActiveSession()
    }

    private func restoreActiveSession() {
        if let session = db.activeSession() {
            sessionId = session.id
            currentTodoText = session.todoText
            currentSourceFile = session.sourceFile
            startedAt = session.startedAt
            isRunning = true
            startTicking()
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
        guard isRunning else { return }
        timer?.invalidate()
        timer = nil
        pausedElapsed = elapsed
        isRunning = false
        isPaused = true
    }

    func resume() {
        guard isPaused else { return }
        startedAt = Date()
        isRunning = true
        isPaused = false
        startTicking()
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

    static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
