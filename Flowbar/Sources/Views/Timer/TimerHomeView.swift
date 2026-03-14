import SwiftUI

struct TimerHomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var timerService: TimerService

    var body: some View {
        Group {
            if timerService.isRunning || timerService.isPaused {
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
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(TimerService.formatTime(timerService.elapsed))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button(action: {
                    if timerService.isRunning {
                        timerService.pause()
                    } else {
                        timerService.resume()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 11))
                        Text(timerService.isRunning ? "PAUSE" : "RESUME")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)

                Button(action: { timerService.complete(folderPath: appState.folderPath) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11))
                        Text("COMPLETE")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
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
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No timer running")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            Text("Start from the todos list")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}
