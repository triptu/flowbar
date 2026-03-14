import SwiftUI

struct TimerHomeView: View {
    @EnvironmentObject var timerService: TimerService

    var body: some View {
        VStack(spacing: 0) {
            if timerService.isRunning {
                runningView
            } else {
                idleView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var runningView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(timerService.currentTodoText)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(TimerService.formatTime(timerService.elapsed))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button(action: { timerService.stop() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                        Text("STOP")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)

                Button(action: { timerService.complete() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                        Text("COMPLETE")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FlowbarColors.accent.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var idleView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No timer running")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Text("Start a timer from the todos list")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}
