import SwiftUI

/// Renders markdown content as native SwiftUI views with clickable checkboxes and styled headings.
struct MarkdownPreviewView: View {
    let content: String
    let bodySize: CGFloat
    let accentColor: Color
    let onToggleTodo: (Int) -> Void
    var onDoubleClick: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(MarkdownParser.parseBlocks(from: content).enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onTapGesture(count: 2) { onDoubleClick?() }
    }

    // MARK: - Block views

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)
        case .todo(let isDone, let text, let lineIndex, let indent):
            todoView(isDone: isDone, text: text, lineIndex: lineIndex, indent: indent)
        case .bullet(let text, let indent):
            bulletView(text: text, indent: indent)
        case .numbered(let number, let text, let indent):
            numberedView(number: number, text: text, indent: indent)
        case .codeBlock(let code):
            codeBlockView(code)
        case .blockquote(let text):
            blockquoteView(text)
        case .horizontalRule:
            Divider().padding(.vertical, 4)
        case .paragraph(let text):
            inlineMarkdown(text)
                .font(.system(size: bodySize))
        case .empty:
            Spacer().frame(height: bodySize * 0.5)
        }
    }

    private func headingView(level: Int, text: String) -> some View {
        let size: CGFloat = switch level {
        case 1: bodySize * 2.0
        case 2: bodySize * 1.6
        case 3: bodySize * 1.3
        case 4: bodySize * 1.15
        default: bodySize * 1.05
        }
        return inlineMarkdown(text)
            .font(.system(size: size, weight: level <= 2 ? .bold : .semibold))
            .padding(.top, level <= 2 ? 8 : 4)
            .padding(.bottom, 2)
    }

    private func todoView(isDone: Bool, text: String, lineIndex: Int, indent: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Button(action: { onToggleTodo(lineIndex) }) {
                Image(systemName: isDone ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isDone ? accentColor : .secondary)
                    .font(.system(size: bodySize))
            }
            .buttonStyle(.plain)

            inlineMarkdown(text)
                .font(.system(size: bodySize))
                .strikethrough(isDone)
                .foregroundStyle(isDone ? .secondary : .primary)
        }
        .padding(.leading, indentPadding(indent))
        .padding(.vertical, 1)
    }

    private func bulletView(text: String, indent: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\u{2022}")
                .foregroundStyle(.secondary)
            inlineMarkdown(text)
                .font(.system(size: bodySize))
        }
        .padding(.leading, indentPadding(indent))
        .padding(.vertical, 1)
    }

    private func numberedView(number: Int, text: String, indent: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(number).")
                .foregroundStyle(.secondary)
                .font(.system(size: bodySize))
            inlineMarkdown(text)
                .font(.system(size: bodySize))
        }
        .padding(.leading, indentPadding(indent))
        .padding(.vertical, 1)
    }

    /// Converts character-level indent (spaces/tabs) to padding.
    /// Standard markdown uses 2 or 4 spaces per nesting level.
    private func indentPadding(_ indent: Int) -> CGFloat {
        CGFloat(indent / 2) * 12
    }

    private func codeBlockView(_ code: String) -> some View {
        Text(code)
            .font(.system(size: bodySize - 1, design: .monospaced))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.vertical, 4)
    }

    private func blockquoteView(_ text: String) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(accentColor.opacity(0.5))
                .frame(width: 3)
            inlineMarkdown(text)
                .font(.system(size: bodySize))
                .foregroundStyle(.secondary)
                .padding(.leading, 10)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Inline markdown

    private func inlineMarkdown(_ text: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed)
        } else {
            return Text(text)
        }
    }
}
