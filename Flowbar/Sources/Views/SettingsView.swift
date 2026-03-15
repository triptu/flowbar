import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.system(size: appState.typography.titleSize, weight: .bold))

                settingsSection("Obsidian Folder Path") {
                    HStack {
                        TextField("/path/to/obsidian/vault/folder", text: $appState.folderPath)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: appState.folderPath) { _, _ in
                                appState.loadFiles()
                            }
                        Button("Browse...") { browseFolder() }
                            .buttonStyle(.bordered)
                            .tint(FlowbarColors.accent)
                    }
                }

                settingsSection("Appearance") {
                    settingsPickerRow("Theme", selection: $appState.theme, options: AppTheme.allCases) { $0.rawValue.capitalized }
                    settingsPickerRow("Text Size", selection: $appState.typography, options: TypographySize.allCases) { $0.rawValue.capitalized }
                }

                settingsSection("Keyboard Shortcuts") {
                    VStack(alignment: .leading, spacing: 6) {
                        shortcutRow("Toggle Flowbar", "Double-tap Fn")
                        shortcutRow("Toggle Sidebar", "⌘B")
                        shortcutRow("Previous File", "⌃-")
                        shortcutRow("Next File", "⌃⇧-")
                        shortcutRow("Open Settings", "⌘,")
                        shortcutRow("Open Timer", "⌘⇧T")
                        shortcutRow("Pause / Resume Timer", "⌘⇧Space")
                    }
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
        }
    }

    private func settingsPickerRow<T: Hashable>(
        _ label: String,
        selection: Binding<T>,
        options: [T],
        display: @escaping (T) -> String
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(display(option)).tag(option)
                }
            }
            .labelsHidden()
            .frame(width: 120)
        }
    }

    private func shortcutRow(_ action: String, _ keys: String) -> some View {
        HStack {
            Text(action)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(keys)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.06))
                )
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
