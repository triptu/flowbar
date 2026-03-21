import SwiftUI
import AppKit

/// A small inline view that captures a key combination when focused.
///
/// Displays "Press shortcut..." while recording, or the current custom shortcut label.
/// Pressing Escape cancels recording.
struct ShortcutRecorderView: View {
    @Binding var shortcut: GlobalShortcut
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 6) {
            Text(isRecording ? "Press shortcut…" : shortcut.displayName)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(isRecording ? .primary : .tertiary)
                .frame(minWidth: 100, alignment: .center)

            if !isRecording {
                Button("Record") { isRecording = true }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else {
                Button("Cancel") { isRecording = false }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(isRecording ? 0.08 : 0.04))
        )
        .background {
            if isRecording {
                ShortcutKeyCapture { keyCode, modifiers in
                    shortcut = .custom(keyCode: keyCode, modifiers: modifiers)
                    isRecording = false
                } onCancel: {
                    isRecording = false
                }
            }
        }
    }
}

// MARK: - NSView-based key capture

/// An invisible NSView that becomes first responder to capture a single key event.
private struct ShortcutKeyCapture: NSViewRepresentable {
    let onCapture: (UInt16, NSEvent.ModifierFlags) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onCapture = onCapture
        view.onCancel = onCancel
        // Become first responder on next run loop to ensure the view is in the window
        DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.onCapture = onCapture
        nsView.onCancel = onCancel
    }
}

private final class KeyCaptureNSView: NSView {
    var onCapture: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel?()
            return
        }
        let mods = event.modifierFlags.intersection(GlobalShortcut.relevantModifiers)
        // Require at least one modifier for custom shortcuts (bare keys would conflict with typing)
        guard !mods.isEmpty else { return }
        onCapture?(event.keyCode, mods)
    }
}
