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
        let args = ProcessInfo.processInfo.arguments
        let uitestFolder = args.firstIndex(of: "-uitest-folder").flatMap { idx in
            idx + 1 < args.count ? args[idx + 1] : nil
        }

        if let folder = uitestFolder {
            // If running UI tests, use the provided folder path and a shared UserDefaults suite to persist it. This is to avoid conflicts with the regular app's settings.
            let defaults = UserDefaults(suiteName: "com.flowbar.uitests")!
            defaults.set(folder, forKey: "folderPath")
            appState = AppState(defaults: defaults)
        } else {
            appState = AppState()
        }
        timerService = TimerService()
        windowManager = WindowManager(appState: appState, timerService: timerService)
        setupDoubleFnShortcut()

        if uitestFolder != nil {
            // If running UI tests, show the panel immediately. Otherwise, rely on the user to click the menu bar icon or use the shortcut.
            windowManager.showPanel()
        }
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
