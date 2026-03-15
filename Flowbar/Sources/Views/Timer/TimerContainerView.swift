import SwiftUI

/// Container that switches between the timer home screen and the todos list.
///
/// When no timer is active, defaults to showing todos. When a timer is running,
/// shows TimerHomeView. The user can toggle between them with the list button.
/// Listens to timerService.isRunning changes to auto-switch when a timer completes.
struct TimerContainerView: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService
    @State private var showingTodos: Bool? = nil

    private var effectiveShowingTodos: Bool {
        if let override = showingTodos { return override }
        return !timerService.hasActiveSession
    }

    var body: some View {
        VStack(spacing: 0) {
            if effectiveShowingTodos {
                TimerTodosView(onToggleView: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingTodos = !effectiveShowingTodos
                    }
                }, isShowingTodos: effectiveShowingTodos)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Toolbar for timer home view
                HStack(spacing: 6) {
                    Spacer(minLength: 0)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingTodos = !effectiveShowingTodos
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 13))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(effectiveShowingTodos ? appState.accent : Color.primary.opacity(0.06))
                            )
                            .foregroundStyle(effectiveShowingTodos ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 6)

                TimerHomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: effectiveShowingTodos)
        .onChange(of: timerService.isRunning) { old, new in
            // When timer completes (was running, now stopped and not paused), show todos
            if old && !new && !timerService.isPaused {
                showingTodos = true
            }
        }
    }
}
