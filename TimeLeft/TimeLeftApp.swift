import SwiftUI

@main
struct TimeLeftApp: App {
    @StateObject private var preferences: Preferences
    @StateObject private var countdown: CountdownModel

    init() {
        let preferences = Preferences()
        _preferences = StateObject(wrappedValue: preferences)
        _countdown = StateObject(wrappedValue: CountdownModel(preferences: preferences))
        LaunchAtLoginManager.registerIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(preferences)
                .environmentObject(countdown)
        } label: {
            Text(countdown.snapshot.menuBarText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(preferences)
        }
    }
}
