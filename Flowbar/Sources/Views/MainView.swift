import SwiftUI

/// Root view that combines the title bar, sidebar, and content area.
///
/// Layout: VStack with title bar on top (rendered in the native title bar region)
/// and sidebar+content below. The whole view ignores the top safe area so the
/// title bar content sits behind the transparent native title bar, alongside
/// the traffic lights. A single .regularMaterial background covers everything.
struct MainView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 0) {
            TitleBarView()

            Divider()

            HStack(spacing: 0) {
                if appState.sidebar.sidebarVisible {
                    SidebarView()
                        .frame(width: CGFloat(appState.sidebar.sidebarWidth))
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    SidebarDivider()
                }

                Group {
                    switch appState.sidebar.activePanel {
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
                .accessibilityIdentifier("content-area")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .background(.regularMaterial)
        .preferredColorScheme(appState.settings.preferredColorScheme)
        .background(keyboardShortcuts)
    }

    @ViewBuilder
    private var keyboardShortcuts: some View {
        Group {
            // Toggle sidebar
            Button("") { appState.toggleSidebar() }
                .keyboardShortcut("b", modifiers: .command)

            // Navigate to previous file
            Button("") { appState.selectPreviousFile() }
                .keyboardShortcut(.leftArrow, modifiers: [.option, .command])

            // Navigate to next file
            Button("") { appState.selectNextFile() }
                .keyboardShortcut(.rightArrow, modifiers: [.option, .command])

            // Open settings
            Button("") { appState.showSettings() }
                .keyboardShortcut(",", modifiers: .command)

            // Open timer
            Button("") { appState.showTimer() }
                .keyboardShortcut("t", modifiers: [.option, .command])
        }
        .hidden()
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

/// Draggable divider between sidebar and content.
/// Uses local @GestureState to avoid jitter from binding writes during drag.
/// Snaps the sidebar closed when dragged below the collapse threshold.
struct SidebarDivider: View {
    @Environment(AppState.self) var appState

    private let minWidth: Double = 140
    private let maxWidth: Double = 350
    /// Drag below this width triggers a full collapse
    private let collapseThreshold: Double = 100

    @GestureState private var dragOffset: Double = 0
    @State private var dragStartWidth: Double?

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 5)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onChanged { _ in
                        if dragStartWidth == nil {
                            dragStartWidth = appState.sidebar.sidebarWidth
                        }
                    }
                    .onEnded { value in
                        let start = dragStartWidth ?? appState.sidebar.sidebarWidth
                        let raw = start + value.translation.width
                        dragStartWidth = nil
                        if raw < collapseThreshold {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.sidebar.sidebarVisible = false
                            }
                        } else {
                            appState.sidebar.sidebarWidth = max(minWidth, min(maxWidth, raw))
                        }
                    }
            )
            .onChange(of: dragOffset) {
                guard let start = dragStartWidth else { return }
                let raw = start + dragOffset
                if raw >= collapseThreshold {
                    appState.sidebar.sidebarWidth = max(minWidth, min(maxWidth, raw))
                }
            }
    }
}
