import AppKit
import SwiftUI

/// The overlay window shown when the user clicks the menu bar icon or presses double-Fn.
///
/// Configured as an always-on-top utility panel that joins all Spaces. Saves its
/// size back via an onClose callback so dimensions persist across sessions.
/// Traffic lights, sidebar toggle, and active task label all live in the native
/// title bar view hierarchy so they receive clicks and align naturally.
class FloatingPanel: NSPanel {
    /// Horizontal offset where traffic lights start (aligned with sidebar item text).
    static let trafficLightX: CGFloat = 20
    /// Width past the traffic lights area. Used by views to inset content.
    static let trafficLightWidth: CGFloat = 80
    /// Height of the native title bar region.
    static let titleBarHeight: CGFloat = 28

    /// Called with (frame, spaceID) when the panel closes, so the caller can persist the window frame.
    private let onClose: (NSRect, Int) -> Void
    private var initialSize: NSSize = .zero
    /// The Space ID this panel was created on, used to save per-Space frame
    let spaceID: Int
    /// Hosting view for the active task label, kept for cleanup
    private var activeTaskHost: NSView?

    init(contentRect: NSRect, spaceID: Int, onClose: @escaping (NSRect, Int) -> Void) {
        self.onClose = onClose
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
        repositionTrafficLights()
    }

    /// Add a native NSButton to the title bar view hierarchy so it receives clicks.
    /// Placed right after the traffic lights, vertically centered.
    func addSidebarToggle(action: @escaping () -> Void) {
        guard let closeButton = standardWindowButton(.closeButton),
              let titlebarView = closeButton.superview else { return }

        let button = TitleBarButton(action: action)
        button.image = NSImage(
            systemSymbolName: "sidebar.left",
            accessibilityDescription: "Toggle Sidebar"
        )
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.bezelStyle = .inline
        (button.cell as? NSButtonCell)?.highlightsBy = .contentsCellMask
        button.contentTintColor = .secondaryLabelColor

        let size: CGFloat = 20
        let x = Self.trafficLightWidth + 10
        let y = (titlebarView.bounds.height - size) / 2
        button.frame = NSRect(x: x, y: y, width: size, height: size)
        button.autoresizingMask = [.minYMargin]

        titlebarView.addSubview(button)
    }

    /// Add a SwiftUI active task label centered in the title bar.
    func addActiveTaskLabel(_ view: some View) {
        guard let closeButton = standardWindowButton(.closeButton),
              let titlebarView = closeButton.superview else { return }

        let host = NSHostingView(rootView: view)
        host.translatesAutoresizingMaskIntoConstraints = false
        host.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Transparent background so the title bar shows through
        host.layer?.backgroundColor = .clear
        titlebarView.addSubview(host)

        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: titlebarView.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: titlebarView.trailingAnchor),
            host.centerYAnchor.constraint(equalTo: titlebarView.centerYAnchor),
            host.heightAnchor.constraint(equalTo: titlebarView.heightAnchor),
        ])

        activeTaskHost = host
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
        onClose(frame, spaceID)
        super.close()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// NSButton that fires a closure and lives in the title bar view hierarchy.
final class TitleBarButton: NSButton {
    private let onClick: () -> Void

    init(action: @escaping () -> Void) {
        self.onClick = action
        super.init(frame: .zero)
        target = self
        self.action = #selector(handleClick)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleClick() {
        onClick()
    }

    override var mouseDownCanMoveWindow: Bool { false }
}
