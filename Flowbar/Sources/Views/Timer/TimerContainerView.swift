import SwiftUI

/// Container that switches between the timer home screen and the todos list.
///
/// Screen routing is owned by TimerService.screen — this view just reads it.
struct TimerContainerView: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService

    var body: some View {
        VStack(spacing: 0) {
            if timerService.screen == .todos {
                TimerTodosView(onToggleView: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        timerService.toggleScreen()
                    }
                })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Toolbar for timer home view
                HStack(spacing: 6) {
                    Spacer(minLength: 0)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            timerService.toggleScreen()
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 13))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.06))
                            )
                            .foregroundStyle(.secondary)
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
        .animation(.easeInOut(duration: 0.2), value: timerService.screen)
    }
}
