import AppKit
import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    let preferences: AppPreferences
    let store: ClipboardStore

    @Published private(set) var hotkeyErrorMessage: String?
    @Published private(set) var launchAtLoginErrorMessage: String?

    private let pasteboardReader: PasteboardReading
    private let frontmostAppProvider: FrontmostAppProviding
    private let popupController: ClipboardPopupPanelControlling
    private let preferencesController: PreferencesWindowControlling
    private let hotkeyManager: HotkeyManaging
    private let launchAtLoginManager: LaunchAtLoginControlling
    private let watcher: ClipboardWatcher

    private var cancellables: Set<AnyCancellable> = []
    private var hasStarted = false

    init(
        preferences: AppPreferences = AppPreferences(),
        pasteboardReader: PasteboardReading = PasteboardReader(),
        frontmostAppProvider: FrontmostAppProviding = FrontmostAppProvider(),
        popupController: ClipboardPopupPanelControlling = ClipboardPopupPanelController(),
        preferencesController: PreferencesWindowControlling = PreferencesWindowController(),
        hotkeyManager: HotkeyManaging = HotkeyManager(),
        launchAtLoginManager: LaunchAtLoginControlling = LaunchAtLoginManager(),
        database: ClipboardDatabase = ClipboardDatabase()
    ) {
        self.preferences = preferences
        self.pasteboardReader = pasteboardReader
        self.frontmostAppProvider = frontmostAppProvider
        self.popupController = popupController
        self.preferencesController = preferencesController
        self.hotkeyManager = hotkeyManager
        self.launchAtLoginManager = launchAtLoginManager
        store = ClipboardStore(
            database: database,
            historyLimit: preferences.historyLimit
        )
        watcher = ClipboardWatcher(
            pasteboard: pasteboardReader,
            frontmostAppProvider: frontmostAppProvider
        ) { [weak store] content, sourceApplication in
            guard let store else {
                return
            }

            Task { @MainActor in
                await store.captureText(content, sourceApplication: sourceApplication)
            }
        }

        configureBindings()
        setupSettingsWindowObserver()

        Task { @MainActor in
            await startIfNeeded()
        }
    }

    func startIfNeeded() async {
        guard !hasStarted else {
            return
        }

        hasStarted = true

        await store.load()
        watcher.start()
        applyHotkey(preferences.shortcut)
        applyLaunchAtLogin(preferences.launchAtLoginEnabled)
    }

    func showPopup() {
        popupController.show(store: store, coordinator: self)
    }

    func closePopup() {
        popupController.close(shouldHideApp: true)
    }
    
    func closePopupWithoutHiding() {
        popupController.close(shouldHideApp: false)
    }

    func openPreferences() {
        // Close the clipboard history popup if it's open, but don't hide the app
        closePopupWithoutHiding()
        
        // Ensure NSApplication is available
        guard NSApplication.shared as NSApplication? != nil else {
            AppLogger.warning("NSApplication not available - cannot open preferences")
            return
        }
        
        // Temporarily change activation policy to allow preferences window
        _ = NSApp.setActivationPolicy(.regular)
        
        // Show the preferences window
        preferencesController.show(coordinator: self)
    }

    func copyItem(_ item: ClipboardItem) {
        pasteboardReader.writeString(item.content)

        Task { @MainActor in
            await store.reuseItem(
                item,
                sourceApplication: frontmostAppProvider.frontmostApplicationName
            )
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        Task { @MainActor in
            await store.deleteItem(item)
        }
    }

    func clearHistory() {
        Task { @MainActor in
            await store.clearHistory()
        }
    }

    func quit() {
        watcher.stop()
        hotkeyManager.unregister()
        NSApplication.shared.terminate(nil)
    }

    func temporarilyDisableHotkey() {
        hotkeyManager.unregister()
    }

    func reEnableHotkey() {
        applyHotkey(preferences.shortcut)
    }

    private func configureBindings() {
        preferences.$historyLimit
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] historyLimit in
                guard let self else {
                    return
                }

                Task { @MainActor in
                    await store.updateHistoryLimit(historyLimit)
                }
            }
            .store(in: &cancellables)

        preferences.$shortcut
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] shortcut in
                self?.applyHotkey(shortcut)
            }
            .store(in: &cancellables)

        preferences.$launchAtLoginEnabled
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isEnabled in
                self?.applyLaunchAtLogin(isEnabled)
            }
            .store(in: &cancellables)
    }

    private func applyHotkey(_ shortcut: KeyboardShortcut) {
        do {
            try hotkeyManager.register(shortcut: shortcut) { [weak self] in
                self?.showPopup()
            }
            hotkeyErrorMessage = nil
        } catch {
            hotkeyErrorMessage = error.localizedDescription
            AppLogger.error("Unable to register the global shortcut.", error: error)
        }
    }

    private func applyLaunchAtLogin(_ isEnabled: Bool) {
        launchAtLoginManager.setEnabled(isEnabled)
        launchAtLoginErrorMessage = launchAtLoginManager.lastErrorMessage
    }
    
    private func setupSettingsWindowObserver() {
        // Monitor for settings windows closing to reset activation policy
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            
            // Check if this is the settings window
            Task { @MainActor in
                guard let app = NSApplication.shared as NSApplication? else { return }
                
                if window.identifier?.rawValue.contains("Settings") == true ||
                   window.title == "Settings" ||
                   window.title == "Preferences" {
                    // Reset to accessory when settings window closes
                    _ = app.setActivationPolicy(.accessory)
                    self?.objectWillChange.send()
                }
            }
        }
    }
}
