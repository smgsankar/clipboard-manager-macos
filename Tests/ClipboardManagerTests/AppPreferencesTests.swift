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
