import Foundation
import Testing
@testable import ClipboardManager

@Test
func databasePathsHaveApplicationSupportDirectory() {
    let appSupport = DatabasePaths.applicationSupportDirectory
    
    #expect(appSupport.path.contains("Library/Application Support/ClipboardManager"))
    #expect(appSupport.path.contains(FileManager.default.homeDirectoryForCurrentUser.path))
}

@Test
func databasePathsHaveDatabaseURL() {
    let databaseURL = DatabasePaths.databaseURL
    
    #expect(databaseURL.lastPathComponent == "clipboard.db")
    #expect(databaseURL.path.contains("Library/Application Support/ClipboardManager"))
}

@Test
func databaseURLIsWithinApplicationSupportDirectory() {
    let appSupport = DatabasePaths.applicationSupportDirectory
    let databaseURL = DatabasePaths.databaseURL
    
    #expect(databaseURL.path.hasPrefix(appSupport.path))
}

@Test
func databasePathsAreAbsolutePaths() {
    let appSupport = DatabasePaths.applicationSupportDirectory
    let databaseURL = DatabasePaths.databaseURL
    
    #expect(appSupport.path.hasPrefix("/"))
    #expect(databaseURL.path.hasPrefix("/"))
}
