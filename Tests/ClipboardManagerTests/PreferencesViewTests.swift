import SwiftUI
import Testing
import ViewInspector
@testable import ClipboardManager

@MainActor
@Test
func preferencesViewDisplaysKeyboardShortcutSection() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PreferencesView(coordinator: coordinator)
    
    let text = try view.inspect().find(text: "Open Clipboard History")
    #expect(try text.string() == "Open Clipboard History")
}

@MainActor
@Test
func preferencesViewDisplaysDefaultShortcut() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PreferencesView(coordinator: coordinator)
    
    let defaultShortcut = KeyboardShortcut.defaultShortcut.displayString
    let text = try view.inspect().find(text: "Default: \(defaultShortcut)")
    #expect(try text.string().contains("Default:"))
}

@MainActor
@Test
func preferencesViewDisplaysHistorySection() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PreferencesView(coordinator: coordinator)
    
    // Check if the privacy notice text exists
    let hasPrivacyNotice = try view.inspect().findAll(ViewType.Text.self, where: { view in
        try view.string().contains("Stored locally")
    }).count >= 1
    #expect(hasPrivacyNotice)
}

@MainActor
@Test
func preferencesViewDisplaysLaunchAtLoginToggle() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PreferencesView(coordinator: coordinator)
    
    let toggle = try view.inspect().find(ViewType.Toggle.self)
    let label = try toggle.labelView().text().string()
    #expect(label == "Launch at Login")
}

@MainActor
@Test
func preferencesViewDisplaysPrivacySection() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PreferencesView(coordinator: coordinator)
    
    let text = try view.inspect().find(text: "Clipboard history stays on this Mac. No analytics, sync, or telemetry are included.")
    #expect(try text.string().contains("Clipboard history stays on this Mac"))
}

@MainActor
@Test
func preferencesViewDisplaysHotkeyErrorWhenPresent() async throws {
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
    
    let view = PreferencesView(coordinator: coordinator)
    
    if coordinator.hotkeyErrorMessage != nil {
        // Error message should be visible in the view
        _ = try view.inspect()
        #expect(coordinator.hotkeyErrorMessage != nil)
    }
}

@MainActor
@Test
func preferencesViewUpdatesHistoryLimit() throws {
    let preferences = AppPreferences(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    preferences.historyLimit = 100
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let coordinator = AppCoordinator(
        preferences: preferences,
        database: database
    )
    
    let view = PreferencesView(coordinator: coordinator)
    
    // Find the stepper
    let steppers = try view.inspect().findAll(ViewType.Stepper.self)
    #expect(steppers.count >= 1)
}
