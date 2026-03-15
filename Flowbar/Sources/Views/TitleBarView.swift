import SwiftUI

/// Content rendered in the native title bar region (behind the transparent title bar).
/// Sits alongside traffic lights. Shows sidebar toggle and active task info.
struct TitleBarView: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService

    var body: some View {
        ZStack {
            activeTaskLabel

            HStack(spacing: 0) {
                Button(action: { appState.toggleSidebar() }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, FloatingPanel.trafficLightWidth + 10)
                Spacer()
            }
        }
        .frame(height: FloatingPanel.titleBarHeight)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var activeTaskLabel: some View {
        if timerService.hasActiveSession {
            HStack(spacing: 6) {
                Circle()
                    .fill(timerService.isRunning ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                Text(timerService.currentTodoText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(TimerService.formatTime(timerService.elapsed))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 11))
            .padding(.horizontal, 100)
        } else {
            Text("No active task")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }
}
