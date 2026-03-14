import SwiftUI

struct TimerContainerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var timerService: TimerService
    @State private var showingTodos: Bool? = nil // nil = auto

    private var effectiveShowingTodos: Bool {
        showingTodos ?? !timerService.isRunning
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: search (when todos) + toggle
            timerToolbar

            // Content
            if effectiveShowingTodos {
                TimerTodosView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                TimerHomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: effectiveShowingTodos)
    }

    private var timerToolbar: some View {
        HStack(spacing: 8) {
            if effectiveShowingTodos {
                TimerSearchBar()
            }
            Spacer()
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showingTodos = !effectiveShowingTodos
                }
            }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14))
                    .padding(7)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(effectiveShowingTodos ? FlowbarColors.timerActive : Color.secondary.opacity(0.15))
                    )
                    .foregroundStyle(effectiveShowingTodos ? .white : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

struct TimerSearchBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        EmptyView() // Search is now inside TimerTodosView's toolbar row
    }
}
