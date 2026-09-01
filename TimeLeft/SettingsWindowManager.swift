import AppKit
import SwiftUI

final class SettingsWindowManager {
    static let shared = SettingsWindowManager()

    private var windowController: NSWindowController?

    func show(preferences: Preferences) {
        if windowController == nil {
            let rootView = SettingsView()
                .environmentObject(preferences)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
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

        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
}
