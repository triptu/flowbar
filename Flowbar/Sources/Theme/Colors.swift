import SwiftUI
import AppKit

/// P3 color components — values can push beyond sRGB gamut for richer color on wide-gamut displays.
private typealias P3 = (r: Double, g: Double, b: Double)

/// Preset accent colors using Display P3 gamut for wide-gamut richness.
/// Each has a light variant (richer, for light backgrounds) and a dark variant (softer, for dark backgrounds).
enum AccentColor: String, CaseIterable {
    case sage, ocean, lavender, amber, clay, slate, rose

    var displayName: String {
        rawValue.capitalized
    }

    /// Color shown in the swatch picker (uses the dark-mode variant for a vibrant preview)
    var preview: Color {
        Color(.displayP3, red: p3Pair.dark.r, green: p3Pair.dark.g, blue: p3Pair.dark.b)
    }

    /// (light P3, dark P3) — single source of truth for both variants
    private var p3Pair: (light: P3, dark: P3) {
        switch self {
        case .sage:     return ((0.32, 0.50, 0.30), (0.34, 0.56, 0.30))  // herb green / deep leaf
        case .ocean:    return ((0.18, 0.44, 0.58), (0.20, 0.50, 0.62))  // deep water / dark cyan
        case .lavender: return ((0.40, 0.34, 0.64), (0.42, 0.36, 0.64))  // soft indigo / deep wisteria
        case .amber:    return ((0.76, 0.56, 0.36), (0.72, 0.52, 0.30))  // warm peach / deep gold
        case .clay:     return ((0.60, 0.32, 0.24), (0.62, 0.36, 0.28))  // terracotta / deep clay
        case .slate:    return ((0.30, 0.36, 0.46), (0.34, 0.40, 0.52))  // cool ink / dark steel
        case .rose:     return ((0.62, 0.30, 0.42), (0.62, 0.32, 0.42))  // dusty wine / deep rose
        }
    }

    /// Adaptive NSColor that switches between light/dark variants based on appearance
    var nsColor: NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let c = isDark ? self.p3Pair.dark : self.p3Pair.light
            return NSColor(colorSpace: .displayP3, components: [CGFloat(c.r), CGFloat(c.g), CGFloat(c.b), 1], count: 4)
        }
    }

    /// Adaptive SwiftUI Color (wraps nsColor)
    var color: Color {
        Color(nsColor: nsColor)
    }
}

enum FlowbarColors {
    static var titleBarBg: Color {
        Color.primary.opacity(0.08)
    }
    static var sidebarBg: Color {
        Color.primary.opacity(0.04)
    }

    /// Very subtle warm tint overlaid on the material background in light mode.
    /// Gives the light theme texture and warmth instead of flat white.
    /// Invisible in dark mode so the glass-like depth is preserved.
    static var warmTint: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if isDark {
                return .clear
            } else {
                // Warm cream tint (~#FDFBF8) — just enough to break the sterile white
                return NSColor(displayP3Red: 0.94, green: 0.88, blue: 0.78, alpha: 0.07)
            }
        })
    }
}

// MARK: - Hex color initializer (Display P3, kept for one-off colors outside the palette)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        guard hex.count == 6 else { self.init(.displayP3, red: 0, green: 0, blue: 0); return }
        self.init(
            .displayP3,
            red: Double((int >> 16) & 0xFF) / 255.0,
            green: Double((int >> 8) & 0xFF) / 255.0,
            blue: Double(int & 0xFF) / 255.0
        )
    }
}
