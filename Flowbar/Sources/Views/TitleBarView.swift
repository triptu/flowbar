import SwiftUI

/// Active task label displayed centered in the native title bar.
/// Hosted as an NSHostingView added to the title bar view hierarchy by FloatingPanel.
struct TitleBarLabel: View {
    @Environment(TimerService.self) var timerService

    var body: some View {
        Group {
            if timerService.hasActiveSession {
                HStack(spacing: 6) {
                    Text(TimerService.formatTime(timerService.elapsed))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Text(truncated(timerService.currentTodoText, limit: 25))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            } else {
                Text("No active task")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.system(size: 13))
    }

    private func truncated(_ text: String, limit: Int) -> String {
        text.count > limit ? String(text.prefix(limit)) + "…" : text
    }
}
