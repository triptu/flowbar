import Foundation
import Combine
import SwiftUI

@MainActor
final class TimerService: ObservableObject {
    @Published var isRunning = false
    @Published var currentTodoText = ""
    @Published var currentSourceFile = ""
    @Published var elapsed: TimeInterval = 0

    private var sessionId: Int64?
    private var startedAt: Date?
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
        // Stop any running session first
        if isRunning {
            stop()
        }

        sessionId = db.startSession(todoText: todoText, sourceFile: sourceFile)
        currentTodoText = todoText
        currentSourceFile = sourceFile
        startedAt = Date()
        elapsed = 0
        isRunning = true
        startTicking()
    }

    func stop() {
        guard isRunning, let id = sessionId else { return }
        db.endSession(id: id, completed: false)
        cleanup()
    }

    func complete(folderPath: String) {
        guard isRunning, let id = sessionId else { return }
        // Mark the todo as done in the markdown file
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

    private func cleanup() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        sessionId = nil
        startedAt = nil
        elapsed = 0
        currentTodoText = ""
        currentSourceFile = ""
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(start)
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
