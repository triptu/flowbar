import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    private var appState: AppState?

    init(contentRect: NSRect, appState: AppState) {
        self.appState = appState
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        minSize = NSSize(width: 400, height: 300)
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
