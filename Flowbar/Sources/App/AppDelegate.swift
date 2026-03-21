import AppKit
import ServiceManagement
import SwiftUI

/// App entry point that wires together the core services and the menu bar item.
///
/// Creates AppState, TimerService, and WindowManager on launch, then sets up
/// a configurable global keyboard shortcut to toggle the overlay from anywhere.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager: WindowManager!
    var appState: AppState!
    var timerService: TimerService!
    private var globalMonitor: Any?
    private var localMonitor: Any?
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
        enableLaunchAtLoginOnFirstRun()
        installShortcut()

        appState.settings.onShortcutChanged = { [weak self] in self?.installShortcut() }

        if uitestFolder != nil {
            // If running UI tests, show the panel immediately. Otherwise, rely on the user to click the menu bar icon or use the shortcut.
            windowManager.showPanel()
        }
    }

    // MARK: - Shortcut installation

    /// Tears down any existing monitors and installs new ones matching the current setting.
    private func installShortcut() {
        removeMonitors()
        lastFnPress = nil

        let shortcut = appState.settings.globalShortcut
        if shortcut.isDoubleTap {
            installDoubleFnMonitors()
        } else {
            installHotkeyMonitors(shortcut: shortcut)
        }
    }

    private func removeMonitors() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }

    // MARK: - Double-Fn

    private func installDoubleFnMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return }
            DispatchQueue.main.async { self.handleFnEvent(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFnEvent(event)
            return event
        }
    }

    private func handleFnEvent(_ event: NSEvent) {
        let fnPressed = event.modifierFlags.contains(.function)
        guard event.modifierFlags.intersection(GlobalShortcut.relevantModifiers).isEmpty else { return }

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

    // MARK: - Hotkey (single combo)

    private func installHotkeyMonitors(shortcut: GlobalShortcut) {
        guard let targetKeyCode = shortcut.keyCode else { return }
        let targetMods = shortcut.requiredModifiers

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            if Self.eventMatches(event, keyCode: targetKeyCode, modifiers: targetMods) {
                DispatchQueue.main.async { self.windowManager.togglePanel() }
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if Self.eventMatches(event, keyCode: targetKeyCode, modifiers: targetMods) {
                self.windowManager.togglePanel()
                return nil // consume the event
            }
            return event
        }
    }

    /// Check if an event's key code and modifier flags match the target.
    private static func eventMatches(
        _ event: NSEvent, keyCode: UInt16, modifiers: NSEvent.ModifierFlags
    ) -> Bool {
        guard event.keyCode == keyCode else { return false }
        let mask = GlobalShortcut.relevantModifiers
        return event.modifierFlags.intersection(mask) == modifiers.intersection(mask)
    }

    // MARK: - Launch at login

    private func enableLaunchAtLoginOnFirstRun() {
        let key = "hasRegisteredLaunchAtLogin"
        guard !appState.settings.defaults.bool(forKey: key) else { return }
        appState.settings.defaults.set(true, forKey: key)
        if SMAppService.mainApp.status != .enabled {
            appState.settings.launchAtLogin = true
        }
    }
}
