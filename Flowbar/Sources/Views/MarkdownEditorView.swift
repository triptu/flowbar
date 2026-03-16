import SwiftUI
import AppKit

/// NSTextView wrapper that auto-continues bullets and todos on Enter.
///
/// When the user presses Return on a line starting with `- [ ] `, `- `, `* `, or `1. `,
/// the next line automatically gets the same prefix (with incremented numbers for ordered lists).
/// Pressing Return on an empty bullet/todo line removes it instead of continuing.
struct MarkdownEditorView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var focusOnAppear: Bool = false
    var onTextChange: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.font = font
        textView.string = text
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        context.coordinator.textView = textView
        if focusOnAppear {
            DispatchQueue.main.async { textView.window?.makeFirstResponder(textView) }
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text && !context.coordinator.isUpdating {
            context.coordinator.isUpdating = true
            textView.string = text
            textView.font = font
            context.coordinator.isUpdating = false
        }
    }

    @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditorView
        weak var textView: NSTextView?
        var isUpdating = false

        init(_ parent: MarkdownEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = textView.string
            parent.onTextChange()
            isUpdating = false
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                return handleNewline(textView)
            }
            return false
        }

        private func handleNewline(_ textView: NSTextView) -> Bool {
            let nsText = textView.string as NSString
            let cursorLocation = textView.selectedRange().location
            let lineRange = nsText.lineRange(for: NSRange(location: cursorLocation, length: 0))
            let currentLine = nsText.substring(with: lineRange).replacingOccurrences(of: "\n", with: "")

            let leadingWhitespace = String(currentLine.prefix(while: { $0 == " " || $0 == "\t" }))
            let trimmed = currentLine.trimmingCharacters(in: .whitespaces)

            // Empty bullet/todo — remove the prefix and just insert newline
            let emptyPrefixes = ["-", "- [ ]", "- [x]", "- [X]", "*"]
            if emptyPrefixes.contains(trimmed) || isEmptyNumberedItem(trimmed) {
                // Replace the current line content with just a newline
                textView.setSelectedRange(lineRange)
                textView.insertText("\n", replacementRange: textView.selectedRange())
                return true
            }

            // Determine continuation prefix
            var prefix = ""
            if trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                prefix = leadingWhitespace + "- [ ] "
            } else if trimmed.hasPrefix("- ") {
                prefix = leadingWhitespace + "- "
            } else if trimmed.hasPrefix("* ") {
                prefix = leadingWhitespace + "* "
            } else if let nextNum = nextNumberedPrefix(trimmed) {
                prefix = leadingWhitespace + nextNum
            }

            if !prefix.isEmpty {
                textView.insertText("\n" + prefix, replacementRange: textView.selectedRange())
                return true
            }

            return false
        }

        private func isEmptyNumberedItem(_ line: String) -> Bool {
            guard let dotIndex = line.firstIndex(of: ".") else { return false }
            let numPart = String(line[line.startIndex..<dotIndex])
            guard Int(numPart) != nil else { return false }
            let rest = line[line.index(after: dotIndex)...]
            return rest.isEmpty || rest == " "
        }

        private func nextNumberedPrefix(_ line: String) -> String? {
            guard let dotIndex = line.firstIndex(of: ".") else { return nil }
            let numStr = String(line[line.startIndex..<dotIndex])
            guard let num = Int(numStr),
                  line.index(after: dotIndex) < line.endIndex,
                  line[line.index(after: dotIndex)...].hasPrefix(" ") else { return nil }
            return "\(num + 1). "
        }
    }
}
