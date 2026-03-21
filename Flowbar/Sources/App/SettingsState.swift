import ServiceManagement
import SwiftUI
import Observation

extension Notification.Name {
    static let globalShortcutChanged = Notification.Name("globalShortcutChanged")
}

/// Persisted user preferences — theme, typography, accent color, folder path, window frames.
///
/// Each property writes to UserDefaults via didSet. The `defaults` instance is injectable
/// so tests can pass a throwaway suite.
@Observable
@MainActor
final class SettingsState {
    @ObservationIgnored let defaults: UserDefaults

    var folderPath: String {
        didSet { defaults.set(folderPath, forKey: "folderPath") }
    }
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: "theme") }
    }
    var typography: TypographySize {
        didSet { defaults.set(typography.rawValue, forKey: "typography") }
    }
    var accentColor: AccentColor {
        didSet { defaults.set(accentColor.rawValue, forKey: "accentColor") }
    }

    /// Reactive accent color — views should use this instead of reading from a static.
    var accent: Color { accentColor.color }

    var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Revert on failure
                launchAtLogin = oldValue
            }
        }
    }

    var globalShortcut: GlobalShortcut {
        didSet {
            defaults.set(globalShortcut.toDictionary(), forKey: "globalShortcut")
            NotificationCenter.default.post(name: .globalShortcutChanged, object: nil)
        }
    }

    /// Per-Space window frames: [SpaceID: [x, y, width, height]]
    @ObservationIgnored var windowFrames: [String: [Double]] {
        didSet { defaults.set(windowFrames, forKey: "windowFrames") }
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    /// Default window size for new Spaces
    static let defaultWindowSize = NSSize(width: 700, height: 500)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.folderPath = defaults.string(forKey: "folderPath") ?? ""
        self.theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .dark
        self.typography = TypographySize(rawValue: defaults.string(forKey: "typography") ?? "") ?? .default
        self.accentColor = AccentColor(rawValue: defaults.string(forKey: "accentColor") ?? "") ?? .amber
        if let dict = defaults.object(forKey: "globalShortcut") as? [String: Any],
           let shortcut = GlobalShortcut.from(dictionary: dict) {
            self.globalShortcut = shortcut
        } else {
            self.globalShortcut = .doubleFn
        }
        self.windowFrames = defaults.object(forKey: "windowFrames") as? [String: [Double]] ?? [:]
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Toggle between light and dark theme.
    func toggleTheme() {
        theme = theme == .dark ? .light : .dark
    }

    // MARK: - Per-Space window frame

    func windowFrame(forSpace spaceID: Int) -> NSRect? {
        guard let vals = windowFrames[String(spaceID)], vals.count == 4 else { return nil }
        return NSRect(x: vals[0], y: vals[1], width: vals[2], height: vals[3])
    }

    func saveWindowFrame(_ frame: NSRect, forSpace spaceID: Int) {
        let newVal = [
            Double(frame.origin.x), Double(frame.origin.y),
            Double(frame.width), Double(frame.height)
        ]
        let key = String(spaceID)
        guard windowFrames[key] != newVal else { return }
        windowFrames[key] = newVal
    }
}
