import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var window: FloatingWindow?
    private var keyMonitor: Any?
    private var cancellables: Set<AnyCancellable> = []

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !AppModel.isRunningTests else { return }
        let model = AppModel()
        self.model = model

        let margin: CGFloat = 20
        let size = CGSize(width: Theme.bodySize.width + margin * 2, height: Theme.bodySize.height + margin * 2)
        let root = model.rootView().padding(margin)
        let host = NSHostingView(rootView: root)
        let window = FloatingWindow(contentView: host, size: size)
        self.window = window

        model.settings.$keepOnTop
            .sink { [weak window] onTop in window?.level = onTop ? .floating : .normal }
            .store(in: &cancellables)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak model] event in
            guard let model,
                  event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
                  let wheelEvent = KeyMap.event(forKeyCode: event.keyCode) else { return event }
            model.navigator.handle(wheelEvent)
            return nil
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        model.renderSnapshotIfRequested()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
