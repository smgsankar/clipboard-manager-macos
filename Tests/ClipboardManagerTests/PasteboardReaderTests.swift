import AppKit
import Foundation
import Testing
@testable import ClipboardManager

@MainActor
@Test
func pasteboardReaderReadsPasteboardChangeCount() {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    let reader = PasteboardReader(pasteboard: pasteboard)
    
    let initialCount = reader.changeCount
    
    pasteboard.clearContents()
    pasteboard.setString("test", forType: .string)
    
    let newCount = reader.changeCount
    #expect(newCount > initialCount)
}

@MainActor
@Test
func pasteboardReaderReadsString() {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    pasteboard.clearContents()
    pasteboard.setString("Hello World", forType: .string)
    
    let reader = PasteboardReader(pasteboard: pasteboard)
    let content = reader.readString()
    
    #expect(content == "Hello World")
}

@MainActor
@Test
func pasteboardReaderReturnsNilWhenEmpty() {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    pasteboard.clearContents()
    
    let reader = PasteboardReader(pasteboard: pasteboard)
    let content = reader.readString()
    
    #expect(content == nil)
}

@MainActor
@Test
func pasteboardReaderWritesString() {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    let reader = PasteboardReader(pasteboard: pasteboard)
    
    reader.writeString("Test Content")
    
    let written = pasteboard.string(forType: .string)
    #expect(written == "Test Content")
}

@MainActor
@Test
func pasteboardReaderWriteClearsExistingContent() {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    pasteboard.clearContents()
    pasteboard.setString("Old Content", forType: .string)
    
    let reader = PasteboardReader(pasteboard: pasteboard)
    reader.writeString("New Content")
    
    let content = pasteboard.string(forType: .string)
    #expect(content == "New Content")
}

@MainActor
@Test
func pasteboardReaderUsesGeneralPasteboardByDefault() {
    let reader = PasteboardReader()
    
    // Just verify it doesn't crash - we can't reliably test the general pasteboard
    // as it's shared with the system
    _ = reader.changeCount
}

@MainActor
@Test
func pasteboardReaderHandlesEmptyString() {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    let reader = PasteboardReader(pasteboard: pasteboard)
    
    reader.writeString("")
    let content = reader.readString()
    
    #expect(content == "")
}

@MainActor
@Test
func pasteboardReaderHandlesLongContent() {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    let reader = PasteboardReader(pasteboard: pasteboard)
    
    let longContent = String(repeating: "x", count: 10_000)
    reader.writeString(longContent)
    
    let content = reader.readString()
    #expect(content == longContent)
}
