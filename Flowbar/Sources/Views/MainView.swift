import SwiftUI

/// Root view that combines the sidebar and content area.
///
/// Reads activePanel from AppState to decide what to show: a note editor,
/// settings, the timer, or an empty state. The sidebar is togglable with Cmd+B.
/// Used identically in both popover and floating panel modes.
struct MainView: View {
    @Environment(AppState.self) var appState
    @Environment(PopoverManager.self) var popoverManager

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
        }
        .background(.regularMaterial)
        .preferredColorScheme(appState.preferredColorScheme)
        .onAppear {
            if case .empty = appState.activePanel, let first = appState.noteFiles.first {
                appState.selectFile(first)
            }
        }
        .background(
            Button("") { appState.toggleSidebar() }
                .keyboardShortcut("b", modifiers: .command)
                .hidden()
        )
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
    @GestureState private var dragOffset: CGFloat = 0
    @State private var startWidth: Double = 0

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 5)
            .overlay(
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 1)
            )
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
