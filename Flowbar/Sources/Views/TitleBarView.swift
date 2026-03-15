import SwiftUI

/// Content rendered in the native title bar region (behind the transparent title bar).
/// Shows active task info centered. The sidebar toggle button is a native NSButton
/// added directly to the title bar view hierarchy by FloatingPanel.
struct TitleBarView: View {
    @Environment(TimerService.self) var timerService

    var body: some View {
        ZStack {
            activeTaskLabel
        }
        .frame(height: FloatingPanel.titleBarHeight)
        .frame(maxWidth: .infinity)
        .background(FlowbarColors.titleBarBg)
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
