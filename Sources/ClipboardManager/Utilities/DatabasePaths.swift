import Foundation

enum DatabasePaths {
    static let applicationSupportDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/ClipboardManager", isDirectory: true)

    static let databaseURL = applicationSupportDirectory.appendingPathComponent("clipboard.db", isDirectory: false)
}
