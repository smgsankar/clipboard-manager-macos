import Foundation
import Testing
@testable import ClipboardManager

@Test
func clipboardItemCanBeCreated() {
    let id = UUID()
    let timestamp = Date()
    
    let item = ClipboardItem(
        id: id,
        content: "Test content",
        timestamp: timestamp,
        sourceApplication: "TestApp"
    )
    
    #expect(item.id == id)
    #expect(item.content == "Test content")
    #expect(item.timestamp == timestamp)
    #expect(item.sourceApplication == "TestApp")
}

@Test
func clipboardItemSupportsNilSourceApplication() {
    let item = ClipboardItem(
        id: UUID(),
        content: "Test",
        timestamp: Date(),
        sourceApplication: nil
    )
    
    #expect(item.sourceApplication == nil)
}

@Test
func clipboardItemsAreEquatable() {
    let id = UUID()
    let timestamp = Date()
    
    let item1 = ClipboardItem(
        id: id,
        content: "Same",
        timestamp: timestamp,
        sourceApplication: "App"
    )
    
    let item2 = ClipboardItem(
        id: id,
        content: "Same",
        timestamp: timestamp,
        sourceApplication: "App"
    )
    
    #expect(item1 == item2)
    
    let differentItem = ClipboardItem(
        id: UUID(),
        content: "Different",
        timestamp: timestamp,
        sourceApplication: "App"
    )
    
    #expect(item1 != differentItem)
}

@Test
func clipboardItemsAreHashable() {
    let item = ClipboardItem(
        id: UUID(),
        content: "Test",
        timestamp: Date(),
        sourceApplication: nil
    )
    
    var set = Set<ClipboardItem>()
    set.insert(item)
    
    #expect(set.contains(item))
    #expect(set.count == 1)
}

@Test
func clipboardItemEncodesAndDecodesCorrectly() throws {
    let original = ClipboardItem(
        id: UUID(),
        content: "Test content",
        timestamp: Date(),
        sourceApplication: "TestApp"
    )
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let data = try encoder.encode(original)
    let decoded = try decoder.decode(ClipboardItem.self, from: data)
    
    #expect(decoded.id == original.id)
    #expect(decoded.content == original.content)
    #expect(decoded.timestamp.timeIntervalSince1970 == original.timestamp.timeIntervalSince1970)
    #expect(decoded.sourceApplication == original.sourceApplication)
}

@Test
func clipboardItemHandlesEmptyContent() {
    let item = ClipboardItem(
        id: UUID(),
        content: "",
        timestamp: Date(),
        sourceApplication: nil
    )
    
    #expect(item.content.isEmpty)
}

@Test
func clipboardItemHandlesLongContent() {
    let longContent = String(repeating: "x", count: 10_000)
    let item = ClipboardItem(
        id: UUID(),
        content: longContent,
        timestamp: Date(),
        sourceApplication: nil
    )
    
    #expect(item.content.count == 10_000)
}
