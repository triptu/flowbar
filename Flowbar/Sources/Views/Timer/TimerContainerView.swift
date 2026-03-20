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
                TimerTodosView()
                    .accessibilityIdentifier("timer-todos-view")
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                TimerHomeView()
                    .accessibilityIdentifier("timer-home-view")
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: timerService.screen)
    }
}
