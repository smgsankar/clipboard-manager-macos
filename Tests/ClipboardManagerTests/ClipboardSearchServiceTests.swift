import Foundation
import Testing
@testable import ClipboardManager

@Test
func searchIsCaseInsensitiveSubstringMatch() {
    let service = ClipboardSearchService()
    let items = [
        ClipboardItem(id: UUID(), content: "docker ps", timestamp: .now, sourceApplication: nil),
        ClipboardItem(id: UUID(), content: "docker compose", timestamp: .now, sourceApplication: nil),
        ClipboardItem(id: UUID(), content: "notes", timestamp: .now, sourceApplication: nil)
    ]

    let matches = service.search(query: "DOCK", in: items)

    #expect(matches.map(\.content) == ["docker ps", "docker compose"])
}

@Test
func emptySearchReturnsAllItems() {
    let service = ClipboardSearchService()
    let items = [
        ClipboardItem(id: UUID(), content: "alpha", timestamp: .now, sourceApplication: nil),
        ClipboardItem(id: UUID(), content: "beta", timestamp: .now, sourceApplication: nil)
    ]

    #expect(service.search(query: "   ", in: items) == items)
}
