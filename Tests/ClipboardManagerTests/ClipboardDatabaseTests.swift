import Foundation
import Testing
@testable import ClipboardManager

@Test
func upsertDeduplicatesContentAndUpdatesTimestamp() async throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    let firstTimestamp = Date(timeIntervalSince1970: 100)
    let secondTimestamp = Date(timeIntervalSince1970: 200)

    let firstItem = try await database.upsert(
        content: "duplicate",
        timestamp: firstTimestamp,
        sourceApplication: "Notes",
        historyLimit: 100
    )

    let secondItem = try await database.upsert(
        content: "duplicate",
        timestamp: secondTimestamp,
        sourceApplication: "Safari",
        historyLimit: 100
    )

    let items = try await database.loadItems()

    #expect(items.count == 1)
    #expect(firstItem.id == secondItem.id)
    #expect(items.first?.timestamp == secondTimestamp)
    #expect(items.first?.sourceApplication == "Safari")
}

@Test
func pruneRetainsNewestItemsWithinLimit() async throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    for index in 0..<5 {
        _ = try await database.upsert(
            content: "item-\(index)",
            timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
            sourceApplication: nil,
            historyLimit: 3
        )
    }

    let items = try await database.loadItems()

    #expect(items.map(\.content) == ["item-4", "item-3", "item-2"])
}

@Test
func databaseLoadsItemsWithLimit() async throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    for index in 0..<10 {
        _ = try await database.upsert(
            content: "item-\(index)",
            timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
            sourceApplication: nil,
            historyLimit: 100
        )
    }

    let limitedItems = try await database.loadItems(limit: 3)
    #expect(limitedItems.count == 3)
    #expect(limitedItems.first?.content == "item-9")
    
    let allItems = try await database.loadItems()
    #expect(allItems.count == 10)
}

@Test
func databaseSearchFindsMatchingItems() async throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    _ = try await database.upsert(
        content: "apple pie recipe",
        timestamp: Date(timeIntervalSince1970: 1),
        sourceApplication: nil,
        historyLimit: 100
    )
    
    _ = try await database.upsert(
        content: "banana smoothie",
        timestamp: Date(timeIntervalSince1970: 2),
        sourceApplication: nil,
        historyLimit: 100
    )
    
    _ = try await database.upsert(
        content: "apple juice",
        timestamp: Date(timeIntervalSince1970: 3),
        sourceApplication: nil,
        historyLimit: 100
    )

    let searchResults = try await database.searchItems(query: "apple")
    #expect(searchResults.count == 2)
    #expect(searchResults.allSatisfy { $0.content.contains("apple") })
    
    let limitedSearch = try await database.searchItems(query: "apple", limit: 1)
    #expect(limitedSearch.count == 1)
}

@Test
func databaseDeleteRemovesSpecificItem() async throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    let item1 = try await database.upsert(
        content: "keep this",
        timestamp: Date(timeIntervalSince1970: 1),
        sourceApplication: nil,
        historyLimit: 100
    )
    
    let item2 = try await database.upsert(
        content: "delete this",
        timestamp: Date(timeIntervalSince1970: 2),
        sourceApplication: nil,
        historyLimit: 100
    )
    
    try await database.delete(id: item2.id)
    
    let items = try await database.loadItems()
    #expect(items.count == 1)
    #expect(items.first?.id == item1.id)
}

@Test
func databaseClearHistoryRemovesAllItems() async throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    for index in 0..<5 {
        _ = try await database.upsert(
            content: "item-\(index)",
            timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
            sourceApplication: nil,
            historyLimit: 100
        )
    }
    
    let beforeClear = try await database.loadItems()
    #expect(beforeClear.count == 5)
    
    try await database.clearHistory()
    
    let afterClear = try await database.loadItems()
    #expect(afterClear.isEmpty)
}

@Test
func databasePruneReducesItemCount() async throws {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let databaseURL = tempDirectory.appendingPathComponent("clipboard.db")
    let database = ClipboardDatabase(databaseURL: databaseURL)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    for index in 0..<20 {
        _ = try await database.upsert(
            content: "item-\(index)",
            timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
            sourceApplication: nil,
            historyLimit: 100
        )
    }
    
    let beforePrune = try await database.loadItems()
    #expect(beforePrune.count == 20)
    
    try await database.prune(to: 10)
    
    let afterPrune = try await database.loadItems()
    #expect(afterPrune.count == 10)
    #expect(afterPrune.first?.content == "item-19")
}

