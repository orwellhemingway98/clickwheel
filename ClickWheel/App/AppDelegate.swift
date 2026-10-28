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

        let root = model.rootView().padding(Self.shadowMargin)
        let host = NSHostingView(rootView: root)
        let window = FloatingWindow(contentView: host, size: windowSize(for: model.display.geometry))
        self.window = window

        // Stay life size: re-measure whenever the window lands on another display.
        model.display.update(for: window.screen)
        model.display.$geometry
            .sink { [weak self, weak window] geometry in
                guard let self, let window else { return }
                window.resizeKeepingTopLeft(to: self.windowSize(for: geometry))
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSWindow.didChangeScreenNotification, object: window)
            .sink { [weak model, weak window] _ in model?.display.update(for: window?.screen) }
            .store(in: &cancellables)

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

    /// Room around the body for its drop shadow.
    private static let shadowMargin: CGFloat = 20

    private func windowSize(for geometry: IPodGeometry) -> CGSize {
        CGSize(width: geometry.bodySize.width + Self.shadowMargin * 2,
               height: geometry.bodySize.height + Self.shadowMargin * 2)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
