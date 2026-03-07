import Testing
@testable import ClipboardManager

@MainActor
@Test
func watcherCapturesTrimmedTextFromPasteboard() {
    let pasteboard = FakePasteboard()
    let appProvider = FakeFrontmostAppProvider()
    appProvider.frontmostApplicationName = "Notes"

    var captures: [(String, String?)] = []
    let watcher = ClipboardWatcher(
        pasteboard: pasteboard,
        frontmostAppProvider: appProvider,
        pollingInterval: 0.3
    ) { content, sourceApplication in
        captures.append((content, sourceApplication))
    }

    pasteboard.string = "  hello world  "
    pasteboard.changeCount = 1
    watcher.pollNow()

    #expect(captures.count == 1)
    #expect(captures.first?.0 == "hello world")
    #expect(captures.first?.1 == "Notes")
}

@MainActor
@Test
func watcherIgnoresEmptyAndOversizedText() {
    let pasteboard = FakePasteboard()
    let appProvider = FakeFrontmostAppProvider()

    var captures: [(String, String?)] = []
    let watcher = ClipboardWatcher(
        pasteboard: pasteboard,
        frontmostAppProvider: appProvider,
        pollingInterval: 0.3
    ) { content, sourceApplication in
        captures.append((content, sourceApplication))
    }

    pasteboard.string = "   "
    pasteboard.changeCount = 1
    watcher.pollNow()

    pasteboard.string = String(repeating: "a", count: ClipboardWatcher.maximumItemSizeInBytes + 1)
    pasteboard.changeCount = 2
    watcher.pollNow()

    #expect(captures.isEmpty)
}

@MainActor
private final class FakePasteboard: PasteboardReading {
    var changeCount: Int = 0
    var string: String?

    func readString() -> String? {
        string
    }

    func writeString(_ string: String) {
        self.string = string
        changeCount += 1
    }
}

@MainActor
private final class FakeFrontmostAppProvider: FrontmostAppProviding {
    var frontmostApplicationName: String?
}
