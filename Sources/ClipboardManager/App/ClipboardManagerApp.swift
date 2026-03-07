import AppKit
import SwiftUI

@main
struct ClipboardManagerApp: App {
    @StateObject private var coordinator = AppCoordinator()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("Clipboard", systemImage: "clipboard") {
            MenuBarView(coordinator: coordinator)
                .environmentObject(coordinator.store)
        }

        Settings {
            PreferencesView(coordinator: coordinator)
        }
    }
}
