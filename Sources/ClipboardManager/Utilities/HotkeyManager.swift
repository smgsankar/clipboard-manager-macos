import AppKit
import Carbon

@MainActor
protocol HotkeyManaging: AnyObject {
    func register(shortcut: KeyboardShortcut, handler: @escaping @MainActor () -> Void) throws
    func unregister()
}

enum HotkeyError: LocalizedError {
    case invalidShortcut
    case handlerInstallationFailed(OSStatus)
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidShortcut:
            return "Choose a shortcut with at least one modifier key."
        case .handlerInstallationFailed(let status):
            return "Failed to install the global shortcut handler (OSStatus \(status))."
        case .registrationFailed(let status):
            return "Failed to register the global shortcut (OSStatus \(status))."
        }
    }
}

@MainActor
final class HotkeyManager: HotkeyManaging {
    private let hotKeyID = EventHotKeyID(signature: 0x434C4950, id: 1)

    private var registeredHotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (@MainActor () -> Void)?

    func register(shortcut: KeyboardShortcut, handler: @escaping @MainActor () -> Void) throws {
        guard shortcut.isValid else {
            throw HotkeyError.invalidShortcut
        }

        try installEventHandlerIfNeeded()
        unregister()

        callback = handler

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            callback = nil
            throw HotkeyError.registrationFailed(status)
        }

        registeredHotKey = hotKeyRef
    }

    func unregister() {
        if let registeredHotKey {
            UnregisterEventHotKey(registeredHotKey)
        }

        registeredHotKey = nil
        callback = nil
    }

    private func installEventHandlerIfNeeded() throws {
        guard eventHandler == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard
                    let userData,
                    let eventRef
                else {
                    return noErr
                }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleHotKeyEvent(eventRef)
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )

        guard status == noErr else {
            throw HotkeyError.handlerInstallationFailed(status)
        }
    }

    private func handleHotKeyEvent(_ eventRef: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            return status
        }

        guard hotKeyID.id == self.hotKeyID.id, hotKeyID.signature == self.hotKeyID.signature else {
            return noErr
        }

        if let callback {
            Task { @MainActor in
                callback()
            }
        }

        return noErr
    }
}
