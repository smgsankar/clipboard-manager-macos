import AppKit
import Carbon
import Foundation
import Testing
@testable import ClipboardManager

@Test
func shortcutIsValidWhenModifiersSet() {
    let validShortcut = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey)
    )
    #expect(validShortcut.isValid)
    
    let invalidShortcut = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: 0
    )
    #expect(!invalidShortcut.isValid)
}

@Test
func shortcutConvertsToEventModifiers() {
    let shortcut = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey) | UInt32(shiftKey)
    )
    
    let flags = shortcut.eventModifiers
    #expect(flags.contains(.command))
    #expect(flags.contains(.shift))
    #expect(!flags.contains(.option))
    #expect(!flags.contains(.control))
}

@Test
func shortcutGeneratesDisplayString() {
    let shortcut = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey) | UInt32(shiftKey)
    )
    
    let display = shortcut.displayString
    #expect(display.contains("⇧"))
    #expect(display.contains("⌘"))
}

@Test
func shortcutGeneratesModifierSymbols() {
    let shortcut1 = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_A),
        modifiers: UInt32(cmdKey)
    )
    #expect(shortcut1.modifierSymbols == "⌘")
    
    let shortcut2 = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_A),
        modifiers: UInt32(controlKey) | UInt32(optionKey) | UInt32(shiftKey) | UInt32(cmdKey)
    )
    #expect(shortcut2.modifierSymbols == "⌃⌥⇧⌘")
}

@Test
func shortcutConvertsCarbonModifiersFromEventFlags() {
    var flags: NSEvent.ModifierFlags = [.command, .shift]
    var carbonMods = KeyboardShortcut.carbonModifiers(from: flags)
    #expect(carbonMods & UInt32(cmdKey) != 0)
    #expect(carbonMods & UInt32(shiftKey) != 0)
    
    flags = [.option, .control]
    carbonMods = KeyboardShortcut.carbonModifiers(from: flags)
    #expect(carbonMods & UInt32(optionKey) != 0)
    #expect(carbonMods & UInt32(controlKey) != 0)
}

@Test
func shortcutEncodesAndDecodesCorrectly() throws {
    let original = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_C),
        modifiers: UInt32(cmdKey) | UInt32(optionKey)
    )
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let data = try encoder.encode(original)
    let decoded = try decoder.decode(KeyboardShortcut.self, from: data)
    
    #expect(decoded == original)
    #expect(decoded.keyCode == original.keyCode)
    #expect(decoded.modifiers == original.modifiers)
}

@Test
func defaultShortcutIsValid() {
    let defaultShortcut = KeyboardShortcut.defaultShortcut
    #expect(defaultShortcut.isValid)
    #expect(defaultShortcut.modifiers & UInt32(cmdKey) != 0)
    #expect(defaultShortcut.modifiers & UInt32(shiftKey) != 0)
}
