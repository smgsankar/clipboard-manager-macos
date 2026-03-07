import AppKit
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: KeyboardShortcut
    var onRecordingStarted: (() -> Void)?
    var onRecordingEnded: (() -> Void)?

    func makeNSView(context: Context) -> ShortcutCaptureField {
        let field = ShortcutCaptureField()
        field.onShortcutCapture = { capturedShortcut in
            shortcut = capturedShortcut
        }
        field.onRecordingStarted = onRecordingStarted
        field.onRecordingEnded = onRecordingEnded
        field.currentShortcut = shortcut
        return field
    }

    func updateNSView(_ nsView: ShortcutCaptureField, context: Context) {
        nsView.onShortcutCapture = { capturedShortcut in
            shortcut = capturedShortcut
        }
        nsView.onRecordingStarted = onRecordingStarted
        nsView.onRecordingEnded = onRecordingEnded
        nsView.currentShortcut = shortcut
    }
}

final class ShortcutCaptureField: NSTextField {
    var onShortcutCapture: ((KeyboardShortcut) -> Void)?
    var onRecordingStarted: (() -> Void)?
    var onRecordingEnded: (() -> Void)?

    private var isRecording = false

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
            isRecording = true
            stringValue = "Type Shortcut…"
            onRecordingStarted?()
        }
        return didBecomeFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()
        if didResignFirstResponder {
            isRecording = false
            stringValue = currentShortcut.displayString
            onRecordingEnded?()
        }
        return didResignFirstResponder
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        
        // If we're being removed from window while recording, clean up
        if newWindow == nil && isRecording {
            isRecording = false
            onRecordingEnded?()
        }
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
