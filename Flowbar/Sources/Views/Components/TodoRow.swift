import SwiftUI

struct TodoRow: View {
    let todo: TodoItem
    let timerService: TimerService
    let onToggle: () -> Void
    let onStart: () -> Void
    let onNavigate: () -> Void

    private var isActive: Bool {
        timerService.isRunning &&
        timerService.currentTodoText == todo.text &&
        timerService.currentSourceFile == todo.sourceFile.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main row
            HStack(spacing: 10) {
                // State circle
                Button(action: onToggle) {
                    Circle()
                        .fill(todo.isDone ? FlowbarColors.accent : Color.clear)
                        .overlay(
                            Circle().strokeBorder(todo.isDone ? FlowbarColors.accent : Color.secondary.opacity(0.5), lineWidth: 1.5)
                        )
                        .overlay(
                            todo.isDone ? Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)).foregroundStyle(.white) : nil
                        )
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)

                // Title
                Text(todo.text)
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                    .strikethrough(todo.isDone)
                    .opacity(todo.isDone ? 0.5 : 1)
                    .lineLimit(2)

                Spacer()

                // Play/Pause
                if !todo.isDone {
                    Button(action: onStart) {
                        Image(systemName: isActive ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(isActive ? FlowbarColors.timerActive : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Footer: source file + time
            HStack {
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
                        .foregroundStyle(FlowbarColors.timerActive)
                } else if todo.totalSeconds > 0 {
                    Text(TimerService.formatTime(todo.totalSeconds))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? FlowbarColors.timerActive.opacity(0.1) : Color.clear)
        )
    }
}
