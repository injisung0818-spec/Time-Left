import AppKit
import SwiftUI

@MainActor
final class SettingsWindowManager {
    static let shared = SettingsWindowManager()

    private var windowController: NSWindowController?

    func show(preferences: Preferences, updateChecker: GitHubReleaseChecker) {
        if windowController == nil {
            let rootView = SettingsView()
                .environmentObject(preferences)
                .environmentObject(updateChecker)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Time Left 설정"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: rootView)
            windowController = NSWindowController(window: window)
        }

        updateChecker.checkForLatestRelease()
        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
}
