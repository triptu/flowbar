import AppKit
import SwiftUI

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
            .environmentObject(appState)
            .environmentObject(timerService)
            .environmentObject(popoverManager)

        popoverManager.setContentView(mainView, timerService: timerService)
        setupDoubleFnShortcut()
    }

    private func setupDoubleFnShortcut() {
        fnMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return }
            let fnPressed = event.modifierFlags.contains(.function)
            // Only trigger on Fn key alone (no other modifiers)
            let otherMods: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
            guard !event.modifierFlags.intersection(otherMods).isEmpty == false else { return }

            if fnPressed {
                let now = Date()
                if let last = self.lastFnPress, now.timeIntervalSince(last) < 0.4 {
                    // Double-tap detected
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
