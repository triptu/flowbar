import AppKit
import SwiftUI

/// The overlay window shown when the user clicks the menu bar icon or presses double-Fn.
///
/// Configured as an always-on-top utility panel that joins all Spaces. Saves its
/// size back to AppState on close so dimensions persist across sessions.
/// The full title bar is the drag region. Traffic lights sit inside it over the sidebar.
class FloatingPanel: NSPanel {
    /// Width of the standard traffic light buttons area (close/minimize/zoom).
    /// Used by SidebarView to inset its header past the buttons.
    static let trafficLightWidth: CGFloat = 76

    private let appState: AppState
    private var initialSize: NSSize = .zero

    init(contentRect: NSRect, appState: AppState) {
        self.appState = appState
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        initialSize = contentRect.size
        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
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
        // Persist size if user resized
        if frame.size != initialSize {
            appState.windowWidth = Double(frame.width)
            appState.windowHeight = Double(frame.height)
        }
        // Always persist position so it reopens where the user left it
        appState.windowX = Double(frame.origin.x)
        appState.windowY = Double(frame.origin.y)
        super.close()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
