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
                    ShortcutRecorderView(
                        shortcut: $preferences.shortcut,
                        onRecordingStarted: {
                            coordinator.temporarilyDisableHotkey()
                        },
                        onRecordingEnded: {
                            coordinator.reEnableHotkey()
                        }
                    )
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
                Picker("History Size", selection: $preferences.historyLimit) {
                    Text("10").tag(10)
                    Text("25").tag(25)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
                }
                .pickerStyle(.menu)

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
