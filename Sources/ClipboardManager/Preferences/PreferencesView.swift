import SwiftUI

struct PreferencesView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var preferences: AppPreferences

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _preferences = ObservedObject(wrappedValue: coordinator.preferences)
    }

    var body: some View {
        Form {
            Section("Keyboard Shortcut") {
                HStack {
                    Text("Open Clipboard History")
                    Spacer()
                    ShortcutRecorderView(shortcut: $preferences.shortcut)
                        .frame(width: 180, height: 28)
                }

                Text("Default: \(KeyboardShortcut.defaultShortcut.displayString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let hotkeyErrorMessage = coordinator.hotkeyErrorMessage {
                    Text(hotkeyErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("History") {
                Stepper(
                    value: $preferences.historyLimit,
                    in: AppPreferences.historyLimitRange,
                    step: 10
                ) {
                    Text("History Size: \(preferences.historyLimit)")
                }

                Text("Stored locally only. Maximum 1000 text entries.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: $preferences.launchAtLoginEnabled)

                if let launchAtLoginErrorMessage = coordinator.launchAtLoginErrorMessage {
                    Text(launchAtLoginErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Privacy") {
                Text("Clipboard history stays on this Mac. No analytics, sync, or telemetry are included.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(minWidth: 460, minHeight: 320)
    }
}
