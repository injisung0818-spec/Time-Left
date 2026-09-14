import SwiftUI
import WidgetKit
import AppKit

@MainActor
final class AppearanceManager {
    static let shared = AppearanceManager()

    func apply(_ appearance: AppAppearance) {
        switch appearance {
        case .system: NSApplication.shared.appearance = nil
        case .light: NSApplication.shared.appearance = NSAppearance(named: .aqua)
        case .dark: NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

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
        AppearanceManager.shared.apply(preferences.appAppearance)
        WidgetCenter.shared.reloadTimelines(ofKind: "TimeLeftWidget")
        URLSchemeHandler.shared.start { url in
            guard url.scheme?.lowercased() == "timeleft" else { return }
            if url.host?.lowercased() == "schedule",
               let scheduleID = UUID(uuidString: url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))),
               let schedule = preferences.schedules.first(where: { $0.id == scheduleID }) {
                preferences.selectSchedule(schedule)
            }
            SettingsWindowManager.shared.show(preferences: preferences, updateChecker: updateChecker)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(preferences)
                .environmentObject(countdown)
                .environmentObject(updateChecker)
        } label: {
            switch preferences.selectedMenuBarDisplayStyle {
            case .compact:
                Text(CountdownEngine.formatDuration(countdown.snapshot.remaining, unit: preferences.displayUnit()))
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
