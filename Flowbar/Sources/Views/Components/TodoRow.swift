import SwiftUI

struct TodoRow: View {
    let todo: TodoItem
    let totalSeconds: TimeInterval
    let timerService: TimerService
    let onToggle: () -> Void
    let onStart: () -> Void
    let onNavigate: () -> Void

    private var isActive: Bool {
        timerService.isTracking(todoText: todo.text, sourceFile: todo.sourceFile.id)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // State circle
            Button(action: onToggle) {
                Circle()
                    .fill(todo.isDone ? FlowbarColors.accent : Color.clear)
                    .overlay(
                        Circle().strokeBorder(
                            todo.isDone ? FlowbarColors.accent : Color.primary.opacity(0.2),
                            lineWidth: 1.5
                        )
                    )
                    .overlay(
                        todo.isDone
                            ? Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                            : nil
                    )
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            // Title + source stacked
            VStack(alignment: .leading, spacing: 3) {
                Text(todo.text)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .strikethrough(todo.isDone)
                    .opacity(todo.isDone ? 0.4 : 1)
                    .lineLimit(2)

                HStack(spacing: 0) {
                    Button(action: onNavigate) {
                        Text(todo.sourceFile.name)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if isActive {
                        Text(TimerService.formatTime(timerService.elapsed))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(FlowbarColors.accent)
                    } else if totalSeconds > 0 {
                        Text(TimerService.formatTime(totalSeconds))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 0)

            // Play/Pause
            if !todo.isDone {
                Button(action: onStart) {
                    Image(systemName: isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(isActive ? FlowbarColors.accent : Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? FlowbarColors.accent.opacity(0.08) : Color.clear)
        )
    }
}
