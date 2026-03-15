import AppKit
import SwiftUI

/// The overlay window shown when the user clicks the menu bar icon or presses double-Fn.
///
/// Configured as an always-on-top utility panel that joins all Spaces. Saves its
/// size back to AppState on close so dimensions persist across sessions.
/// The full title bar is the drag region. Traffic lights sit inside it over the sidebar.
class FloatingPanel: NSPanel {
    /// Horizontal offset where traffic lights start (aligned with sidebar item text).
    static let trafficLightX: CGFloat = 20
    /// Width past the traffic lights area. Used by SidebarView to inset its header.
    static let trafficLightWidth: CGFloat = 80

    private let appState: AppState
    private var initialSize: NSSize = .zero
    /// The Space ID this panel was created on, used to save per-Space frame
    let spaceID: Int

    init(contentRect: NSRect, appState: AppState, spaceID: Int) {
        self.appState = appState
        self.spaceID = spaceID
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
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
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
        repositionTrafficLights()
    }

    /// Move traffic lights so they align horizontally with sidebar item text.
    private func repositionTrafficLights() {
        let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        let spacing: CGFloat = 20 // center-to-center
        for (i, type) in types.enumerated() {
            guard let button = standardWindowButton(type) else { continue }
            let x = Self.trafficLightX + CGFloat(i) * spacing
            button.setFrameOrigin(NSPoint(x: x, y: button.frame.origin.y))
        }
    }

    override func close() {
        appState.saveWindowFrame(frame, forSpace: spaceID)
        super.close()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
