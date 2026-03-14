import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.system(size: appState.typography.titleSize, weight: .bold))

                settingsSection("Obsidian Folder Path") {
                    HStack {
                        TextField("/path/to/obsidian/vault/folder", text: $appState.folderPath)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: appState.folderPath) { appState.loadFiles() }
                        Button("Browse...") { browseFolder() }
                            .buttonStyle(.bordered)
                            .tint(FlowbarColors.accent)
                    }
                }

                settingsSection("Appearance") {
                    FlowbarSegmentedControl(
                        selection: $appState.theme,
                        options: AppTheme.allCases,
                        label: { $0.rawValue.capitalized }
                    )
                    .frame(maxWidth: 300)
                }

                settingsSection("Typography") {
                    FlowbarSegmentedControl(
                        selection: $appState.typography,
                        options: TypographySize.allCases,
                        label: { $0.rawValue.capitalized }
                    )
                    .frame(maxWidth: 300)
                }

                settingsSection("Sidebar") {
                    Text("Toggle with **\u{2318}B**")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                settingsSection("Global Keyboard Shortcut") {
                    Text("Double-tap **Fn** key to toggle Flowbar")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
    }

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            content()
            Divider().opacity(0.2)
        }
    }

    private func browseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select your Obsidian notes folder"
        if panel.runModal() == .OK, let url = panel.url {
            appState.folderPath = url.path
        }
    }
}

// Custom segmented control using accent color
struct FlowbarSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                Button(action: { selection = option }) {
                    Text(label(option))
                        .font(.system(size: 13, weight: selection == option ? .semibold : .regular))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == option ? FlowbarColors.accent : Color.clear)
                        )
                        .foregroundStyle(selection == option ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.06))
        )
    }
}
