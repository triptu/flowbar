import SwiftUI

struct NoteContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            noteHeader
            Divider().opacity(0.2)

            if appState.editor.isEditing {
                MarkdownEditorView(
                    text: Binding(
                        get: { appState.editor.editorContent },
                        set: { appState.editor.editorContent = $0 }
                    ),
                    font: .systemFont(ofSize: appState.settings.typography.bodySize),
                    focusOnAppear: true,
                    onTextChange: { appState.saveFileContent() }
                )
            } else {
                MarkdownPreviewView(
                    content: appState.editor.editorContent,
                    bodySize: appState.settings.typography.bodySize,
                    accentColor: appState.settings.accent,
                    onToggleTodo: { lineIndex in
                        toggleTodoInContent(at: lineIndex)
                    },
                    onDoubleClick: { appState.editor.isEditing = true }
                )
            }
        }
    }

    private func toggleTodoInContent(at lineIndex: Int) {
        var lines = appState.editor.editorContent.components(separatedBy: "\n")
        guard lineIndex < lines.count,
              let toggled = MarkdownParser.toggleTodoLine(lines[lineIndex]) else { return }
        lines[lineIndex] = toggled
        appState.editor.editorContent = lines.joined(separator: "\n")
        appState.saveFileContent()
    }

    private var noteHeader: some View {
        HStack(spacing: 10) {
            Text(appState.sidebar.selectedFile?.name ?? "")
                .font(.system(size: appState.settings.typography.titleSize, weight: .bold))

            Spacer()

            // Edit/Preview toggle
            Button(action: { appState.editor.isEditing.toggle() }) {
                Image(systemName: appState.editor.isEditing ? "eye" : "pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(appState.editor.isEditing ? "Preview (\u{2318}E)" : "Edit (\u{2318}E)")

            Button(action: { appState.openInObsidian() }) {
                ObsidianIcon()
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .help("Open in Obsidian")
        }
        .padding(.leading, appState.sidebar.sidebarVisible ? 20 : FloatingPanel.trafficLightWidth)
        .padding(.trailing, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}

// Obsidian logo from SVG path
struct ObsidianIcon: View {
    var body: some View {
        ObsidianShape()
            .fill(Color(hex: "6C31E3"))
    }
}

struct ObsidianShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Original viewBox: 0 0 512 512
        let scale = min(rect.width / 512, rect.height / 512)
        let xOff = (rect.width - 512 * scale) / 2
        let yOff = (rect.height - 512 * scale) / 2

        var path = Path()
        // Simplified crystal shape approximating the Obsidian logo
        let points: [(CGFloat, CGFloat)] = [
            (248, 9), (143, 104), (131, 209), (118, 211),
            (61, 342), (156, 480), (230, 486),
            (334, 511), (383, 476), (407, 403),
            (452, 332), (451, 313), (407, 241),
            (394, 148), (386, 126), (298, 13)
        ]
        if let first = points.first {
            path.move(to: CGPoint(x: first.0 * scale + xOff, y: first.1 * scale + yOff))
            for pt in points.dropFirst() {
                path.addLine(to: CGPoint(x: pt.0 * scale + xOff, y: pt.1 * scale + yOff))
            }
            path.closeSubpath()
        }
        return path
    }
}
