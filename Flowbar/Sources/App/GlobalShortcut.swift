import AppKit

/// Represents the user's chosen global shortcut for toggling Flowbar.
///
/// Presets cover the most common choices; `.custom` stores an arbitrary key + modifiers.
enum GlobalShortcut: Equatable {
    case doubleFn
    case ctrlSpace
    case optionSpace
    case shiftSpace
    case custom(keyCode: UInt16, modifiers: NSEvent.ModifierFlags)

    // MARK: - Display

    var displayName: String {
        switch self {
        case .doubleFn: return "Double-tap Fn"
        case .ctrlSpace: return "⌃ Space"
        case .optionSpace: return "⌥ Space"
        case .shiftSpace: return "⇧ Space"
        case .custom(let keyCode, let modifiers):
            return Self.symbolString(modifiers: modifiers, keyCode: keyCode)
        }
    }

    /// Whether this shortcut uses double-tap detection vs a single hotkey combo.
    var isDoubleTap: Bool {
        if case .doubleFn = self { return true }
        return false
    }

    /// The key code to match for hotkey-style shortcuts (non-double-tap).
    var keyCode: UInt16? {
        switch self {
        case .doubleFn: return nil
        case .ctrlSpace, .optionSpace, .shiftSpace: return 49 // space bar
        case .custom(let kc, _): return kc
        }
    }

    /// The modifier flags required for hotkey-style shortcuts.
    var requiredModifiers: NSEvent.ModifierFlags {
        switch self {
        case .doubleFn: return []
        case .ctrlSpace: return .control
        case .optionSpace: return .option
        case .shiftSpace: return .shift
        case .custom(_, let mods): return mods
        }
    }

    // MARK: - Persistence

    /// Encode to a dictionary for UserDefaults storage.
    func toDictionary() -> [String: Any] {
        switch self {
        case .doubleFn:
            return ["type": "doubleFn"]
        case .ctrlSpace:
            return ["type": "ctrlSpace"]
        case .optionSpace:
            return ["type": "optionSpace"]
        case .shiftSpace:
            return ["type": "shiftSpace"]
        case .custom(let keyCode, let modifiers):
            return ["type": "custom", "keyCode": Int(keyCode), "modifiers": Int(modifiers.rawValue)]
        }
    }

    /// Decode from a UserDefaults dictionary.
    static func from(dictionary: [String: Any]) -> GlobalShortcut? {
        guard let type = dictionary["type"] as? String else { return nil }
        switch type {
        case "doubleFn": return .doubleFn
        case "ctrlSpace": return .ctrlSpace
        case "optionSpace": return .optionSpace
        case "shiftSpace": return .shiftSpace
        case "custom":
            guard let kc = dictionary["keyCode"] as? Int,
                  let mods = dictionary["modifiers"] as? Int else { return nil }
            return .custom(keyCode: UInt16(kc), modifiers: NSEvent.ModifierFlags(rawValue: UInt(mods)))
        default: return nil
        }
    }

    // MARK: - Shared constants

    static let relevantModifiers: NSEvent.ModifierFlags = [.shift, .control, .option, .command]

    static let presets: [GlobalShortcut] = [.doubleFn, .ctrlSpace, .optionSpace, .shiftSpace]

    // MARK: - Key symbol helpers

    static func symbolString(modifiers: NSEvent.ModifierFlags, keyCode: UInt16) -> String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(keyName(for: keyCode))
        return parts.joined(separator: " ")
    }

    private static let keyNames: [UInt16: String] = [
            49: "Space", 36: "Return", 48: "Tab", 51: "Delete", 53: "Escape",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
            43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            50: "`", 65: ".", 67: "*", 69: "+", 71: "Clear",
            75: "/", 76: "Enter", 78: "-",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]

    static func keyName(for keyCode: UInt16) -> String {
        keyNames[keyCode] ?? "Key\(keyCode)"
    }
}
