import AppKit
import SwiftUI

/// App entry point that wires together the core services and the menu bar item.
///
/// Creates AppState, TimerService, and WindowManager on launch, then sets up
/// the double-Fn global keyboard shortcut to toggle the overlay from anywhere.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager: WindowManager!
    var appState: AppState!
    var timerService: TimerService!
    private var globalFnMonitor: Any?
    private var localFnMonitor: Any?
    private var lastFnPress: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()
        timerService = TimerService()
        windowManager = WindowManager(appState: appState, timerService: timerService)
        setupDoubleFnShortcut()
    }

    private func handleFnEvent(_ event: NSEvent) {
        let fnPressed = event.modifierFlags.contains(.function)
        let otherMods: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
        guard event.modifierFlags.intersection(otherMods).isEmpty else { return }

        if fnPressed {
            let now = Date()
            if let last = lastFnPress, now.timeIntervalSince(last) < 0.4 {
                lastFnPress = nil
                windowManager.togglePanel()
            } else {
                lastFnPress = now
            }
        }
    }

    private func setupDoubleFnShortcut() {
        // Global monitor fires when another app is focused
        globalFnMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return }
            DispatchQueue.main.async { self.handleFnEvent(event) }
        }
        // Local monitor fires when Flowbar itself is focused
        localFnMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFnEvent(event)
            return event
        }
    }
}
