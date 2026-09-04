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
            if preferences.menuBarDisplayStyle == .gauge {
                ProgressView(value: countdown.snapshot.progress)
                    .progressViewStyle(.linear)
                    .frame(width: 56)
                    .accessibilityLabel("목표까지 진행률")
                    .accessibilityValue("\(Int(countdown.snapshot.progress * 100))%")
            } else {
                Text(countdown.snapshot.menuBarText)
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(preferences)
        }
    }
}
