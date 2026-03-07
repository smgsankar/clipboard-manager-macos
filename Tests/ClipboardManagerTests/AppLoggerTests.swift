import Foundation
import Testing
@testable import ClipboardManager

@Test
func loggerInfoMethodCanBeCalled() {
    // This test ensures the method is exercised for coverage
    // The actual logging will go to OSLog
    AppLogger.info("Test info message")
    
    // No assertion needed - we're just ensuring the method runs without crashing
}

@Test
func loggerWarningMethodCanBeCalled() {
    AppLogger.warning("Test warning message")
    
    // No assertion needed - we're just ensuring the method runs without crashing
}

@Test
func loggerErrorMethodWithErrorCanBeCalled() {
    let testError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    AppLogger.error("Test error message", error: testError)
    
    // No assertion needed - we're just ensuring the method runs without crashing
}

@Test
func loggerErrorMethodWithoutErrorCanBeCalled() {
    AppLogger.error("Test error message without error object")
    
    // No assertion needed - we're just ensuring the method runs without crashing
}

@Test
func loggerHandlesEmptyMessages() {
    AppLogger.info("")
    AppLogger.warning("")
    AppLogger.error("")
    
    // No assertion needed - ensuring empty strings don't cause issues
}

@Test
func loggerHandlesLongMessages() {
    let longMessage = String(repeating: "Long message ", count: 100)
    
    AppLogger.info(longMessage)
    AppLogger.warning(longMessage)
    AppLogger.error(longMessage)
    
    // No assertion needed - ensuring long messages are handled
}

@Test
func loggerHandlesSpecialCharacters() {
    let specialMessage = "Test with special chars: 🎉 \n \t \" ' \\"
    
    AppLogger.info(specialMessage)
    AppLogger.warning(specialMessage)
    AppLogger.error(specialMessage, error: nil)
    
    // No assertion needed - ensuring special characters are handled
}
