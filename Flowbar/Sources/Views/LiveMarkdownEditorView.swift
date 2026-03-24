import SwiftUI
import AppKit

/// Editable view with live markdown formatting — headings render large/bold,
/// done todos show strikethrough. Always editable, no mode toggle.
struct LiveMarkdownEditorView: NSViewRepresentable {
    @Binding var text: String
    var baseSize: CGFloat
    var onTextChange: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        configure(textView, coordinator: context.coordinator)
        setText(text, in: textView)
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        guard !context.coordinator.isUpdating, textView.string != text else { return }
        context.coordinator.isUpdating = true
        setText(text, in: textView)
        context.coordinator.isUpdating = false
    }

    private func configure(_ textView: NSTextView, coordinator: Coordinator) {
        textView.delegate = coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.typingAttributes = Self.defaultAttrs(size: baseSize)
        coordinator.textView = textView
    }

    private func setText(_ string: String, in textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        storage.beginEditing()
        storage.setAttributedString(NSAttributedString(string: string, attributes: Self.defaultAttrs(size: baseSize)))
        Self.applyFormatting(to: storage, baseSize: baseSize)
        storage.endEditing()
    }

    // MARK: - Formatting

    static func defaultAttrs(size: CGFloat) -> [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: size), .foregroundColor: NSColor.labelColor]
    }

    static func applyFormatting(to storage: NSTextStorage, baseSize: CGFloat) {
        let full = NSRange(location: 0, length: storage.length)
        storage.setAttributes(defaultAttrs(size: baseSize), range: full)
        var offset = 0
        for line in storage.string.components(separatedBy: "\n") {
            let lineRange = NSRange(location: offset, length: (line as NSString).length)
            applyLineStyle(line, in: lineRange, to: storage, baseSize: baseSize)
            offset += (line as NSString).length + 1
        }
    }

    private static func applyLineStyle(_ line: String, in range: NSRange, to storage: NSTextStorage, baseSize: CGFloat) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let level = trimmed.prefix(while: { $0 == "#" }).count
        if level >= 1, level <= 6, trimmed.dropFirst(level).hasPrefix(" ") {
            let sizes: [CGFloat] = [baseSize * 2.0, baseSize * 1.6, baseSize * 1.3, baseSize * 1.15, baseSize * 1.05, baseSize]
            let weight: NSFont.Weight = level <= 2 ? .bold : .semibold
            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: sizes[level - 1], weight: weight), range: range)
        } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            storage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: range)
            storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    // MARK: - Coordinator

    @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LiveMarkdownEditorView
        weak var textView: NSTextView?
        var isUpdating = false

        init(_ parent: LiveMarkdownEditorView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let tv = notification.object as? NSTextView,
                  let storage = tv.textStorage else { return }
            isUpdating = true
            let selection = tv.selectedRange()
            storage.beginEditing()
            LiveMarkdownEditorView.applyFormatting(to: storage, baseSize: parent.baseSize)
            storage.endEditing()
            tv.setSelectedRange(selection)
            tv.typingAttributes = LiveMarkdownEditorView.defaultAttrs(size: parent.baseSize)
            parent.text = tv.string
            parent.onTextChange()
            isUpdating = false
        }

        func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                return handleNewline(textView)
            }
            return false
        }

        private func handleNewline(_ tv: NSTextView) -> Bool {
            let nsText = tv.string as NSString
            let cursor = tv.selectedRange().location
            let lineRange = nsText.lineRange(for: NSRange(location: cursor, length: 0))
            let line = nsText.substring(with: lineRange).replacingOccurrences(of: "\n", with: "")
            let indent = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            let emptyPrefixes = ["-", "- [ ]", "- [x]", "- [X]", "*"]
            if emptyPrefixes.contains(trimmed) {
                tv.setSelectedRange(lineRange)
                tv.insertText("\n", replacementRange: tv.selectedRange())
                return true
            }

            var prefix = ""
            if trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                prefix = indent + "- [ ] "
            } else if trimmed.hasPrefix("- ") {
                prefix = indent + "- "
            } else if trimmed.hasPrefix("* ") {
                prefix = indent + "* "
            }

            if !prefix.isEmpty {
                tv.insertText("\n" + prefix, replacementRange: tv.selectedRange())
                return true
            }
            return false
        }
    }
}
