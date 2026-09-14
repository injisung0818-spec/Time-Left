import AppKit

@MainActor
final class URLSchemeHandler: NSObject {
    static let shared = URLSchemeHandler()

    private var onOpen: ((URL) -> Void)?

    func start(onOpen: @escaping (URL) -> Void) {
        self.onOpen = onOpen
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(event:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleGetURL(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let rawURL = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: rawURL) else { return }
        onOpen?(url)
    }
}
