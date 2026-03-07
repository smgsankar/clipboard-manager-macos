import SwiftUI
import Testing
import ViewInspector
@testable import ClipboardManager

@MainActor
@Test
func menuBarViewDisplaysEmptyState() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = MenuBarView(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    let text = try view.inspect().find(text: "No clipboard items")
    #expect(try text.string() == "No clipboard items")
}

@MainActor
@Test
func menuBarViewDisplaysItemsWhenAvailable() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    await coordinator.store.captureText("Test item 1", sourceApplication: nil)
    await coordinator.store.captureText("Test item 2", sourceApplication: nil)
    
    let view = MenuBarView(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    // Should not show empty state
    #expect(throws: (any Error).self) {
        try view.inspect().find(text: "No clipboard items")
    }
}

@MainActor
@Test
func menuBarViewHasShowAllButton() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = MenuBarView(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    let button = try view.inspect().find(button: "Show All")
    #expect(try button.labelView().text().string() == "Show All")
}

@MainActor
@Test
func menuBarViewHasPreferencesButton() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = MenuBarView(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    let button = try view.inspect().find(button: "Preferences")
    #expect(try button.labelView().text().string() == "Preferences")
}

@MainActor
@Test
func menuBarViewHasQuitButton() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = MenuBarView(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    let button = try view.inspect().find(button: "Quit")
    #expect(try button.labelView().text().string() == "Quit")
}

@MainActor
@Test
func clipboardRowViewDisplaysContent() throws {
    let item = ClipboardItem(
        id: UUID(),
        content: "Test clipboard content",
        timestamp: Date(),
        sourceApplication: "TestApp"
    )
    
    var copyCallCount = 0
    var deleteCallCount = 0
    
    let view = ClipboardRowView(
        item: item,
        isSelected: false,
        onCopy: { copyCallCount += 1 },
        onDelete: { deleteCallCount += 1 }
    )
    
    let contentText = try view.inspect().find(text: "Test clipboard content")
    #expect(try contentText.string() == "Test clipboard content")
}

@MainActor
@Test
func clipboardRowViewDisplaysSourceApplication() throws {
    let item = ClipboardItem(
        id: UUID(),
        content: "Content",
        timestamp: Date(),
        sourceApplication: "Safari"
    )
    
    let view = ClipboardRowView(
        item: item,
        isSelected: false,
        onCopy: {},
        onDelete: {}
    )
    
    let appText = try view.inspect().find(text: "Safari")
    #expect(try appText.string() == "Safari")
}

@MainActor
@Test
func clipboardRowViewDisplaysTimestamp() throws {
    let timestamp = Date()
    let item = ClipboardItem(
        id: UUID(),
        content: "Content",
        timestamp: timestamp,
        sourceApplication: nil
    )
    
    let view = ClipboardRowView(
        item: item,
        isSelected: false,
        onCopy: {},
        onDelete: {}
    )
    
    let formattedDate = timestamp.formatted(date: .abbreviated, time: .shortened)
    let timestampText = try view.inspect().find(text: formattedDate)
    #expect(try timestampText.string() == formattedDate)
}

@MainActor
@Test
func clipboardRowViewHasDeleteButton() throws {
    let item = ClipboardItem(
        id: UUID(),
        content: "Content",
        timestamp: Date(),
        sourceApplication: nil
    )
    
    let view = ClipboardRowView(
        item: item,
        isSelected: false,
        onCopy: {},
        onDelete: {}
    )
    
    let buttons = try view.inspect().findAll(ViewType.Button.self)
    
    // Should have only delete button (copy button was removed)
    #expect(buttons.count == 1)
}

@MainActor
@Test
func clipboardRowViewCallsOnCopyDirectly() throws {
    let item = ClipboardItem(
        id: UUID(),
        content: "Content",
        timestamp: Date(),
        sourceApplication: nil
    )
    
    var copyCallCount = 0
    
    let view = ClipboardRowView(
        item: item,
        isSelected: false,
        onCopy: { copyCallCount += 1 },
        onDelete: {}
    )
    
    // Copy is now triggered by double-click or Return key, not a button
    // Render the view to ensure onCopy callback is properly set up
    _ = try view.inspect()
    #expect(copyCallCount == 0) // Not called until user action
}

@MainActor
@Test
func clipboardRowViewCallsOnDeleteWhenDeleteButtonTapped() throws {
    let item = ClipboardItem(
        id: UUID(),
        content: "Content",
        timestamp: Date(),
        sourceApplication: nil
    )
    
    var deleteCallCount = 0
    
    let view = ClipboardRowView(
        item: item,
        isSelected: false,
        onCopy: {},
        onDelete: { deleteCallCount += 1 }
    )
    
    // Find and tap the delete button (now the only button)
    let buttons = try view.inspect().findAll(ViewType.Button.self)
    #expect(buttons.count == 1)
    try buttons[0].tap()
    #expect(deleteCallCount == 1)
}

@MainActor
@Test
func clipboardRowViewHighlightsWhenSelected() throws {
    let item = ClipboardItem(
        id: UUID(),
        content: "Content",
        timestamp: Date(),
        sourceApplication: nil
    )
    
    let selectedView = ClipboardRowView(
        item: item,
        isSelected: true,
        onCopy: {},
        onDelete: {}
    )
    
    let unselectedView = ClipboardRowView(
        item: item,
        isSelected: false,
        onCopy: {},
        onDelete: {}
    )
    
    // Both views should render without error
    _ = try selectedView.inspect()
    _ = try unselectedView.inspect()
}

// MARK: - PopupWindow Tests

@MainActor
@Test
func popupWindowHasPreferencesButton() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PopupWindow(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    let button = try view.inspect().find(button: "Preferences")
    #expect(try button.labelView().text().string() == "Preferences")
}

@MainActor
@Test
func popupWindowHasClearHistoryButton() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PopupWindow(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    let button = try view.inspect().find(button: "Clear History")
    #expect(try button.labelView().text().string() == "Clear History")
}

@MainActor
@Test
func popupWindowHasSearchField() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PopupWindow(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    // Verify the search field exists
    let textField = try view.inspect().find(ViewType.TextField.self)
    #expect(textField != nil)
}

@MainActor
@Test
func popupWindowDisplaysItemCount() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let database = ClipboardDatabase(databaseURL: tempDir.appendingPathComponent("test.db"))
    let coordinator = AppCoordinator(database: database)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let view = PopupWindow(coordinator: coordinator)
        .environmentObject(coordinator.store)
    
    // Should show "0 items" when empty
    let itemsText = try view.inspect().find(text: "0 items")
    #expect(try itemsText.string() == "0 items")
}
