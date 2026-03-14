import SwiftUI

enum FlowbarColors {
    // Accent — earthy sage green
    static let accent = Color(hex: "8B9A6B")
    static let accentLight = Color(hex: "6B7A4B")

    // Text
    static let textPrimary = Color(hex: "E8E8E8")
    static let textSecondary = Color(hex: "8A8A8A")
    static let textMuted = Color(hex: "5A5A5A")

    // Backgrounds
    static let sidebarSelected = Color(hex: "8B9A6B").opacity(0.25)
    static let divider = Color(hex: "2A2A2A").opacity(0.5)

    // Timer
    static let timerActive = Color(hex: "7CB342")

    // Light mode overrides
    static let textPrimaryLight = Color(hex: "1A1A1A")
    static let textSecondaryLight = Color(hex: "6A6A6A")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
