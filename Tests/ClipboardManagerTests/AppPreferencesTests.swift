import Carbon
import Foundation
import Testing
@testable import ClipboardManager

@MainActor
@Test
func historyLimitIsClampedAndPersisted() {
    let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let preferences = AppPreferences(userDefaults: defaults)
    preferences.historyLimit = 5

    #expect(preferences.historyLimit == AppPreferences.historyLimitRange.lowerBound)

    let reloadedPreferences = AppPreferences(userDefaults: defaults)
    #expect(reloadedPreferences.historyLimit == AppPreferences.historyLimitRange.lowerBound)
}

@MainActor
@Test
func shortcutPersistsAcrossReload() {
    let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let preferences = AppPreferences(userDefaults: defaults)
    let shortcut = KeyboardShortcut(keyCode: 8, modifiers: UInt32(cmdKey) | UInt32(optionKey))
    preferences.shortcut = shortcut

    let reloadedPreferences = AppPreferences(userDefaults: defaults)
    #expect(reloadedPreferences.shortcut == shortcut)
}

@MainActor
@Test
func launchAtLoginCanBeEnabledAndDisabled() {
    let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let preferences = AppPreferences(userDefaults: defaults)
    
    // Test enabling
    preferences.launchAtLoginEnabled = true
    #expect(preferences.launchAtLoginEnabled == true)
    
    // Test disabling
    preferences.launchAtLoginEnabled = false
    #expect(preferences.launchAtLoginEnabled == false)
    
    // Verify persistence
    let reloadedPreferences = AppPreferences(userDefaults: defaults)
    #expect(reloadedPreferences.launchAtLoginEnabled == false)
}

@MainActor
@Test
func invalidShortcutIsRejected() {
    let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let preferences = AppPreferences(userDefaults: defaults)
    let originalShortcut = preferences.shortcut
    
    // Try to set an invalid shortcut (no modifiers)
    let invalidShortcut = KeyboardShortcut(keyCode: 8, modifiers: 0)
    #expect(!invalidShortcut.isValid)
    
    preferences.shortcut = invalidShortcut
    
    // Should revert to the original shortcut
    #expect(preferences.shortcut == originalShortcut)
    #expect(preferences.shortcut.isValid)
}
