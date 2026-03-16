import SwiftUI

struct TimerHomeView: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService
    @State private var previousTotal: TimeInterval = 0
    @State private var todaySessions: [(todoText: String, sourceFile: String, totalDuration: TimeInterval)] = []

    var body: some View {
        VStack(spacing: 0) {
            if timerService.hasActiveSession {
                runningView
            } else {
                idleView
            }

            if !todaySessions.isEmpty {
                sessionsListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.space) {
            guard timerService.hasActiveSession else { return .ignored }
            timerService.togglePlayPause()
            return .handled
        }
        .onAppear {
            refreshPreviousTotal()
            refreshTodaySessions()
        }
        .onChange(of: timerService.currentTodoText) { _, _ in refreshPreviousTotal() }
        .onChange(of: timerService.hasActiveSession) { _, active in
            if !active {
                refreshTodaySessions()
                previousTotal = 0
            }
        }
    }

    private func refreshTodaySessions() {
        todaySessions = timerService.todaySessions().filter { $0.totalDuration >= 1 }
    }

    private func refreshPreviousTotal() {
        guard timerService.hasActiveSession else { previousTotal = 0; return }
        previousTotal = timerService.totalTime(forTodo: timerService.currentTodoText, sourceFile: timerService.currentSourceFile)
    }

    private var runningView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(timerService.currentTodoText)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(TimerService.formatTime(timerService.elapsed))
                .font(.system(size: appState.settings.typography.timerSize, weight: .light, design: .monospaced))
                .foregroundStyle(.secondary)

            if previousTotal > 0 {
                Text("+ \(TimerService.formatTime(previousTotal)) = \(TimerService.formatTime(previousTotal + timerService.elapsed))")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 12) {
                Button(action: { timerService.togglePlayPause() }) {
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

Button(action: {
                    timerService.completeAndMarkDone(folderPath: appState.settings.folderPath)
                }) {
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
                            .fill(appState.settings.accent.opacity(0.3))
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

    private var sessionsListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY'S SESSIONS")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            ForEach(todaySessions, id: \.todoText) { session in
                HStack(spacing: 8) {
                    Button(action: {
                        timerService.start(todoText: session.todoText, sourceFile: session.sourceFile)
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 20)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)

                    Text(session.todoText)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    Spacer()
                    Text(TimerService.formatTime(session.totalDuration))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
        }
        .padding(.bottom, 16)
    }
}
