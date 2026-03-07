import AppKit
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: KeyboardShortcut

    func makeNSView(context: Context) -> ShortcutCaptureField {
        let field = ShortcutCaptureField()
        field.onShortcutCapture = { capturedShortcut in
            shortcut = capturedShortcut
        }
        field.currentShortcut = shortcut
        return field
    }

    func updateNSView(_ nsView: ShortcutCaptureField, context: Context) {
        nsView.onShortcutCapture = { capturedShortcut in
            shortcut = capturedShortcut
        }
        nsView.currentShortcut = shortcut
    }
}

final class ShortcutCaptureField: NSTextField {
    var onShortcutCapture: ((KeyboardShortcut) -> Void)?

    var currentShortcut: KeyboardShortcut = .defaultShortcut {
        didSet {
            if window?.firstResponder !== self {
                stringValue = currentShortcut.displayString
            }
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    init() {
        super.init(frame: .zero)
        isEditable = false
        isSelectable = false
        isBordered = true
        drawsBackground = true
        alignment = .center
        focusRingType = .default
        font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        stringValue = currentShortcut.displayString
        placeholderString = "Record Shortcut"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        if didBecomeFirstResponder {
            stringValue = "Type Shortcut…"
        }
        return didBecomeFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()
        if didResignFirstResponder {
            stringValue = currentShortcut.displayString
        }
        return didResignFirstResponder
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            _ = window?.makeFirstResponder(nil)
            return
        }

        let modifiers = KeyboardShortcut.carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else {
            NSSound.beep()
            return
        }

        let capturedShortcut = KeyboardShortcut(
            keyCode: UInt32(event.keyCode),
            modifiers: modifiers
        )

        currentShortcut = capturedShortcut
        onShortcutCapture?(capturedShortcut)
        _ = window?.makeFirstResponder(nil)
    }
}
