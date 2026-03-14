import SwiftUI

struct SidebarFooter: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            footerButton(icon: "gearshape", label: "Settings", isActive: appState.showingSettings) {
                if appState.showingSettings {
                    appState.showingSettings = false
                    if let file = appState.noteFiles.first {
                        appState.selectFile(file)
                    }
                } else {
                    appState.showingTimer = false
                    appState.showingSettings = true
                    appState.selectedFile = nil
                }
            }

            footerButton(icon: "clock", label: "Timer", isActive: appState.showingTimer) {
                if appState.showingTimer {
                    appState.showingTimer = false
                    if let file = appState.noteFiles.first {
                        appState.selectFile(file)
                    }
                } else {
                    appState.showingSettings = false
                    appState.showingTimer = true
                    appState.selectedFile = nil
                }
            }
        }
        .padding(6)
    }

    private func footerButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? FlowbarColors.accent.opacity(0.3) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? .primary : .secondary)
    }
}
