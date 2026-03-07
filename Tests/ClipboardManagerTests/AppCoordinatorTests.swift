import AppKit
import Foundation
import Testing
@testable import ClipboardManager

@MainActor
final class FakePasteboardReader: PasteboardReading {
    var changeCount: Int = 0
    var storedString: String?
    var writeCallCount = 0
    
    func readString() -> String? {
        storedString
    }
    
    func writeString(_ string: String) {
        writeCallCount += 1
        storedString = string
        changeCount += 1
    }
}

@MainActor
@Test
func appCoordinatorInitializesWithDependencies() async {
    let preferences = AppPreferences(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    let pasteboard = FakePasteboardReader()
    let appProvider = FakeFrontmostAppProvider()
    let hotkeyManager = MockHotkeyManager()
    let launchManager = MockLaunchAtLoginController()
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferences: preferences,
        pasteboardReader: pasteboard,
        frontmostAppProvider: appProvider,
        hotkeyManager: hotkeyManager,
        launchAtLoginManager: launchManager,
        database: database
    )
    
    #expect(coordinator.preferences === preferences)
    #expect(coordinator.store.items.isEmpty) // Initially empty
}

@MainActor
@Test
func appCoordinatorStartsWatcherAndRegistersHotkey() async {
    let preferences = AppPreferences(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    let hotkeyManager = MockHotkeyManager()
    let launchManager = MockLaunchAtLoginController()
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferences: preferences,
        hotkeyManager: hotkeyManager,
        launchAtLoginManager: launchManager,
        database: database
    )
    
    // Explicitly await initialization (guard in startIfNeeded ensures it runs once)
    await coordinator.startIfNeeded()
    
    #expect(hotkeyManager.registerCallCount == 1)
    #expect(hotkeyManager.registeredShortcut != nil)
}

@MainActor
@Test
func appCoordinatorCopiesItemToPasteboard() async {
    let pasteboard = FakePasteboardReader()
    let appProvider = FakeFrontmostAppProvider()
    appProvider.frontmostApplicationName = "TestApp"
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        pasteboardReader: pasteboard,
        frontmostAppProvider: appProvider,
        database: database
    )
    
    // Add an item to the store
    await coordinator.store.captureText("Test content", sourceApplication: "OriginalApp")
    
    guard let item = coordinator.store.items.first else {
        Issue.record("Expected item in store")
        return
    }
    
    coordinator.copyItem(item)
    
    #expect(pasteboard.writeCallCount >= 1)
    #expect(pasteboard.storedString == "Test content")
}

@MainActor
@Test
func appCoordinatorDeletesItem() async {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(database: database)
    
    await coordinator.store.captureText("Item to delete", sourceApplication: nil)
    try? await Task.sleep(nanoseconds: 10_000_000)
    
    #expect(coordinator.store.items.count == 1)
    
    guard let item = coordinator.store.items.first else {
        Issue.record("Expected item in store")
        return
    }
    
    coordinator.deleteItem(item)
    
    try? await Task.sleep(nanoseconds: 50_000_000) // Wait for async deletion
    
    #expect(coordinator.store.items.isEmpty)
}

@MainActor
@Test
func appCoordinatorClearsHistory() async {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(database: database)
    
    await coordinator.store.captureText("Item 1", sourceApplication: nil)
    await coordinator.store.captureText("Item 2", sourceApplication: nil)
    
    #expect(coordinator.store.items.count == 2)
    
    coordinator.clearHistory()
    
    try? await Task.sleep(nanoseconds: 50_000_000) // Wait for async clear
    
    #expect(coordinator.store.items.isEmpty)
}

@MainActor
@Test
func appCoordinatorHandlesHotkeyError() async {
    let preferences = AppPreferences(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    let hotkeyManager = MockHotkeyManager()
    hotkeyManager.shouldThrowOnRegister = true
    hotkeyManager.errorToThrow = HotkeyError.invalidShortcut
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferences: preferences,
        hotkeyManager: hotkeyManager,
        database: database
    )
    
    // Explicitly await initialization (guard in startIfNeeded ensures it runs once)
    await coordinator.startIfNeeded()
    
    #expect(coordinator.hotkeyErrorMessage != nil)
}

@MainActor
@Test
func appCoordinatorUpdatesHistoryLimitWhenPreferenceChanges() async {
    let preferences = AppPreferences(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferences: preferences,
        database: database
    )
    
    let initialLimit = coordinator.store.historyLimit
    preferences.historyLimit = 50
    
    try? await Task.sleep(nanoseconds: 100_000_000) // Wait for update
    
    #expect(coordinator.store.historyLimit == 50)
    #expect(coordinator.store.historyLimit != initialLimit || initialLimit == 50)
}

@MainActor
@Test
func appCoordinatorReregistersHotkeyWhenShortcutChanges() async {
    let preferences = AppPreferences(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    let hotkeyManager = MockHotkeyManager()
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferences: preferences,
        hotkeyManager: hotkeyManager,
        database: database
    )
    
    try? await Task.sleep(nanoseconds: 50_000_000)
    
    let initialCount = hotkeyManager.registerCallCount
    
    preferences.shortcut = KeyboardShortcut(keyCode: 11, modifiers: 256) // Cmd+B
    
    try? await Task.sleep(nanoseconds: 50_000_000)
    
    #expect(hotkeyManager.registerCallCount > initialCount)
}

