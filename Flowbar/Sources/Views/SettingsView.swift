import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.system(size: appState.typography.titleSize, weight: .bold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Obsidian Folder Path")
                        .font(.system(size: 14, weight: .medium))
                    HStack {
                        TextField("/path/to/obsidian/vault/folder", text: $appState.folderPath)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: appState.folderPath) {
                                appState.loadFiles()
                            }
                        Button("Browse...") { browseFolder() }
                            .buttonStyle(.bordered)
                    }
                }

                Divider().opacity(0.3)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(.system(size: 14, weight: .medium))
                    Picker("", selection: $appState.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }

                Divider().opacity(0.3)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Typography")
                        .font(.system(size: 14, weight: .medium))
                    Picker("", selection: $appState.typography) {
                        ForEach(TypographySize.allCases, id: \.self) { size in
                            Text(size.rawValue.capitalized).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }

                Divider().opacity(0.3)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Global Keyboard Shortcut")
                        .font(.system(size: 14, weight: .medium))
                    Button("Record Shortcut...") {}
                        .buttonStyle(.bordered)
                    Text("Double-tap Fn key to toggle Flowbar (default)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
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
            appState.loadFiles()
        }
    }
}
