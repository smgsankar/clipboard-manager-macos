import Foundation

@MainActor
final class ClipboardWatcher {
    static let maximumItemSizeInBytes = 1_048_576

    private let pasteboard: PasteboardReading
    private let frontmostAppProvider: FrontmostAppProviding
    private let pollingInterval: TimeInterval
    private let onCapture: @MainActor (String, String?) -> Void

    private var timer: Timer?
    private var lastObservedChangeCount: Int

    init(
        pasteboard: PasteboardReading,
        frontmostAppProvider: FrontmostAppProviding,
        pollingInterval: TimeInterval = 0.3,
        onCapture: @escaping @MainActor (String, String?) -> Void
    ) {
        self.pasteboard = pasteboard
        self.frontmostAppProvider = frontmostAppProvider
        self.pollingInterval = pollingInterval
        self.onCapture = onCapture
        lastObservedChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        lastObservedChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollNow()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pollNow() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastObservedChangeCount else {
            return
        }

        lastObservedChangeCount = currentChangeCount

        guard let text = pasteboard.readString() else {
            return
        }

        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return
        }

        guard normalizedText.lengthOfBytes(using: .utf8) <= Self.maximumItemSizeInBytes else {
            AppLogger.warning("Ignored an oversized clipboard item.")
            return
        }

        onCapture(normalizedText, frontmostAppProvider.frontmostApplicationName)
    }
}
