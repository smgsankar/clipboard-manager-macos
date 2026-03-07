import Foundation
import Testing
@testable import ClipboardManager

@Test
func formatterPreviewsShortContent() {
    let content = "Hello, World!"
    let preview = MenuBarItemFormatter.preview(for: content)
    #expect(preview == "Hello, World!")
}

@Test
func formatterTruncatesLongContent() {
    let content = String(repeating: "a", count: 100)
    let preview = MenuBarItemFormatter.preview(for: content, maxLength: 20)
    
    #expect(preview.count == 21) // 20 chars + ellipsis
    #expect(preview.hasSuffix("…"))
}

@Test
func formatterReplacesNewlinesWithSpaces() {
    let content = "First line\nSecond line\nThird line"
    let preview = MenuBarItemFormatter.preview(for: content)
    
    #expect(!preview.contains("\n"))
    #expect(preview == "First line Second line Third line")
}

@Test
func formatterReplacesCarriageReturnsWithSpaces() {
    let content = "First line\rSecond line"
    let preview = MenuBarItemFormatter.preview(for: content)
    
    #expect(!preview.contains("\r"))
    #expect(preview == "First line Second line")
}

@Test
func formatterTrimsWhitespace() {
    let content = "   Hello World   "
    let preview = MenuBarItemFormatter.preview(for: content)
    
    #expect(preview == "Hello World")
}

@Test
func formatterCombinesMultipleFormattingRules() {
    let content = "  First line\nSecond line  \n  Third line  "
    let preview = MenuBarItemFormatter.preview(for: content, maxLength: 30)
    
    #expect(!preview.contains("\n"))
    #expect(preview.count <= 31) // maxLength + ellipsis
}

@Test
func formatterHandlesEmptyString() {
    let content = ""
    let preview = MenuBarItemFormatter.preview(for: content)
    
    #expect(preview.isEmpty)
}

@Test
func formatterHandlesOnlyWhitespace() {
    let content = "   \n\n   "
    let preview = MenuBarItemFormatter.preview(for: content)
    
    #expect(preview.isEmpty)
}

@Test
func formatterDefaultMaxLengthIs80() {
    let content = String(repeating: "x", count: 100)
    let preview = MenuBarItemFormatter.preview(for: content)
    
    // Should be truncated at 80 + ellipsis
    #expect(preview.count == 81)
    #expect(preview.hasSuffix("…"))
}

@Test
func formatterHandlesExactMaxLength() {
    let content = String(repeating: "a", count: 80)
    let preview = MenuBarItemFormatter.preview(for: content, maxLength: 80)
    
    // Exactly at maxLength, no truncation needed
    #expect(preview.count == 80)
    #expect(!preview.hasSuffix("…"))
}

@Test
func formatterHandlesUnicodeCharacters() {
    let content = "Hello 👋 World 🌍"
    let preview = MenuBarItemFormatter.preview(for: content)
    
    #expect(preview == "Hello 👋 World 🌍")
}
