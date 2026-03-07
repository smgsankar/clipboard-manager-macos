import OSLog

enum AppLogger {
    private static let logger = Logger(subsystem: "ClipboardManager", category: "App")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    static func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    static func error(_ message: String, error: Error? = nil) {
        if let error {
            logger.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("\(message, privacy: .public)")
        }
    }
}
