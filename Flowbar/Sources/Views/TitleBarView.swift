import SwiftUI

/// Active task label displayed centered in the native title bar.
/// Hosted as an NSHostingView added to the title bar view hierarchy by FloatingPanel.
struct TitleBarLabel: View {
    @Environment(TimerService.self) var timerService

    var body: some View {
        Group {
            if timerService.hasActiveSession {
                HStack(spacing: 4) {
                    Text("Active — \(timerService.currentTodoText)")
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(TimerService.formatTime(timerService.elapsed))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No active task")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.system(size: 11))
    }
}
