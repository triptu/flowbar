import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var popoverManager: PopoverManager

    var body: some View {
        HStack(spacing: 0) {
            if appState.sidebarVisible {
                SidebarView()
                    .frame(width: 200)
                    .transition(.move(edge: .leading).combined(with: .opacity))

                Divider()
                    .opacity(0.3)
            }

            // Right content area
            Group {
                if appState.showingSettings {
                    SettingsView()
                } else if appState.showingTimer {
                    TimerContainerView()
                } else if appState.selectedFile != nil {
                    NoteContentView()
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.ultraThinMaterial)
        .onAppear {
            if let first = appState.noteFiles.first, appState.selectedFile == nil {
                appState.selectFile(first)
            }
        }
        .background(
            // Hidden button for Cmd+B shortcut
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
