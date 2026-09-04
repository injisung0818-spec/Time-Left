import SwiftUI

@main
struct TimeLeftApp: App {
    @StateObject private var preferences: Preferences
    @StateObject private var countdown: CountdownModel
    @StateObject private var updateChecker: GitHubReleaseChecker

    init() {
        let preferences = Preferences()
        let updateChecker = GitHubReleaseChecker()
        _preferences = StateObject(wrappedValue: preferences)
        _countdown = StateObject(wrappedValue: CountdownModel(preferences: preferences))
        _updateChecker = StateObject(wrappedValue: updateChecker)
        LaunchAtLoginManager.registerIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(preferences)
                .environmentObject(countdown)
                .environmentObject(updateChecker)
        } label: {
            switch preferences.menuBarDisplayStyle {
            case .compact:
                Text(CountdownEngine.formatDuration(countdown.snapshot.remaining, unit: preferences.displayUnit))
                    .monospacedDigit()
            case .digital:
                Text(CountdownEngine.digitalMenuBarText(countdown.snapshot.remaining))
                    .monospacedDigit()
            case .icon:
                Image(systemName: "clock")
                    .accessibilityLabel("Time Left")
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(preferences)
                .environmentObject(updateChecker)
        }
    }
}
