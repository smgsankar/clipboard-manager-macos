import AppKit
import Carbon

struct KeyboardShortcut: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultShortcut = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey) | UInt32(shiftKey)
    )

    var isValid: Bool {
        modifiers != 0
    }

    var eventModifiers: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers & UInt32(cmdKey) != 0 {
            flags.insert(.command)
        }
        if modifiers & UInt32(shiftKey) != 0 {
            flags.insert(.shift)
        }
        if modifiers & UInt32(optionKey) != 0 {
            flags.insert(.option)
        }
        if modifiers & UInt32(controlKey) != 0 {
            flags.insert(.control)
        }
        return flags
    }

    var displayString: String {
        modifierSymbols + Self.keyDisplayString(for: keyCode)
    }

    var modifierSymbols: String {
        var symbols = ""
        if modifiers & UInt32(controlKey) != 0 {
            symbols += "⌃"
        }
        if modifiers & UInt32(optionKey) != 0 {
            symbols += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            symbols += "⇧"
        }
        if modifiers & UInt32(cmdKey) != 0 {
            symbols += "⌘"
        }
        return symbols
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        let filtered = flags.intersection(.deviceIndependentFlagsMask)

        var modifiers: UInt32 = 0
        if filtered.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if filtered.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }
        if filtered.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if filtered.contains(.control) {
            modifiers |= UInt32(controlKey)
        }

        return modifiers
    }

    private static func keyDisplayString(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Delete: return "Delete"
        case kVK_Escape: return "Escape"
        default:
            return "Key \(keyCode)"
        }
    }
}
