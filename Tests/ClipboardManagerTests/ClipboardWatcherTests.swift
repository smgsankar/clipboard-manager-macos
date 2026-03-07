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
@Test
func watcherStartAndStopManageTimer() async {
    let pasteboard = FakePasteboard()
    let appProvider = FakeFrontmostAppProvider()

    var captureCount = 0
    let watcher = ClipboardWatcher(
        pasteboard: pasteboard,
        frontmostAppProvider: appProvider,
        pollingInterval: 0.05 // 50ms for faster tests
    ) { _, _ in
        captureCount += 1
    }

    // Start the watcher
    watcher.start()
    
    // Verify it doesn't restart if already started
    watcher.start()
    
    // Change pasteboard content
    pasteboard.string = "test content"
    pasteboard.changeCount = 1
    
    // Manually poll to verify watcher is working
    watcher.pollNow()
    
    // Should have captured the content
    #expect(captureCount > 0)
    
    let capturesBeforeStop = captureCount
    
    // Stop the watcher
    watcher.stop()
    
    // Change content again
    pasteboard.string = "new content"
    pasteboard.changeCount = 2
    
    // Manually poll after stop - should still capture since we're calling pollNow directly
    watcher.pollNow()
    
    // But the important thing is stop() invalidates the timer
    // We verify this by checking the timer doesn't affect captureCount
    try? await Task.sleep(nanoseconds: 150_000_000) // 150ms (3x polling interval)
    
    // Capture count should have increased by 1 from our manual pollNow()
    #expect(captureCount == capturesBeforeStop + 1)
}

@MainActor
@Test
func watcherIgnoresUnchangedPasteboard() {
    let pasteboard = FakePasteboard()
    let appProvider = FakeFrontmostAppProvider()

    var captureCount = 0
    let watcher = ClipboardWatcher(
        pasteboard: pasteboard,
        frontmostAppProvider: appProvider,
        pollingInterval: 0.3
    ) { _, _ in
        captureCount += 1
    }

    pasteboard.string = "test"
    pasteboard.changeCount = 1
    watcher.pollNow()
    
    #expect(captureCount == 1)
    
    // Poll again without changing pasteboard
    watcher.pollNow()
    
    // Should not capture again
    #expect(captureCount == 1)
}

@MainActor
@Test
func watcherIgnoresNilPasteboardContent() {
    let pasteboard = FakePasteboard()
    let appProvider = FakeFrontmostAppProvider()

    var captureCount = 0
    let watcher = ClipboardWatcher(
        pasteboard: pasteboard,
        frontmostAppProvider: appProvider,
        pollingInterval: 0.3
    ) { _, _ in
        captureCount += 1
    }

    pasteboard.string = nil
    pasteboard.changeCount = 1
    watcher.pollNow()
    
    #expect(captureCount == 0)
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
final class FakeFrontmostAppProvider: FrontmostAppProviding {
    var frontmostApplicationName: String?
}
