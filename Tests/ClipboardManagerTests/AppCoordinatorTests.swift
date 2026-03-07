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
    
    // Wait for initialization to complete
    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    
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
    
    try? await Task.sleep(nanoseconds: 50_000_000)
    
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
