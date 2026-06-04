import SwiftUI

/// Timer screen: the home view (current session + timeline) plus an optional
/// todos list as a right-side panel. Toggled by the title bar `sidebar.right`
/// button, resizable via the divider, and shown by default.
struct TimerContainerView: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService

    var body: some View {
        HStack(spacing: 0) {
            TimerHomeView()
                .accessibilityIdentifier("timer-home-view")
                .frame(maxWidth: .infinity)

            if timerService.todosVisible {
                HStack(spacing: 0) {
                    TodosPanelDivider()
                    TimerTodosView()
                        .accessibilityIdentifier("timer-todos-view")
                        .frame(width: CGFloat(appState.sidebar.todosPanelWidth))
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: timerService.todosVisible)
    }
}

/// Draggable divider on the left edge of the todos side panel.
/// Mirrors `SidebarDivider` but inverts the drag delta — dragging left grows
/// the panel, dragging right shrinks it. Snaps the panel closed when dragged
/// below the collapse threshold.
struct TodosPanelDivider: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService

    private let minWidth: Double = 220
    private let maxWidth: Double = 450
    private let collapseThreshold: Double = 160

    @GestureState private var dragOffset: Double = 0
    @State private var dragStartWidth: Double?

    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(width: 1)
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 5)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering { NSCursor.resizeLeftRight.set() } else { NSCursor.arrow.set() }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .global)
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onChanged { _ in
                                if dragStartWidth == nil {
                                    dragStartWidth = appState.sidebar.todosPanelWidth
                                }
                            }
                            .onEnded { value in
                                let start = dragStartWidth ?? appState.sidebar.todosPanelWidth
                                let raw = start - value.translation.width
                                dragStartWidth = nil
                                if raw < collapseThreshold {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        timerService.todosVisible = false
                                    }
                                } else {
                                    appState.sidebar.todosPanelWidth = max(minWidth, min(maxWidth, raw))
                                }
                            }
                    )
            )
            .onChange(of: dragOffset) {
                guard let start = dragStartWidth else { return }
                let raw = start - dragOffset
                if raw >= collapseThreshold {
                    appState.sidebar.todosPanelWidth = max(minWidth, min(maxWidth, raw))
                }
            }
    }
}
