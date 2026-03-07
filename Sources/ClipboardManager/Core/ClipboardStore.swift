import Foundation

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var lastErrorMessage: String?

    private let database: ClipboardDatabase
    private let searchService: ClipboardSearchService

    private(set) var historyLimit: Int

    init(
        database: ClipboardDatabase,
        searchService: ClipboardSearchService = ClipboardSearchService(),
        historyLimit: Int
    ) {
        self.database = database
        self.searchService = searchService
        self.historyLimit = AppPreferences.clampHistoryLimit(historyLimit)
    }

    func load() async {
        await reloadFromDatabase()
    }

    func recentItems(limit: Int = 7) -> [ClipboardItem] {
        Array(items.prefix(limit))
    }

    func searchItems(query: String) -> [ClipboardItem] {
        searchService.search(query: query, in: items)
    }

    func captureText(_ content: String, sourceApplication: String?) async {
        do {
            _ = try await database.upsert(
                content: content,
                timestamp: Date(),
                sourceApplication: sourceApplication,
                historyLimit: historyLimit
            )
            await reloadFromDatabase()
        } catch {
            handle(error, message: "Unable to save clipboard history.")
        }
    }

    func reuseItem(_ item: ClipboardItem, sourceApplication: String?) async {
        await captureText(item.content, sourceApplication: sourceApplication)
    }

    func deleteItem(_ item: ClipboardItem) async {
        do {
            try await database.delete(id: item.id)
            await reloadFromDatabase()
        } catch {
            handle(error, message: "Unable to delete clipboard item.")
        }
    }

    func clearHistory() async {
        do {
            try await database.clearHistory()
            items = []
            lastErrorMessage = nil
        } catch {
            handle(error, message: "Unable to clear clipboard history.")
        }
    }

    func updateHistoryLimit(_ historyLimit: Int) async {
        self.historyLimit = AppPreferences.clampHistoryLimit(historyLimit)

        do {
            try await database.prune(to: self.historyLimit)
            await reloadFromDatabase()
        } catch {
            handle(error, message: "Unable to apply the new history limit.")
        }
    }

    private func reloadFromDatabase() async {
        do {
            items = try await database.loadItems(limit: historyLimit)
            lastErrorMessage = nil
        } catch {
            handle(error, message: "Unable to load clipboard history.")
        }
    }

    private func handle(_ error: Error, message: String) {
        lastErrorMessage = message
        AppLogger.error(message, error: error)
    }
}
