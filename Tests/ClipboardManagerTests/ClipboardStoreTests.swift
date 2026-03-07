import Foundation
import Testing
@testable import ClipboardManager

@MainActor
@Test
func storePrunesItemsWhenHistoryLimitShrinks() async {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)
    let store = ClipboardStore(database: database, historyLimit: 50)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // Add 20 items with a small delay to ensure distinct timestamps
    for i in 1...20 {
        await store.captureText("item\(i)", sourceApplication: nil)
        // Small delay to ensure timestamps are different
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
    }
    
    #expect(store.items.count == 20)
    #expect(store.items.first?.content == "item20", "Most recent item should be item20")
    
    // Shrink limit to 10 (minimum valid)
    await store.updateHistoryLimit(10)
    
    // Should now have only 10 items (the newest ones)
    #expect(store.items.count == 10, "Should have exactly 10 items after pruning")
    #expect(store.items.first?.content == "item20", "Most recent should still be item20")
    #expect(store.items.last?.content == "item11", "Oldest kept should be item11")
}

@MainActor
@Test
func storeDeleteAndClearHistoryStayInSync() async {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    await store.captureText("one", sourceApplication: nil)
    await store.captureText("two", sourceApplication: nil)

    guard let firstItem = store.items.first else {
        Issue.record("Expected stored items.")
        return
    }

    await store.deleteItem(firstItem)
    #expect(store.items.map(\.content) == ["one"])

    await store.clearHistory()
    #expect(store.items.isEmpty)
}

@MainActor
@Test
func storeLoadRefreshesItemsFromDatabase() async {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    await store.captureText("first", sourceApplication: nil)
    await store.captureText("second", sourceApplication: nil)
    
    #expect(store.items.count == 2)
    
    await store.load()
    #expect(store.items.count == 2)
    #expect(store.items.first?.content == "second")
}

@MainActor
@Test
func storeRecentItemsReturnsLimitedItems() async {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    for i in 1...10 {
        await store.captureText("item\(i)", sourceApplication: nil)
        try? await Task.sleep(nanoseconds: 1_000_000)
    }
    
    let recent = store.recentItems(limit: 3)
    #expect(recent.count == 3)
    #expect(recent.map(\.content) == ["item10", "item9", "item8"])
}

@MainActor
@Test
func storeSearchItemsFiltersContent() async {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    await store.captureText("apple pie", sourceApplication: nil)
    await store.captureText("banana bread", sourceApplication: nil)
    await store.captureText("apple juice", sourceApplication: nil)
    
    let searchResults = store.searchItems(query: "apple")
    #expect(searchResults.count == 2)
    #expect(searchResults.allSatisfy { $0.content.contains("apple") })
}

@MainActor
@Test
func storeReuseItemCapturesContentAgain() async {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    await store.captureText("first", sourceApplication: "App1")
    try? await Task.sleep(nanoseconds: 10_000_000)
    await store.captureText("second", sourceApplication: "App2")
    
    guard let oldItem = store.items.last else {
        Issue.record("Expected stored items.")
        return
    }
    
    #expect(oldItem.content == "first")
    
    try? await Task.sleep(nanoseconds: 10_000_000)
    await store.reuseItem(oldItem, sourceApplication: "App3")
    
    // The reused item should now be at the top with updated timestamp
    #expect(store.items.first?.content == "first")
    #expect(store.items.count == 2)
}

@MainActor
@Test
func storeHandlesCaptureErrorGracefully() async {
    // Create a database with an invalid path to trigger errors
    let invalidURL = URL(fileURLWithPath: "/dev/null/impossible.db")
    let database = ClipboardDatabase(databaseURL: invalidURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    // Capture should fail but not crash
    await store.captureText("test", sourceApplication: nil)
    
    // Error message should be set
    #expect(store.lastErrorMessage != nil)
    #expect(store.lastErrorMessage?.contains("Unable to save clipboard history") == true)
}

@MainActor
@Test
func storeHandlesDeleteErrorGracefully() async {
    let invalidURL = URL(fileURLWithPath: "/dev/null/impossible.db")
    let database = ClipboardDatabase(databaseURL: invalidURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    let dummyItem = ClipboardItem(
        id: UUID(),
        content: "test",
        timestamp: Date(),
        sourceApplication: nil
    )
    
    // Delete should fail but not crash
    await store.deleteItem(dummyItem)
    
    // Error message should be set
    #expect(store.lastErrorMessage != nil)
    #expect(store.lastErrorMessage?.contains("Unable to delete clipboard item") == true)
}

@MainActor
@Test
func storeHandlesClearHistoryErrorGracefully() async {
    let invalidURL = URL(fileURLWithPath: "/dev/null/impossible.db")
    let database = ClipboardDatabase(databaseURL: invalidURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    // Clear should fail but not crash
    await store.clearHistory()
    
    // Error message should be set
    #expect(store.lastErrorMessage != nil)
    #expect(store.lastErrorMessage?.contains("Unable to clear clipboard history") == true)
}

@MainActor
@Test
func storeHandlesUpdateHistoryLimitErrorGracefully() async {
    let invalidURL = URL(fileURLWithPath: "/dev/null/impossible.db")
    let database = ClipboardDatabase(databaseURL: invalidURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    // Update should fail but not crash
    await store.updateHistoryLimit(50)
    
    // Error message should be set
    #expect(store.lastErrorMessage != nil)
    #expect(store.lastErrorMessage?.contains("Unable to apply the new history limit") == true)
}

@MainActor
@Test
func storeHandlesLoadErrorGracefully() async {
    let invalidURL = URL(fileURLWithPath: "/dev/null/impossible.db")
    let database = ClipboardDatabase(databaseURL: invalidURL)
    let store = ClipboardStore(database: database, historyLimit: 100)

    // Load should fail but not crash
    await store.load()
    
    // Error message should be set
    #expect(store.lastErrorMessage != nil)
    #expect(store.lastErrorMessage?.contains("Unable to load clipboard history") == true)
}
