import SwiftUI
import AppKit

/// Preset accent colors — each has a light variant (richer, darker for light backgrounds)
/// and a dark variant (softer, brighter for dark backgrounds), following the app's earthy/calm aesthetic.
enum AccentColor: String, CaseIterable {
    case sage, forest, ocean, lavender, clay, slate, rose

    var displayName: String {
        rawValue.capitalized
    }

    /// Color shown in the swatch picker (uses the dark-mode variant for a vibrant preview)
    var preview: Color {
        Color(hex: darkHex)
    }

    /// (light hex, dark hex) — single source of truth for both variants
    private var hexPair: (light: String, dark: String) {
        switch self {
        case .sage:     return ("4A6332", "8CB86B")  // forest green / leaf green
        case .forest:   return ("2D5016", "5A9A3E")  // deep evergreen / bright moss
        case .ocean:    return ("2B5F6B", "5BB8C9")  // deep teal / soft cyan
        case .lavender: return ("5B4A8A", "9B8EC4")  // muted indigo / soft periwinkle
        case .clay:     return ("8B5E3C", "C9956B")  // warm terracotta / warm sand
        case .slate:    return ("4A5568", "8B9BB0")  // charcoal blue-gray / cool steel
        case .rose:     return ("8B4A5E", "C48B9F")  // dusty wine / soft blush
        }
    }

    var lightHex: String { hexPair.light }
    var darkHex: String { hexPair.dark }

    /// Adaptive NSColor that switches between light/dark variants based on appearance
    var nsColor: NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? self.darkHex : self.lightHex)
        }
    }
}

@MainActor
enum FlowbarColors {
    /// Current accent — call `update(accent:)` when the user changes their preference.
    /// Starts as sage (the original default) and gets overridden by AppState on launch.
    private(set) static var accent = Color(nsColor: AccentColor.sage.nsColor)

    static func update(accent: AccentColor) {
        self.accent = Color(nsColor: accent.nsColor)
    }

    static var sidebarBg: Color {
        Color.primary.opacity(0.04)
    }
}

// MARK: - Hex color initializers

extension Color {
    init(hex: String) {
        let (r, g, b) = hexToRGB(hex)
        self.init(red: r, green: g, blue: b)
    }
}

extension NSColor {
    convenience init(hex: String) {
        let (r, g, b) = hexToRGB(hex)
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

/// Shared hex→RGB parser used by both Color and NSColor initializers
private func hexToRGB(_ hex: String) -> (Double, Double, Double) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    guard hex.count == 6 else { return (0, 0, 0) }
    return (
        Double((int >> 16) & 0xFF) / 255.0,
        Double((int >> 8) & 0xFF) / 255.0,
        Double(int & 0xFF) / 255.0
    )
}
