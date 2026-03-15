import SwiftUI
import AppKit

/// Preset accent colors — each has a light variant (richer, darker for light backgrounds)
/// and a dark variant (softer, brighter for dark backgrounds), following the app's earthy/calm aesthetic.
enum AccentColor: String, CaseIterable {
    case sage, ocean, lavender, amber, clay, slate, rose

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
        case .sage:     return ("5C7A5A", "94C78A")  // muted herb green / soft leaf
        case .ocean:    return ("3B6D8C", "6ABED2")  // calm deep water / sky blue
        case .lavender: return ("6B5B99", "A894D4")  // soft purple / wisteria
        case .amber:    return ("9B7234", "D4A95A")  // warm honey / golden hour
        case .clay:     return ("8C5A4A", "D49882")  // terracotta / warm peach
        case .slate:    return ("505B6E", "8E9DB5")  // cool ink / blue steel
        case .rose:     return ("945A6E", "D4929F")  // dusty mauve / soft pink
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

    /// Adaptive SwiftUI Color (wraps nsColor)
    var color: Color {
        Color(nsColor: nsColor)
    }
}

enum FlowbarColors {
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
