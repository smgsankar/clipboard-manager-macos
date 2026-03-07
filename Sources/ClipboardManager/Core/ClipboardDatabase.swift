import Foundation
import SQLite3

actor ClipboardDatabase {
    enum DatabaseError: LocalizedError {
        case openFailed(String)
        case prepareFailed(String)
        case bindFailed(String)
        case executionFailed(String)
        case rowNotFound

        var errorDescription: String? {
            switch self {
            case .openFailed(let message):
                return "Failed to open clipboard database: \(message)"
            case .prepareFailed(let message):
                return "Failed to prepare clipboard database statement: \(message)"
            case .bindFailed(let message):
                return "Failed to bind clipboard database value: \(message)"
            case .executionFailed(let message):
                return "Failed to execute clipboard database statement: \(message)"
            case .rowNotFound:
                return "Requested clipboard item was not found."
            }
        }
    }

    private let databaseURL: URL
    private let fileManager: FileManager
    private var databaseHandle: OpaquePointer?

    init(
        databaseURL: URL = DatabasePaths.databaseURL,
        fileManager: FileManager = .default
    ) {
        self.databaseURL = databaseURL
        self.fileManager = fileManager
    }

    func loadItems(limit: Int? = nil) throws -> [ClipboardItem] {
        try initializeIfNeeded()

        let sql: String
        if limit != nil {
            sql = """
            SELECT id, content, timestamp, source_app
            FROM clipboard_items
            ORDER BY timestamp DESC
            LIMIT ?;
            """
        } else {
            sql = """
            SELECT id, content, timestamp, source_app
            FROM clipboard_items
            ORDER BY timestamp DESC;
            """
        }

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        if let limit {
            try bind(Int32(limit), to: 1, in: statement)
        }

        var items: [ClipboardItem] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            items.append(makeItem(from: statement))
        }

        return items
    }

    func searchItems(query: String, limit: Int? = nil) throws -> [ClipboardItem] {
        try initializeIfNeeded()

        let sql: String
        if limit != nil {
            sql = """
            SELECT id, content, timestamp, source_app
            FROM clipboard_items
            WHERE content LIKE '%' || ? || '%' COLLATE NOCASE
            ORDER BY timestamp DESC
            LIMIT ?;
            """
        } else {
            sql = """
            SELECT id, content, timestamp, source_app
            FROM clipboard_items
            WHERE content LIKE '%' || ? || '%' COLLATE NOCASE
            ORDER BY timestamp DESC;
            """
        }

        let statement = try prepareStatement(sql)
        defer { sqlite3_finalize(statement) }

        try bind(query, to: 1, in: statement)
        if let limit {
            try bind(Int32(limit), to: 2, in: statement)
        }

        var items: [ClipboardItem] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            items.append(makeItem(from: statement))
        }

        return items
    }

    func upsert(
        content: String,
        timestamp: Date,
        sourceApplication: String?,
        historyLimit: Int
    ) throws -> ClipboardItem {
        try initializeIfNeeded()
        try execute(sql: "BEGIN IMMEDIATE TRANSACTION;")

        do {
            let timestampValue = Self.timestampValue(for: timestamp)

            let upsertStatement = try prepareStatement(
                """
                INSERT INTO clipboard_items (id, content, timestamp, source_app)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(content) DO UPDATE SET
                    timestamp = excluded.timestamp,
                    source_app = excluded.source_app;
                """
            )
            defer { sqlite3_finalize(upsertStatement) }

            try bind(UUID().uuidString, to: 1, in: upsertStatement)
            try bind(content, to: 2, in: upsertStatement)
            try bind(timestampValue, to: 3, in: upsertStatement)
            try bind(sourceApplication, to: 4, in: upsertStatement)
            try step(upsertStatement)

            try pruneInternal(to: historyLimit)
            let storedItem = try fetchItem(matching: content)

            try execute(sql: "COMMIT;")
            return storedItem
        } catch {
            try? execute(sql: "ROLLBACK;")
            throw error
        }
    }

    func delete(id: UUID) throws {
        try initializeIfNeeded()

        let statement = try prepareStatement("DELETE FROM clipboard_items WHERE id = ?;")
        defer { sqlite3_finalize(statement) }

        try bind(id.uuidString, to: 1, in: statement)
        try step(statement)
    }

    func clearHistory() throws {
        try initializeIfNeeded()
        try execute(sql: "DELETE FROM clipboard_items;")
    }

    func prune(to historyLimit: Int) throws {
        try initializeIfNeeded()
        try pruneInternal(to: historyLimit)
    }

    private func initializeIfNeeded() throws {
        guard databaseHandle == nil else {
            return
        }

        try fileManager.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var handle: OpaquePointer?
        let openStatus = sqlite3_open_v2(
            databaseURL.path,
            &handle,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        )

        guard openStatus == SQLITE_OK, let handle else {
            let message = handle.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
            if let handle {
                sqlite3_close(handle)
            }
            throw DatabaseError.openFailed(message)
        }

        databaseHandle = handle

        try execute(sql: "PRAGMA journal_mode = WAL;")
        try execute(sql: "PRAGMA synchronous = NORMAL;")
        try execute(
            sql: """
            CREATE TABLE IF NOT EXISTS clipboard_items (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL UNIQUE,
                timestamp INTEGER NOT NULL,
                source_app TEXT
            );
            """
        )
        try execute(
            sql: """
            CREATE INDEX IF NOT EXISTS idx_clipboard_items_timestamp
            ON clipboard_items(timestamp DESC);
            """
        )
        try execute(
            sql: """
            CREATE INDEX IF NOT EXISTS idx_clipboard_items_content
            ON clipboard_items(content);
            """
        )
    }

    private func pruneInternal(to historyLimit: Int) throws {
        let statement = try prepareStatement(
            """
            DELETE FROM clipboard_items
            WHERE id IN (
                SELECT id
                FROM clipboard_items
                ORDER BY timestamp DESC
                LIMIT -1 OFFSET ?
            );
            """
        )
        defer { sqlite3_finalize(statement) }

        try bind(Int32(historyLimit), to: 1, in: statement)
        try step(statement)
    }

    private func fetchItem(matching content: String) throws -> ClipboardItem {
        let statement = try prepareStatement(
            """
            SELECT id, content, timestamp, source_app
            FROM clipboard_items
            WHERE content = ?
            LIMIT 1;
            """
        )
        defer { sqlite3_finalize(statement) }

        try bind(content, to: 1, in: statement)

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw DatabaseError.rowNotFound
        }

        return makeItem(from: statement)
    }

    private func execute(sql: String) throws {
        guard let databaseHandle else {
            throw DatabaseError.openFailed("SQLite handle is unavailable.")
        }

        let result = sqlite3_exec(databaseHandle, sql, nil, nil, nil)
        guard result == SQLITE_OK else {
            throw DatabaseError.executionFailed(errorMessage)
        }
    }

    private func prepareStatement(_ sql: String) throws -> OpaquePointer? {
        guard let databaseHandle else {
            throw DatabaseError.openFailed("SQLite handle is unavailable.")
        }

        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(databaseHandle, sql, -1, &statement, nil)
        guard result == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage)
        }

        return statement
    }

    private func step(_ statement: OpaquePointer?) throws {
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE || result == SQLITE_ROW else {
            throw DatabaseError.executionFailed(errorMessage)
        }
    }

    private func bind(_ value: String, to index: Int32, in statement: OpaquePointer?) throws {
        let result = sqlite3_bind_text(statement, index, value, -1, transientDestructor)
        guard result == SQLITE_OK else {
            throw DatabaseError.bindFailed(errorMessage)
        }
    }

    private func bind(_ value: String?, to index: Int32, in statement: OpaquePointer?) throws {
        guard let value else {
            let result = sqlite3_bind_null(statement, index)
            guard result == SQLITE_OK else {
                throw DatabaseError.bindFailed(errorMessage)
            }
            return
        }

        try bind(value, to: index, in: statement)
    }

    private func bind(_ value: Int32, to index: Int32, in statement: OpaquePointer?) throws {
        let result = sqlite3_bind_int(statement, index, value)
        guard result == SQLITE_OK else {
            throw DatabaseError.bindFailed(errorMessage)
        }
    }

    private func bind(_ value: Int64, to index: Int32, in statement: OpaquePointer?) throws {
        let result = sqlite3_bind_int64(statement, index, value)
        guard result == SQLITE_OK else {
            throw DatabaseError.bindFailed(errorMessage)
        }
    }

    private func makeItem(from statement: OpaquePointer?) -> ClipboardItem {
        let idString = String(cString: sqlite3_column_text(statement, 0))
        let content = String(cString: sqlite3_column_text(statement, 1))
        let timestamp = sqlite3_column_int64(statement, 2)
        let sourceAppPointer = sqlite3_column_text(statement, 3)
        let sourceApplication = sourceAppPointer.map { String(cString: $0) }

        return ClipboardItem(
            id: UUID(uuidString: idString) ?? UUID(),
            content: content,
            timestamp: Self.dateValue(from: timestamp),
            sourceApplication: sourceApplication
        )
    }

    private static func timestampValue(for date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970 * 1_000)
    }

    private static func dateValue(from timestamp: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp) / 1_000)
    }

    private var errorMessage: String {
        guard let databaseHandle else {
            return "SQLite handle is unavailable."
        }

        return String(cString: sqlite3_errmsg(databaseHandle))
    }
}

private let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
