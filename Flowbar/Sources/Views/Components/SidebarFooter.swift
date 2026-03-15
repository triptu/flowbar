import SwiftUI

struct SidebarFooter: View {
    @Environment(AppState.self) var appState

    private var isSettings: Bool { appState.activePanel == .settings }
    private var isTimer: Bool { appState.activePanel == .timer }

    var body: some View {
        HStack(spacing: 4) {
            footerButton(icon: "gearshape", label: "Settings", isActive: isSettings) {
                isSettings ? appState.returnToFiles() : appState.showSettings()
            }
            footerButton(icon: "clock", label: "Timer", isActive: isTimer) {
                isTimer ? appState.returnToFiles() : appState.showTimer()
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
