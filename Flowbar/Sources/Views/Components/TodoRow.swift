import SwiftUI

struct TodoRow: View {
    @Environment(AppState.self) var appState
    let todo: TodoItem
    let totalSeconds: TimeInterval
    let timerService: TimerService
    let onToggle: () -> Void
    let onStart: () -> Void
    let onNavigate: () -> Void

    private var isTracked: Bool {
        timerService.isTracking(todoText: todo.text, sourceFile: todo.sourceFile.id)
    }

    private var isRunning: Bool {
        isTracked && timerService.isRunning
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: onToggle) {
                Circle()
                    .fill(todo.isDone ? appState.settings.accent : Color.clear)
                    .overlay(
                        Circle().strokeBorder(
                            todo.isDone ? appState.settings.accent : Color.primary.opacity(0.2),
                            lineWidth: 1.5
                        )
                    )
                    .overlay(
                        todo.isDone
                            ? Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.primary)
                            : nil
                    )
                    .frame(width: 18, height: 18)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("todo-toggle-\(todo.text)")
            .accessibilityLabel(todo.isDone ? "Mark incomplete" : "Mark complete")

            VStack(spacing: 3) {
                HStack(spacing: 0) {
                    Text(todo.text)
                        .font(.system(size: 13, weight: isTracked ? .semibold : .regular))
                        .strikethrough(todo.isDone)
                        .opacity(todo.isDone ? 0.4 : 1)
                        .lineLimit(2)

                    Spacer(minLength: 4)

                    Button(action: onStart) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(isTracked ? appState.settings.accent : Color.secondary.opacity(0.5))
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("todo-play-\(todo.text)")
                    .accessibilityLabel(isRunning ? "Pause timer" : "Start timer")
                }

                HStack(spacing: 0) {
                    Button(action: onNavigate) {
                        Text(todo.sourceFile.name)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("todo-navigate-\(todo.sourceFile.id)")

                    Spacer()

                    if isTracked {
                        Text(TimerService.formatTime(totalSeconds + timerService.elapsed))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(appState.settings.accent)
                    } else if totalSeconds > 0 {
                        Text(TimerService.formatTime(totalSeconds))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isTracked ? appState.settings.accent.opacity(0.08) : Color.clear)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todo-row-\(todo.text)")
    }
}
