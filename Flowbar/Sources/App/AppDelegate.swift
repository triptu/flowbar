import AppKit
import SwiftUI

/// App entry point that wires together the core services and the menu bar item.
///
/// Creates AppState, TimerService, and PopoverManager on launch, then injects them
/// via .environment() into the SwiftUI view hierarchy. Also sets up the double-Fn
/// global keyboard shortcut to toggle the popover from anywhere in macOS.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var popoverManager: PopoverManager!
    var appState: AppState!
    var timerService: TimerService!
    private var fnMonitor: Any?
    private var lastFnPress: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()
        timerService = TimerService()
        popoverManager = PopoverManager(appState: appState)

        let mainView = MainView()
            .environment(appState)
            .environment(timerService)
            .environment(popoverManager)

        popoverManager.setContentView(mainView, timerService: timerService)
        setupDoubleFnShortcut()
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
