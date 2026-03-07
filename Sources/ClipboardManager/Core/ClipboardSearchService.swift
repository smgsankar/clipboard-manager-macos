import Foundation

struct ClipboardSearchService {
    func search(query: String, in items: [ClipboardItem]) -> [ClipboardItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return items
        }

        return items.filter { item in
            item.content.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}
