import ServiceManagement

enum LaunchAtLoginManager {
    private static let service = SMAppService.mainApp

    static var isEnabled: Bool {
        service.status == .enabled
    }

    static var requiresApproval: Bool {
        service.status == .requiresApproval
    }

    static func registerIfNeeded() {
        guard service.status == .notRegistered else { return }
        try? service.register()
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }
}
