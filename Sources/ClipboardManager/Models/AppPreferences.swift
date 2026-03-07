import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    static let defaultHistoryLimit = 100
    static let historyLimitRange = 10...1000

    private enum Keys {
        static let historyLimit = "historyLimit"
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let keyboardShortcut = "keyboardShortcut"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published var historyLimit: Int {
        didSet {
            let clamped = Self.clampHistoryLimit(historyLimit)
            if clamped != historyLimit {
                historyLimit = clamped
                return
            }

            userDefaults.set(historyLimit, forKey: Keys.historyLimit)
        }
    }

    @Published var launchAtLoginEnabled: Bool {
        didSet {
            userDefaults.set(launchAtLoginEnabled, forKey: Keys.launchAtLoginEnabled)
        }
    }

    @Published var shortcut: KeyboardShortcut {
        didSet {
            guard shortcut.isValid else {
                shortcut = oldValue
                return
            }

            if let encoded = try? encoder.encode(shortcut) {
                userDefaults.set(encoded, forKey: Keys.keyboardShortcut)
            }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let savedHistoryLimit = userDefaults.object(forKey: Keys.historyLimit) as? Int
        historyLimit = Self.clampHistoryLimit(savedHistoryLimit ?? Self.defaultHistoryLimit)

        let savedLaunchPreference = userDefaults.object(forKey: Keys.launchAtLoginEnabled) as? Bool
        launchAtLoginEnabled = savedLaunchPreference ?? true

        if
            let data = userDefaults.data(forKey: Keys.keyboardShortcut),
            let decodedShortcut = try? decoder.decode(KeyboardShortcut.self, from: data)
        {
            shortcut = decodedShortcut
        } else {
            shortcut = .defaultShortcut
        }
    }

    static func clampHistoryLimit(_ value: Int) -> Int {
        min(max(value, historyLimitRange.lowerBound), historyLimitRange.upperBound)
    }
}
