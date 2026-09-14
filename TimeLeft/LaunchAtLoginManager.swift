import ServiceManagement

enum LaunchAtLoginManager {
    private static let service = SMAppService.mainApp

    static var isEnabled: Bool {
        service.status == .enabled
    }

    static var requiresApproval: Bool {
        service.status == .requiresApproval
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard service.status != .enabled else { return }
            try service.register()
        } else if service.status != .notRegistered {
            try service.unregister()
        }
    }
}
