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
            .contentShape(Rectangle())
            .onTapGesture { appState.showTimer() }
            .frame(maxWidth: .infinity)

            if isTimerPanel {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        timerService.toggleScreen()
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11))
                        .foregroundStyle(timerService.screen == .todos ? .primary : .secondary)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(timerService.screen == .todos ? appState.settings.accent : Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
        }
        .padding(.leading, appState.sidebar.sidebarVisible ? CGFloat(appState.sidebar.sidebarWidth) + 5 : 0)
    }

    private func truncated(_ text: String, limit: Int) -> String {
        text.count > limit ? String(text.prefix(limit)) + "…" : text
    }
}
