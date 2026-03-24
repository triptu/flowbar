import SwiftUI

/// Daily note content view with edit/preview toggle (same pattern as NoteContentView).
struct DailyNoteContentView: View {
    @Environment(AppState.self) var appState
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.2)

            if !appState.dailyNoteExists {
                createNotePrompt
            } else if isEditing {
                LiveMarkdownEditorView(
                    text: Binding(
                        get: { appState.dailyNoteDisplayContent },
                        set: { saveSection($0) }
                    ),
                    baseSize: appState.settings.typography.bodySize,
                    onTextChange: {}
                )
            } else {
                MarkdownPreviewView(
                    content: appState.dailyNoteDisplayContent,
                    bodySize: appState.settings.typography.bodySize,
                    accentColor: appState.settings.accent,
                    onToggleTodo: { toggleTodo(at: $0) },
                    onDoubleClick: { isEditing = true }
                )
            }
        }
        .onChange(of: appState.dailyNoteSelectedHeading) { isEditing = false }
    }

    private var createNotePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No note for today")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Button(action: { appState.createDailyNote() }) {
                Text("Create Daily Note")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(appState.settings.accent.opacity(0.8))
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("create-daily-note")

            if appState.settings.dailyNoteTemplatePath.isEmpty {
                Text("Tip: add a template path in Settings")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.settings.dailyNoteFilename())
                    .font(.system(size: appState.settings.typography.titleSize, weight: .bold))
                if let heading = appState.dailyNoteSelectedHeading {
                    Text(heading)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()

            Button(action: { isEditing.toggle() }) {
                Image(systemName: isEditing ? "eye" : "pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(isEditing ? "Preview (⌘E)" : "Edit (⌘E)")
            .accessibilityIdentifier("daily-note-edit-preview")
            .keyboardShortcut("e", modifiers: .command)

            if let url = appState.dailyNoteURL {
                Button(action: { openInObsidian(url) }) {
                    ObsidianIcon().frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .help("Open in Obsidian")
                .accessibilityIdentifier("daily-note-open-obsidian")
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .padding(.top, FloatingPanel.contentTopPadding)
        .padding(.bottom, 10)
    }

    private func toggleTodo(at lineIndex: Int) {
        guard let url = appState.dailyNoteURL else { return }
        var lines = appState.dailyNoteContent.components(separatedBy: "\n")
        if appState.dailyNoteSelectedHeading != nil {
            let displayLines = appState.dailyNoteDisplayContent.components(separatedBy: "\n")
            guard lineIndex < displayLines.count else { return }
            let targetLine = displayLines[lineIndex]
            guard let fullIndex = lines.firstIndex(where: { $0 == targetLine }),
                  let toggled = MarkdownParser.toggleTodoLine(lines[fullIndex]) else { return }
            lines[fullIndex] = toggled
        } else {
            guard lineIndex < lines.count,
                  let toggled = MarkdownParser.toggleTodoLine(lines[lineIndex]) else { return }
            lines[lineIndex] = toggled
        }
        appState.dailyNoteContent = lines.joined(separator: "\n")
        try? appState.dailyNoteContent.write(to: url, atomically: true, encoding: .utf8)
    }

    private func saveSection(_ newContent: String) {
        guard let url = appState.dailyNoteURL else { return }
        if let heading = appState.dailyNoteSelectedHeading {
            let old = MarkdownParser.sectionContent(for: heading, in: appState.dailyNoteContent)
            appState.dailyNoteContent = appState.dailyNoteContent.replacingOccurrences(of: old, with: newContent)
        } else {
            appState.dailyNoteContent = newContent
        }
        appState.dailyNoteHeadings = MarkdownParser.extractHeadings(from: appState.dailyNoteContent)
        try? appState.dailyNoteContent.write(to: url, atomically: true, encoding: .utf8)
    }

    private func openInObsidian(_ fileURL: URL) {
        let vaultPath = URL(fileURLWithPath: appState.settings.folderPath).deletingLastPathComponent()
        let vaultName = vaultPath.lastPathComponent
        let folderName = URL(fileURLWithPath: appState.settings.folderPath).lastPathComponent
        let fileName = fileURL.lastPathComponent
        let encoded = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
        if let url = URL(string: "obsidian://open?vault=\(vaultName)&file=\(folderName)/\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}
