import Foundation
import Testing
@testable import ClipboardManager

// Mock implementations for testing system integrations

@MainActor
final class MockHotkeyManager: HotkeyManaging {
    var registeredShortcut: KeyboardShortcut?
    var registeredHandler: (@MainActor () -> Void)?
    var registerCallCount = 0
    var unregisterCallCount = 0
    var shouldThrowOnRegister = false
    var errorToThrow: Error?
    
    func register(shortcut: KeyboardShortcut, handler: @escaping @MainActor () -> Void) throws {
        registerCallCount += 1
        
        if shouldThrowOnRegister {
            throw errorToThrow ?? HotkeyError.invalidShortcut
        }
        
        registeredShortcut = shortcut
        registeredHandler = handler
    }
    
    func unregister() {
        unregisterCallCount += 1
        registeredShortcut = nil
        registeredHandler = nil
    }
    
    func simulateHotkeyPress() {
        registeredHandler?()
    }
}

@MainActor
final class MockLaunchAtLoginController: LaunchAtLoginControlling {
    var mockLastErrorMessage: String?
    var mockCurrentStatus = false
    var setEnabledCallCount = 0
    var lastEnabledValue: Bool?
    
    var lastErrorMessage: String? {
        mockLastErrorMessage
    }
    
    func currentStatus() -> Bool {
        mockCurrentStatus
    }
    
    func setEnabled(_ enabled: Bool) {
        setEnabledCallCount += 1
        lastEnabledValue = enabled
        mockCurrentStatus = enabled
    }
}

@MainActor
final class MockClipboardPopupPanelController: ClipboardPopupPanelControlling {
    var isShowing = false
    var showCallCount = 0
    var closeCallCount = 0
    var lastStore: ClipboardStore?
    var lastCoordinator: AppCoordinator?
    
    func show(store: ClipboardStore, coordinator: AppCoordinator) {
        showCallCount += 1
        isShowing = true
        lastStore = store
        lastCoordinator = coordinator
    }
    
    func close(shouldHideApp: Bool) {
        closeCallCount += 1
        isShowing = false
    }
}

// HotkeyManager Tests
@MainActor
@Test
func hotkeyManagerMockRegistersShortcut() throws {
    let manager = MockHotkeyManager()
    let shortcut = KeyboardShortcut(
        keyCode: 9, // V
        modifiers: 256 // Cmd
    )
    
    var handlerCalled = false
    try manager.register(shortcut: shortcut) {
        handlerCalled = true
    }
    
    #expect(manager.registerCallCount == 1)
    #expect(manager.registeredShortcut == shortcut)
    
    manager.simulateHotkeyPress()
    #expect(handlerCalled)
}

@MainActor
@Test
func hotkeyManagerMockUnregisters() throws {
    let manager = MockHotkeyManager()
    let shortcut = KeyboardShortcut(keyCode: 9, modifiers: 256)
    
    try manager.register(shortcut: shortcut) {}
    #expect(manager.registeredShortcut != nil)
    
    manager.unregister()
    #expect(manager.unregisterCallCount == 1)
    #expect(manager.registeredShortcut == nil)
}

@MainActor
@Test
func hotkeyManagerMockThrowsError() {
    let manager = MockHotkeyManager()
    manager.shouldThrowOnRegister = true
    
    let shortcut = KeyboardShortcut(keyCode: 9, modifiers: 256)
    
    #expect(throws: HotkeyError.self) {
        try manager.register(shortcut: shortcut) {}
    }
}

// LaunchAtLoginController Tests
@MainActor
@Test
func launchAtLoginControllerMockSetsEnabled() {
    let controller = MockLaunchAtLoginController()
    
    controller.setEnabled(true)
    
    #expect(controller.setEnabledCallCount == 1)
    #expect(controller.lastEnabledValue == true)
    #expect(controller.currentStatus() == true)
}

@MainActor
@Test
func launchAtLoginControllerMockSetsDisabled() {
    let controller = MockLaunchAtLoginController()
    controller.mockCurrentStatus = true
    
    controller.setEnabled(false)
    
    #expect(controller.setEnabledCallCount == 1)
    #expect(controller.lastEnabledValue == false)
    #expect(controller.currentStatus() == false)
}

@MainActor
@Test
func launchAtLoginControllerMockReturnsError() {
    let controller = MockLaunchAtLoginController()
    controller.mockLastErrorMessage = "Test error"
    
    #expect(controller.lastErrorMessage == "Test error")
}

// PopupPanelController Tests
@MainActor
@Test
func popupPanelControllerMockShowsPanel() async {
    let controller = MockClipboardPopupPanelController()
    let database = ClipboardDatabase(
        databaseURL: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("test.db")
    )
    let store = ClipboardStore(database: database, historyLimit: 100)
    let coordinator = AppCoordinator(database: database)
    
    controller.show(store: store, coordinator: coordinator)
    
    #expect(controller.showCallCount == 1)
    #expect(controller.isShowing)
    #expect(controller.lastStore === store)
}

@MainActor
@Test
func popupPanelControllerMockClosesPanel() {
    let controller = MockClipboardPopupPanelController()
    controller.isShowing = true
    
    controller.close(shouldHideApp: true)
    
    #expect(controller.closeCallCount == 1)
    #expect(!controller.isShowing)
}
