import SwiftUI

/// Active task label displayed centered in the native title bar.
/// Hosted as an NSHostingView added to the title bar view hierarchy by FloatingPanel.
struct TitleBarLabel: View {
    @Environment(TimerService.self) var timerService
    @Environment(AppState.self) var appState

    private var isTimerPanel: Bool {
        if case .timer = appState.sidebar.activePanel { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if timerService.hasActiveSession {
                    HStack(spacing: 6) {
                        Text(TimerService.formatTime(timerService.elapsed))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(timerService.currentTodoText.truncated(to: 25))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                } else {
                    Text("No active task")
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.system(size: 13))
            .contentShape(Rectangle())
            .onTapGesture { appState.showTimer() }
            .accessibilityIdentifier("titlebar-task-label")
            .frame(maxWidth: .infinity)

            if isTimerPanel {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        timerService.toggleScreen()
                    }
                }) {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("titlebar-toggle-timeline")
                .accessibilityLabel("Toggle timeline")
                .padding(.trailing, 16)
            }
        }
        .padding(.leading, appState.sidebar.sidebarVisible ? CGFloat(appState.sidebar.sidebarWidth) + 5 : 0)
    }

}

extension String {
    func truncated(to limit: Int) -> String {
        count > limit ? String(prefix(limit)) + "…" : self
    }
}
