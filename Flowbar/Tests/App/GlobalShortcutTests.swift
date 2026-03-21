import Testing
@testable import Flowbar
import AppKit

@Suite("GlobalShortcut")
struct GlobalShortcutTests {

    // MARK: - Display names

    @Test("preset display names", arguments: [
        (GlobalShortcut.doubleFn, "Double-tap Fn"),
        (.ctrlSpace, "⌃ Space"),
        (.optionSpace, "⌥ Space"),
        (.shiftSpace, "⇧ Space"),
    ])
    func presetDisplayName(shortcut: GlobalShortcut, expected: String) {
        #expect(shortcut.displayName == expected)
    }

    @Test("custom display name includes modifiers and key")
    func customDisplayName() {
        let shortcut = GlobalShortcut.custom(keyCode: 0, modifiers: [.command, .shift])
        #expect(shortcut.displayName == "⇧ ⌘ A")
    }

    // MARK: - Properties

    @Test("isDoubleTap only true for doubleFn")
    func isDoubleTap() {
        #expect(GlobalShortcut.doubleFn.isDoubleTap)
        #expect(!GlobalShortcut.ctrlSpace.isDoubleTap)
        #expect(!GlobalShortcut.custom(keyCode: 49, modifiers: .control).isDoubleTap)
    }

    @Test("keyCode is nil for doubleFn, 49 for space presets", arguments: [
        (GlobalShortcut.doubleFn, nil as UInt16?),
        (.ctrlSpace, 49 as UInt16?),
        (.optionSpace, 49 as UInt16?),
        (.shiftSpace, 49 as UInt16?),
    ])
    func presetKeyCode(shortcut: GlobalShortcut, expected: UInt16?) {
        #expect(shortcut.keyCode == expected)
    }

    @Test("custom keyCode passes through")
    func customKeyCode() {
        #expect(GlobalShortcut.custom(keyCode: 12, modifiers: .command).keyCode == 12)
    }

    @Test("requiredModifiers for presets", arguments: [
        (GlobalShortcut.ctrlSpace, NSEvent.ModifierFlags.control),
        (.optionSpace, NSEvent.ModifierFlags.option),
        (.shiftSpace, NSEvent.ModifierFlags.shift),
    ])
    func presetModifiers(shortcut: GlobalShortcut, expected: NSEvent.ModifierFlags) {
        #expect(shortcut.requiredModifiers == expected)
    }

    // MARK: - Persistence round-trip

    @Test("all presets survive dictionary round-trip", arguments: GlobalShortcut.presets)
    func presetRoundTrip(shortcut: GlobalShortcut) {
        let dict = shortcut.toDictionary()
        let restored = GlobalShortcut.from(dictionary: dict)
        #expect(restored == shortcut)
    }

    @Test("custom shortcut survives dictionary round-trip")
    func customRoundTrip() {
        let original = GlobalShortcut.custom(keyCode: 38, modifiers: [.command, .option])
        let restored = GlobalShortcut.from(dictionary: original.toDictionary())
        #expect(restored == original)
    }

    @Test("from returns nil for unknown type")
    func unknownType() {
        #expect(GlobalShortcut.from(dictionary: ["type": "unknown"]) == nil)
    }

    @Test("from returns nil for empty dictionary")
    func emptyDict() {
        #expect(GlobalShortcut.from(dictionary: [:]) == nil)
    }

    @Test("from returns nil for custom missing fields")
    func customMissingFields() {
        #expect(GlobalShortcut.from(dictionary: ["type": "custom"]) == nil)
        #expect(GlobalShortcut.from(dictionary: ["type": "custom", "keyCode": 1]) == nil)
    }

    // MARK: - Key name helpers

    @Test("keyName for known codes", arguments: [
        (49 as UInt16, "Space"),
        (36 as UInt16, "Return"),
        (0 as UInt16, "A"),
        (53 as UInt16, "Escape"),
    ])
    func knownKeyName(keyCode: UInt16, expected: String) {
        #expect(GlobalShortcut.keyName(for: keyCode) == expected)
    }

    @Test("keyName for unknown code returns fallback")
    func unknownKeyName() {
        #expect(GlobalShortcut.keyName(for: 255) == "Key255")
    }

    // MARK: - Presets

    @Test("presets list has 4 entries")
    func presetsCount() {
        #expect(GlobalShortcut.presets.count == 4)
    }
}
