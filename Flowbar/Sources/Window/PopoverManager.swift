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
            button.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "Flowbar")
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }
        if event.type == .rightMouseUp {
            statusItem.menu = statusMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePopover(sender)
        }
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
}
