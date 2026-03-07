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
    let store = ClipboardStore(database: database, historyLimit: 100)

    defer {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    await store.captureText("one", sourceApplication: nil)
    await store.captureText("two", sourceApplication: nil)
    await store.captureText("three", sourceApplication: nil)
    await store.updateHistoryLimit(2)

    #expect(store.items.map(\.content) == ["three", "two"])
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
