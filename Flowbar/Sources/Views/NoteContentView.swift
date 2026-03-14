import SwiftUI

struct NoteContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var popoverManager: PopoverManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            noteHeader
            Divider().opacity(0.3)

            TextEditor(text: $appState.editorContent)
                .font(.system(size: appState.typography.bodySize))
                .scrollContentBackground(.hidden)
                .padding(16)
                .onChange(of: appState.editorContent) {
                    appState.saveFileContent()
                }
        }
    }

    private var noteHeader: some View {
        HStack(spacing: 12) {
            Text(appState.selectedFile?.name ?? "")
                .font(.system(size: appState.typography.titleSize, weight: .bold))

            Spacer()

            Button(action: { appState.openInObsidian() }) {
                ObsidianIcon()
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .help("Open in Obsidian")

            Button(action: {
                if popoverManager.isFloating {
                    popoverManager.dockPanel()
                } else {
                    popoverManager.floatPanel()
                }
            }) {
                Image(systemName: popoverManager.isFloating ? "pip.exit" : "pip.enter")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help(popoverManager.isFloating ? "Dock to menu bar" : "Pop out as overlay")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct ObsidianIcon: View {
    var body: some View {
        // Simplified Obsidian crystal shape
        Image(systemName: "diamond.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "A855F7"), Color(hex: "7C3AED")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
