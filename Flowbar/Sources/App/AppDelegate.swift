import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var popoverManager: PopoverManager!
    var appState: AppState!
    var timerService: TimerService!
    var debugWindow: NSWindow?
    private var fnMonitor: Any?
    private var lastFnPress: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()
        timerService = TimerService()
        popoverManager = PopoverManager(appState: appState)

        let mainView = MainView()
            .environmentObject(appState)
            .environmentObject(timerService)
            .environmentObject(popoverManager)

        popoverManager.setContentView(mainView, timerService: timerService)
        setupDoubleFnShortcut()

        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered, defer: false
            )
            window.center()
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.contentView = NSHostingView(rootView:
                MainView()
                    .environmentObject(self.appState!)
                    .environmentObject(self.timerService!)
                    .environmentObject(self.popoverManager!)
            )
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.debugWindow = window
        }
        #endif
    }

    private func setupDoubleFnShortcut() {
        fnMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return }
            let fnPressed = event.modifierFlags.contains(.function)
            let otherMods: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
            guard event.modifierFlags.intersection(otherMods).isEmpty else { return }

            if fnPressed {
                let now = Date()
                if let last = self.lastFnPress, now.timeIntervalSince(last) < 0.4 {
                    self.lastFnPress = nil
                    DispatchQueue.main.async {
                        self.popoverManager.togglePopover(nil)
                    }
                } else {
                    self.lastFnPress = now
                }
            }
        }
    }
}
