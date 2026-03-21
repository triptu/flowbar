import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState

    @State private var folderPathInput = ""
    @State private var folderPathDebounce: DispatchWorkItem?

    var body: some View {
        @Bindable var settings = appState.settings
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.system(size: appState.settings.typography.titleSize, weight: .bold))

                settingsSection("Markdown Folder Path") {
                    HStack {
                        TextField("/path/to/markdown/folder", text: $folderPathInput)
                            .textFieldStyle(.roundedBorder)
                            .onAppear { folderPathInput = appState.settings.folderPath }
                            .onChange(of: folderPathInput) { _, newValue in
                                folderPathDebounce?.cancel()
                                let task = DispatchWorkItem { appState.setFolderPath(newValue) }
                                folderPathDebounce = task
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
                            }
                        Button("Browse...") { browseFolder() }
                            .buttonStyle(.bordered)
                            .tint(appState.settings.accent)
                    }
                }

                settingsSection("Appearance") {
                    settingsPickerRow("Theme", selection: $settings.theme, options: AppTheme.allCases) { $0.rawValue.capitalized }
                    settingsPickerRow("Text Size", selection: $settings.typography, options: TypographySize.allCases) { $0.rawValue.capitalized }
                    accentColorRow
                }

                settingsSection("General") {
                    HStack {
                        Text("Launch at Login")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Toggle("", isOn: $settings.launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .tint(appState.settings.accent)
                    }
                }

                settingsSection("Keyboard Shortcuts") {
                    VStack(alignment: .leading, spacing: 6) {
                        globalShortcutPicker
                        shortcutRow("Toggle Sidebar", "⌘ B")
                        shortcutRow("Previous File", "⌥ ⌘ ←")
                        shortcutRow("Next File", "⌥ ⌘ →")
                        shortcutRow("Open Settings", "⌘ ,")
                        shortcutRow("Open Timer", "⌥ ⌘ T")
                        shortcutRow("Edit / Preview Mode", "⌘ E")
                        shortcutRow("Open Todo List", "⌥ ⌘ L")
                        shortcutRow("Toggle Light/Dark", "⌥ ⌘ D")
                        shortcutRow("Pause / Resume Timer", "Space")
                    }
                }
            }
            .padding(.top, FloatingPanel.contentTopPadding)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .clipped()
    }

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
            .fixedSize()
        }
    }

    private var accentColorRow: some View {
        HStack {
            Text("Accent Color")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 6) {
                ForEach(AccentColor.allCases, id: \.self) { color in
                    Circle()
                        .fill(color.preview)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.primary.opacity(appState.settings.accentColor == color ? 0.6 : 0), lineWidth: 1.5)
                        )
                        .scaleEffect(appState.settings.accentColor == color ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: appState.settings.accentColor)
                        .onTapGesture { appState.settings.accentColor = color }
                        .help(color.displayName)
                }
            }
        }
    }

    /// Whether the current shortcut is one of the presets (for picker selection).
    private var selectedPresetIndex: Int? {
        GlobalShortcut.presets.firstIndex(where: { $0 == appState.settings.globalShortcut })
    }

    private var isCustomShortcut: Bool {
        if case .custom = appState.settings.globalShortcut { return true }
        return false
    }

    private var globalShortcutPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Toggle Flowbar")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    ForEach(Array(GlobalShortcut.presets.enumerated()), id: \.offset) { _, preset in
                        Button(preset.displayName) {
                            appState.settings.globalShortcut = preset
                        }
                    }
                    Divider()
                    Button("Custom…") {
                        // If not already custom, switch to custom with a default
                        if !isCustomShortcut {
                            appState.settings.globalShortcut = .custom(keyCode: 49, modifiers: .control)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isCustomShortcut ? "Custom" : appState.settings.globalShortcut.displayName)
                            .font(.system(size: 12))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.primary.opacity(0.06))
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            if isCustomShortcut {
                HStack {
                    Spacer()
                    ShortcutRecorderView(shortcut: Binding(
                        get: { appState.settings.globalShortcut },
                        set: { appState.settings.globalShortcut = $0 }
                    ))
                }
            }
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
        panel.message = "Select your markdown notes folder"
        if panel.runModal() == .OK, let url = panel.url {
            folderPathInput = url.path
            appState.setFolderPath(url.path)
        }
    }
}
