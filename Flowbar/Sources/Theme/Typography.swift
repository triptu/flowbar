import SwiftUI

enum TypographySize: String, CaseIterable {
    case small, `default`, large

    var bodySize: CGFloat {
        switch self {
        case .small: return 12
        case .default: return 14
        case .large: return 16
        }
    }

    var titleSize: CGFloat {
        switch self {
        case .small: return 20
        case .default: return 24
        case .large: return 28
        }
    }

    var sidebarSize: CGFloat {
        switch self {
        case .small: return 13
        case .default: return 15
        case .large: return 17
        }
    }

    var timerSize: CGFloat { 48 }
}
