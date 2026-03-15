import AppKit
import SwiftUI
import Observation

/// Manages the menu bar status item and the floating overlay panel.
///
/// Owns the NSStatusItem (menu bar icon). Clicking the icon or pressing
/// double-Fn toggles the overlay panel on/off. Injected via .environment()
/// so views can access window state.
@Observable
@MainActor
final class WindowManager: NSObject {
    let statusItem: NSStatusItem

    @ObservationIgnored private var panel: FloatingPanel?
    @ObservationIgnored private var appState: AppState
    @ObservationIgnored private var timerService: TimerService
    @ObservationIgnored private var statusMenu: NSMenu
    @ObservationIgnored private var rightClickMonitor: Any?
    @ObservationIgnored private var isHiding = false

    init(appState: AppState, timerService: TimerService) {
        self.appState = appState
        self.timerService = timerService
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusMenu = NSMenu()
        super.init()

        let openItem = NSMenuItem(title: "Open Flowbar", action: #selector(openFromMenu), keyEquivalent: "")
        openItem.target = self
        statusMenu.addItem(openItem)
        statusMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Flowbar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)

        if let button = statusItem.button {
            button.image = Self.makeMenuBarIcon()
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
        togglePanel()
    }

    @objc private func openFromMenu() {
        showPanel()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func togglePanel() {
        guard !isHiding else { return }
        if let panel, panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        if let panel {
            panel.alphaValue = 1
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let size = NSSize(width: appState.windowWidth, height: appState.windowHeight)
        let screen = NSScreen.main ?? NSScreen.screens.first!

        // Use saved position if available, otherwise center on screen
        let origin: NSPoint
        if appState.windowX >= 0, appState.windowY >= 0 {
            origin = NSPoint(x: appState.windowX, y: appState.windowY)
        } else {
            origin = NSPoint(
                x: screen.frame.midX - size.width / 2,
                y: screen.frame.midY - size.height / 2
            )
        }
        let frame = NSRect(origin: origin, size: size)

        let newPanel = FloatingPanel(contentRect: frame, appState: appState)
        let mainView = MainView()
            .environment(appState)
            .environment(timerService)
            .environment(self)
        newPanel.setContent(mainView)
        newPanel.delegate = self
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        panel = newPanel
    }

    func hidePanel() {
        guard let panelToClose = panel else { return }
        isHiding = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            panelToClose.animator().alphaValue = 0
        }) { [weak self] in
            panelToClose.close()
            self?.isHiding = false
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
            groove.curve(to: NSPoint(x: 10.5, y: 10.8),
                         controlPoint1: NSPoint(x: 7, y: 8.8),
                         controlPoint2: NSPoint(x: 7, y: 8.8))
            groove.curve(to: NSPoint(x: 13.5, y: 12.2),
                         controlPoint1: NSPoint(x: 12, y: 11.8),
                         controlPoint2: NSPoint(x: 12, y: 11.8))
            groove.curve(to: NSPoint(x: 20.2, y: 10.8),
                         controlPoint1: NSPoint(x: 17, y: 13),
                         controlPoint2: NSPoint(x: 17, y: 13))
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
/// Tracks panel close (e.g. via close button or Cmd+W) to clean up.
extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard notification.object as? FloatingPanel === panel else { return }
        panel = nil
        isHiding = false
    }
}
