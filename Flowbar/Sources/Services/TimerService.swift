import Foundation
import Combine
import SwiftUI

@MainActor
final class TimerService: ObservableObject {
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentTodoText = ""
    @Published var currentSourceFile = ""
    @Published var elapsed: TimeInterval = 0

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
        if isRunning || isPaused {
            stopSession()
        }

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

    func stop() {
        guard isRunning || isPaused, let id = sessionId else { return }
        db.endSession(id: id, completed: false)
        cleanup()
    }

    func complete(folderPath: String) {
        guard (isRunning || isPaused), let id = sessionId else { return }
        let fileURL = URL(fileURLWithPath: folderPath).appendingPathComponent(currentSourceFile + ".md")
        if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
            let lines = content.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("- [ ] ") && String(trimmed.dropFirst(6)) == currentTodoText {
                    _ = MarkdownParser.toggleTodo(at: index, in: fileURL)
                    break
                }
            }
        }
        db.endSession(id: id, completed: true)
        cleanup()
    }

    private func stopSession() {
        if let id = sessionId {
            db.endSession(id: id, completed: false)
        }
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

    func totalTime(forTodo text: String, sourceFile: String) -> TimeInterval {
        db.totalTime(forTodo: text, sourceFile: sourceFile)
    }

    static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