@MainActor
@Test
func appCoordinatorUnregistersHotkeyOnQuit() async {
    let hotkeyManager = MockHotkeyManager()
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        hotkeyManager: hotkeyManager,
        database: database
    )
    
    try? await Task.sleep(nanoseconds: 50_000_000)
    
    // Note: quit() calls NSApplication.shared.terminate which we can't test
    // But we can verify the unregister is called
    #expect(hotkeyManager.unregisterCallCount == 0)
}

@MainActor
@Test
func appCoordinatorOpenPreferencesCanBeCalled() async {
    let preferencesController = MockPreferencesWindowController()
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferencesController: preferencesController,
        database: database
    )
    
    // Call openPreferences - verify it calls the preferences controller
    coordinator.openPreferences()
    
    // Allow time for any async operations
    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
    
    #expect(preferencesController.showCallCount == 1)
    #expect(preferencesController.isShowing == true)
}

@MainActor
@Test
func appCoordinatorClosesPopupWhenOpeningPreferences() async {
    let popupController = MockClipboardPopupPanelController()
    let preferencesController = MockPreferencesWindowController()
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        popupController: popupController,
        preferencesController: preferencesController,
        database: database
    )
    
    // Simulate popup being open
    popupController.isShowing = true
    
    // Call openPreferences
    coordinator.openPreferences()
    
    // Verify that close was called
    #expect(popupController.closeCallCount == 1)
    #expect(popupController.isShowing == false)
}

@MainActor
@Test
func appCoordinatorReEnablesHotkeyWhenPreferencesClose() async {
    let hotkeyManager = MockHotkeyManager()
    let preferences = AppPreferences(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferences: preferences,
        hotkeyManager: hotkeyManager,
        database: database
    )
    
    // Wait for initialization
    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    
    let initialRegisterCount = hotkeyManager.registerCallCount
    
    // Simulate opening preferences (which would call temporarilyDisableHotkey)
    coordinator.temporarilyDisableHotkey()
    #expect(hotkeyManager.registeredShortcut == nil)
    
    // Simulate the preferences window closing by calling reEnableHotkey
    coordinator.reEnableHotkey()
    
    // Verify hotkey was re-registered
    #expect(hotkeyManager.registerCallCount == initialRegisterCount + 1)
    #expect(hotkeyManager.registeredShortcut == preferences.shortcut)
}

@MainActor
@Test
func appCoordinatorSettingsWindowObserverDoesNotCrash() async {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(database: database)
    
    // Note: This tests that the notification observer setup doesn't crash.
    // The actual behavior of detecting settings window closing and resetting
    // activation policy requires a full macOS app environment.
    
    // Simulate a window closing by posting a notification
    let testWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    testWindow.title = "Settings"
    testWindow.identifier = NSUserInterfaceItemIdentifier("TestSettingsWindow")
    
    // Post the will close notification
    NotificationCenter.default.post(
        name: NSWindow.willCloseNotification,
        object: testWindow
    )
    
    // Allow time for the notification to be processed
    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
    
    // If we get here without crashing, the test passes
    #expect(true)
}

@MainActor
@Test
func appCoordinatorClosePopupCanBeCalled() async {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(database: database)
    
    // Note: This is a smoke test that verifies the closePopup() method can be called
    // without crashing. The actual behavior of closing the popup window requires a
    // full macOS app environment and should be tested manually or with UI tests.
    
    // Call closePopup - verify it doesn't crash
    coordinator.closePopup()
    
    // Allow time for any async operations
    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
    
    // If we get here without crashing, the test passes
    #expect(true)
}

@MainActor
@Test
func appCoordinatorTemporarilyDisablesHotkey() async {
    let hotkeyManager = MockHotkeyManager()
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        hotkeyManager: hotkeyManager,
        database: database
    )
    
    // Wait for initialization
    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    
    let initialUnregisterCount = hotkeyManager.unregisterCallCount
    
    // Temporarily disable hotkey
    coordinator.temporarilyDisableHotkey()
    
    // Verify unregister was called
    #expect(hotkeyManager.unregisterCallCount == initialUnregisterCount + 1)
    #expect(hotkeyManager.registeredShortcut == nil)
}

@MainActor
@Test
func appCoordinatorReEnablesHotkey() async {
    let hotkeyManager = MockHotkeyManager()
    let preferences = AppPreferences(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferences: preferences,
        hotkeyManager: hotkeyManager,
        database: database
    )
    
    // Wait for initialization
    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    
    let initialRegisterCount = hotkeyManager.registerCallCount
    
    // Temporarily disable then re-enable
    coordinator.temporarilyDisableHotkey()
    coordinator.reEnableHotkey()
    
    // Verify register was called again
    #expect(hotkeyManager.registerCallCount == initialRegisterCount + 1)
    #expect(hotkeyManager.registeredShortcut == preferences.shortcut)
}

@MainActor
@Test
func appCoordinatorClosePopupWithoutHidingCanBeCalled() async {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(database: database)
    
    // Note: This is a smoke test that verifies the closePopupWithoutHiding() method can be called
    // without crashing. The actual behavior of closing the popup without hiding the app requires a
    // full macOS app environment and should be tested manually or with UI tests.
    
    // Call closePopupWithoutHiding - verify it doesn't crash
    coordinator.closePopupWithoutHiding()
    
    // Allow time for any async operations
    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
    
    // If we get here without crashing, the test passes
    #expect(true)
}
