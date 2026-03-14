import AppKit
import SwiftUI

/// A detached floating window used when the user "pops out" from the menu bar popover.
///
/// Configured as an always-on-top utility panel that joins all Spaces. Saves its
/// size back to AppState on close so the popover remembers the last used dimensions.
/// The full title bar is the drag region. Traffic lights sit inside it over the sidebar.
class FloatingPanel: NSPanel {
    private var appState: AppState?

    init(contentRect: NSRect, appState: AppState) {
        self.appState = appState
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        minSize = NSSize(width: 400, height: 300)

        // Make the entire title bar area draggable
        standardWindowButton(.closeButton)?.superview?.superview?.wantsLayer = true
    }

    func setContent(_ view: some View) {
        contentView = NSHostingView(rootView: view)
    }

    override func close() {
        if let state = appState {
            state.popoverWidth = Double(frame.width)
            state.popoverHeight = Double(frame.height)
        }
        super.close()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
