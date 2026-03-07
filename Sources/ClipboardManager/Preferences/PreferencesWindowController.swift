import AppKit
import SwiftUI

@MainActor
protocol PreferencesWindowControlling {
    func show(coordinator: AppCoordinator)
    func close()
}

@MainActor
final class PreferencesWindowController: PreferencesWindowControlling {
    private var window: NSWindow?
    private var windowDelegate: WindowDelegate?
    private weak var currentCoordinator: AppCoordinator?
    
    func show(coordinator: AppCoordinator) {
        self.currentCoordinator = coordinator
        
        // If window already exists, just bring it to front
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            // Center after showing
            DispatchQueue.main.async {
                window.center()
            }
            return
        }
        
        // Create the hosting controller
        let hostingController = NSHostingController(
            rootView: PreferencesView(coordinator: coordinator)
        )
        
        // Create the window
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Preferences"
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        
        // Set window delegate to handle closing
        let delegate = WindowDelegate(
            window: newWindow,
            onClose: { [weak self] in
                // Ensure hotkey is re-enabled when window closes
                self?.currentCoordinator?.reEnableHotkey()
                
                self?.window = nil
                self?.windowDelegate = nil
                self?.currentCoordinator = nil
                // Reset activation policy when preferences closes
                _ = NSApp.setActivationPolicy(.accessory)
            },
            onResignKey: { [weak self] in
                // Re-enable hotkey when window loses focus
                self?.currentCoordinator?.reEnableHotkey()
            }
        )
        newWindow.delegate = delegate
        
        self.window = newWindow
        self.windowDelegate = delegate
        
        // Show the window first
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Center after SwiftUI has laid out the content
        DispatchQueue.main.async {
            newWindow.center()
        }
    }
    
    func close() {
        // Ensure hotkey is re-enabled when closing programmatically
        currentCoordinator?.reEnableHotkey()
        
        window?.close()
        window = nil
        windowDelegate = nil
        currentCoordinator = nil
    }
}

private class WindowDelegate: NSObject, NSWindowDelegate {
    weak var window: NSWindow?
    let onClose: () -> Void
    let onResignKey: () -> Void
    
    init(window: NSWindow, onClose: @escaping () -> Void, onResignKey: @escaping () -> Void) {
        self.window = window
        self.onClose = onClose
        self.onResignKey = onResignKey
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Force the first responder to resign (stops recording UI)
        window?.makeFirstResponder(nil)
        onResignKey()
    }
}
