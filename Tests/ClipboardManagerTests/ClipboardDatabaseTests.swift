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
