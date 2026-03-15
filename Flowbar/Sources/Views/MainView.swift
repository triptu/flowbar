import SwiftUI

/// Root view that combines the sidebar and content area.
///
/// Reads activePanel from AppState to decide what to show: a note editor,
/// settings, the timer, or an empty state. The sidebar is togglable with Cmd+B.
struct MainView: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService

    var body: some View {
        @Bindable var appState = appState
        HStack(spacing: 0) {
            if appState.sidebarVisible {
                SidebarView()
                    .frame(width: CGFloat(appState.sidebarWidth))
                    .transition(.move(edge: .leading).combined(with: .opacity))

                SidebarDivider(width: $appState.sidebarWidth)
            }

            Group {
                switch appState.activePanel {
                case .settings:
                    SettingsView()
                case .timer:
                    TimerContainerView()
                case .file:
                    NoteContentView()
                case .empty:
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: .top)
        }
        .background(.regularMaterial)
        .preferredColorScheme(appState.preferredColorScheme)
        .background(keyboardShortcuts)
    }

    @ViewBuilder
    private var keyboardShortcuts: some View {
        Group {
            // Toggle sidebar
            Button("") { appState.toggleSidebar() }
                .keyboardShortcut("b", modifiers: .command)

            // Navigate to previous file (Go Back)
            Button("") { appState.selectPreviousFile() }
                .keyboardShortcut("-", modifiers: .control)

            // Navigate to next file (Go Forward)
            Button("") { appState.selectNextFile() }
                .keyboardShortcut("-", modifiers: [.control, .shift])

            // Open settings
            Button("") { appState.showSettings() }
                .keyboardShortcut(",", modifiers: .command)

            // Open timer
            Button("") { appState.showTimer() }
                .keyboardShortcut("t", modifiers: [.command, .shift])

            // Timer start/stop (pause/resume)
            Button("") { toggleTimerPlayback() }
                .keyboardShortcut(" ", modifiers: [.command, .shift])
        }
        .hidden()
    }

    private func toggleTimerPlayback() {
        if timerService.isRunning {
            timerService.pause()
        } else if timerService.isPaused {
            timerService.resume()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Select a folder in Settings")
                .foregroundStyle(.secondary)
        }
    }
}

struct SidebarDivider: View {
    @Binding var width: Double
    @State private var startWidth: Double = 0

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 5)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if startWidth == 0 { startWidth = width }
                        let newWidth = startWidth + value.translation.width
                        width = max(140, min(350, newWidth))
                    }
                    .onEnded { _ in
                        startWidth = 0
                    }
            )
    }
}
