import SwiftUI

/// Active task label displayed centered in the native title bar.
/// Hosted as an NSHostingView added to the title bar view hierarchy by FloatingPanel.
struct TitleBarLabel: View {
    @Environment(TimerService.self) var timerService
    @Environment(AppState.self) var appState

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
        .frame(maxWidth: .infinity)
        .padding(.leading, appState.sidebar.sidebarVisible ? CGFloat(appState.sidebar.sidebarWidth) + 5 : 0)
    }

    private func truncated(_ text: String, limit: Int) -> String {
        text.count > limit ? String(text.prefix(limit)) + "…" : text
    }
}
