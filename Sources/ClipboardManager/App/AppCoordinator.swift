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
    private let popupController: ClipboardPopupPanelController
    private let hotkeyManager: HotkeyManaging
    private let launchAtLoginManager: LaunchAtLoginControlling
    private let watcher: ClipboardWatcher

    private var cancellables: Set<AnyCancellable> = []
    private var hasStarted = false

    init(
        preferences: AppPreferences = AppPreferences(),
        pasteboardReader: PasteboardReading = PasteboardReader(),
        frontmostAppProvider: FrontmostAppProviding = FrontmostAppProvider(),
        popupController: ClipboardPopupPanelController = ClipboardPopupPanelController(),
        hotkeyManager: HotkeyManaging = HotkeyManager(),
        launchAtLoginManager: LaunchAtLoginControlling = LaunchAtLoginManager(),
        database: ClipboardDatabase = ClipboardDatabase()
    ) {
        self.preferences = preferences
        self.pasteboardReader = pasteboardReader
        self.frontmostAppProvider = frontmostAppProvider
        self.popupController = popupController
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
        popupController.close()
    }

    func openPreferences() {
        NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
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
}
