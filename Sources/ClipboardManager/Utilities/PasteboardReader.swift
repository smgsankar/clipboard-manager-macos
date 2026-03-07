import AppKit

@MainActor
protocol PasteboardReading: AnyObject {
    var changeCount: Int { get }
    func readString() -> String?
    func writeString(_ string: String)
}

@MainActor
final class PasteboardReader: PasteboardReading {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    func readString() -> String? {
        pasteboard.string(forType: .string)
    }

    func writeString(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
