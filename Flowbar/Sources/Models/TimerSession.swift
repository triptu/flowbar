import Foundation

struct TimerSession: Identifiable {
    let id: Int64
    let todoText: String
    let sourceFile: String
    let startedAt: Date
    var endedAt: Date?
    var completed: Bool

    var duration: TimeInterval {
        let end = endedAt ?? Date()
        return end.timeIntervalSince(startedAt)
    }
}
