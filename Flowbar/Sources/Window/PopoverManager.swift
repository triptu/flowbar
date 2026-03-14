import AppKit
import SwiftUI
import Observation

/// Manages the menu bar status item, popover, and floating panel lifecycle.
///
/// Owns the NSStatusItem (menu bar icon) and the NSPopover. Can switch between
/// popover mode (attached to menu bar) and floating panel mode (detached window).
/// Injected via .environment() so views can trigger float/dock and read isFloating.
@Observable
@MainActor
final class PopoverManager: NSObject {
    let statusItem: NSStatusItem
    let popover: NSPopover
    var isFloating = false

    @ObservationIgnored private var floatingPanel: FloatingPanel?
    @ObservationIgnored private var appState: AppState
    @ObservationIgnored private var timerService: TimerService?
    @ObservationIgnored private var statusMenu: NSMenu
    @ObservationIgnored private var rightClickMonitor: Any?

    init(appState: AppState) {
        self.appState = appState
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        statusMenu = NSMenu()
        super.init()

        popover.behavior = .transient
        popover.animates = true

        let quitItem = NSMenuItem(title: "Quit Flowbar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)

        if let button = statusItem.button {
            button.image = Self.makeMenuBarIcon()
            // Default sendAction fires on mouseDown — this gives native highlight behavior
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }

        // Handle right-click separately via event monitor
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { [weak self] event in
            guard let self, let button = self.statusItem.button else { return event }
            let pointInButton = button.convert(event.locationInWindow, from: nil)
            if button.bounds.contains(pointInButton) {
                self.statusItem.menu = self.statusMenu
                button.performClick(nil)
                self.statusItem.menu = nil
                return nil
            }
            return event
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        togglePopover(sender)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func setContentView(_ view: some View, timerService: TimerService) {
        self.timerService = timerService
        popover.contentViewController = NSHostingController(rootView: view)
        popover.contentSize = NSSize(width: appState.popoverWidth, height: appState.popoverHeight)
    }

    @objc func togglePopover(_ sender: Any?) {
        if isFloating {
            dockPanel()
            return
        }
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.contentSize = NSSize(width: appState.popoverWidth, height: appState.popoverHeight)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    func closePopover() {
        popover.performClose(nil)
    }

    func floatPanel() {
        guard let timerService else { return }
        let size = NSSize(width: appState.popoverWidth, height: appState.popoverHeight)
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let origin = NSPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.midY - size.height / 2
        )
        let frame = NSRect(origin: origin, size: size)
        closePopover()

        let panel = FloatingPanel(contentRect: frame, appState: appState)
        let mainView = MainView()
            .environment(appState)
            .environment(timerService)
            .environment(self)
        panel.setContent(mainView)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        panel.delegate = self
        floatingPanel = panel
        isFloating = true
    }

    func dockPanel() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.floatingPanel?.animator().alphaValue = 0
        }) { [weak self] in
            DispatchQueue.main.async {
                self?.floatingPanel?.close()
                self?.floatingPanel = nil
                self?.isFloating = false
                self?.showPopover()
            }
        }
    }

    /// Draws the Flowbar logo (river stone with flow groove) as a menu bar template image.
    /// macOS auto-colors template images to match the system appearance.
    private static func makeMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let scale = min(rect.width, rect.height) / 24.0
            let transform = NSAffineTransform()
            transform.scale(by: scale)

            let path = NSBezierPath()
            // Outer circle (stone shape)
            path.move(to: NSPoint(x: 12, y: 2.5))
            path.curve(to: NSPoint(x: 2.5, y: 12),
                       controlPoint1: NSPoint(x: 7, y: 2.5),
                       controlPoint2: NSPoint(x: 2.5, y: 7))
            path.curve(to: NSPoint(x: 12, y: 21.5),
                       controlPoint1: NSPoint(x: 2.5, y: 17),
                       controlPoint2: NSPoint(x: 7, y: 21.5))
            path.curve(to: NSPoint(x: 21.5, y: 12),
                       controlPoint1: NSPoint(x: 17, y: 21.5),
                       controlPoint2: NSPoint(x: 21.5, y: 17))
            path.curve(to: NSPoint(x: 12, y: 2.5),
                       controlPoint1: NSPoint(x: 21.5, y: 7),
                       controlPoint2: NSPoint(x: 17, y: 2.5))
            path.close()

            // Flow groove (cutout) — winds through the center
            let groove = NSBezierPath()
            groove.move(to: NSPoint(x: 3.8, y: 11.2))
            // Top edge of groove (S-curve right)
            groove.curve(to: NSPoint(x: 10.5, y: 10.8),
                         controlPoint1: NSPoint(x: 7, y: 8.8),
                         controlPoint2: NSPoint(x: 7, y: 8.8))
            groove.curve(to: NSPoint(x: 13.5, y: 12.2),
                         controlPoint1: NSPoint(x: 12, y: 11.8),
                         controlPoint2: NSPoint(x: 12, y: 11.8))
            groove.curve(to: NSPoint(x: 20.2, y: 10.8),
                         controlPoint1: NSPoint(x: 17, y: 13),
                         controlPoint2: NSPoint(x: 17, y: 13))
            // Bottom edge of groove (S-curve back left)
            groove.line(to: NSPoint(x: 20.2, y: 12.8))
            groove.curve(to: NSPoint(x: 13.5, y: 14.2),
                         controlPoint1: NSPoint(x: 17, y: 15),
                         controlPoint2: NSPoint(x: 17, y: 15))
            groove.curve(to: NSPoint(x: 10.5, y: 12.8),
                         controlPoint1: NSPoint(x: 12, y: 13.8),
                         controlPoint2: NSPoint(x: 12, y: 13.8))
            groove.curve(to: NSPoint(x: 3.8, y: 13.2),
                         controlPoint1: NSPoint(x: 7, y: 10.8),
                         controlPoint2: NSPoint(x: 7, y: 10.8))
            groove.close()

            path.transform(using: transform as AffineTransform)
            groove.transform(using: transform as AffineTransform)

            // Use even-odd rule: append groove inside the stone path
            // so the groove is punched out automatically
            path.append(groove)
            path.windingRule = .evenOdd
            NSColor.black.setFill()
            path.fill()

            return true
        }
        image.isTemplate = true
        return image
    }
}

// MARK: - NSWindowDelegate
/// Tracks floating panel close (e.g. via close button) to reset isFloating state.
extension PopoverManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard notification.object as? FloatingPanel === floatingPanel else { return }
        floatingPanel = nil
        isFloating = false
    }
}
