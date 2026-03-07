import Foundation
import ServiceManagement

@MainActor
protocol LaunchAtLoginControlling: AnyObject {
    var lastErrorMessage: String? { get }
    func currentStatus() -> Bool
    func setEnabled(_ enabled: Bool)
}

@MainActor
final class LaunchAtLoginManager: ObservableObject, LaunchAtLoginControlling {
    @Published private(set) var lastErrorMessage: String?

    private let appService: SMAppService

    init(appService: SMAppService = .mainApp) {
        self.appService = appService
    }

    func currentStatus() -> Bool {
        appService.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if appService.status != .enabled {
                    try appService.register()
                }
            } else if appService.status == .enabled {
                try appService.unregister()
            }

            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLogger.error("Unable to update launch-at-login registration.", error: error)
        }
    }
}
