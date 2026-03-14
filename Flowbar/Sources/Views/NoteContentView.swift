import SwiftUI

struct NoteContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var popoverManager: PopoverManager
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            noteHeader

            Divider().opacity(0.3)

            if isEditing {
                TextEditor(text: $appState.editorContent)
                    .font(.system(size: appState.typography.bodySize, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .onChange(of: appState.editorContent) {
                        appState.saveFileContent()
                    }
            } else {
                renderedContent
            }
        }
    }

    private var noteHeader: some View {
        HStack(spacing: 12) {
            Text(appState.selectedFile?.name ?? "")
                .font(.system(size: appState.typography.titleSize, weight: .bold))

            Spacer()

            // Edit toggle
            Button(action: { isEditing.toggle() }) {
                Image(systemName: isEditing ? "eye" : "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(isEditing ? FlowbarColors.accent : .secondary)
            }
            .buttonStyle(.plain)
            .help(isEditing ? "View mode" : "Edit mode")

            // Open in Obsidian
            Button(action: { appState.openInObsidian() }) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.purple)
            }
            .buttonStyle(.plain)
            .help("Open in Obsidian")

            // Pop out / dock
            Button(action: {
                if popoverManager.isFloating {
                    popoverManager.dockPanel()
                } else {
                    popoverManager.floatPanel()
                }
            }) {
                Image(systemName: popoverManager.isFloating ? "arrow.down.forward.and.arrow.up.backward" : "arrow.up.backward.and.arrow.down.forward")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help(popoverManager.isFloating ? "Dock to menu bar" : "Pop out as overlay")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var renderedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                let lines = appState.editorContent.components(separatedBy: "\n")
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    renderLine(line, at: index)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onTapGesture(count: 2) {
            isEditing = true
        }
    }

    @ViewBuilder
    private func renderLine(_ line: String, at index: Int) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("# ") {
            Text(String(trimmed.dropFirst(2)))
                .font(.system(size: appState.typography.titleSize, weight: .bold))
                .padding(.top, 8)
        } else if trimmed.hasPrefix("## ") {
            Text(String(trimmed.dropFirst(3)))
                .font(.system(size: appState.typography.titleSize - 4, weight: .semibold))
                .padding(.top, 6)
        } else if trimmed.hasPrefix("### ") {
            Text(String(trimmed.dropFirst(4)))
                .font(.system(size: appState.typography.bodySize + 2, weight: .semibold))
                .padding(.top, 4)
        } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            todoLine(text: String(trimmed.dropFirst(6)), isDone: true, lineIndex: index)
        } else if trimmed.hasPrefix("- [ ] ") {
            todoLine(text: String(trimmed.dropFirst(6)), isDone: false, lineIndex: index)
        } else if trimmed.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundStyle(.secondary)
                Text(String(trimmed.dropFirst(2)))
                    .font(.system(size: appState.typography.bodySize))
            }
        } else if trimmed.isEmpty {
            Spacer().frame(height: 4)
        } else {
            Text(line)
                .font(.system(size: appState.typography.bodySize))
        }
    }

    private func todoLine(text: String, isDone: Bool, lineIndex: Int) -> some View {
        HStack(spacing: 10) {
            Button(action: {
                guard let file = appState.selectedFile else { return }
                _ = MarkdownParser.toggleTodo(at: lineIndex, in: file.url)
                appState.loadFileContent(file)
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isDone ? FlowbarColors.accent : Color.clear)
                        .frame(width: 22, height: 22)
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(isDone ? FlowbarColors.accent : Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(text)
                .font(.system(size: appState.typography.bodySize))
                .strikethrough(isDone)
                .opacity(isDone ? 0.5 : 1)
        }
        .padding(.vertical, 4)
    }
}
