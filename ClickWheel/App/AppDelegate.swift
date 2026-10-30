import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var window: FloatingWindow?
    private var menuController: AppMenuController?
    private var statusItem: NSStatusItem?
    private var keyMonitor: Any?
    private var trackpadMonitor: Any?
    private var cancellables: Set<AnyCancellable> = []

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !AppModel.isRunningTests else { return }
        let model = AppModel()
        self.model = model

        let host = NSHostingView(rootView: AnyView(EmptyView()))
        let window = FloatingWindow(contentView: host, size: windowSize(for: model.display.geometry))
        self.window = window
        let menuController = AppMenuController(window: window, settings: model.settings,
                                               loginItem: MainAppLoginItem(),
                                               onError: { NSAlert(error: $0).runModal() })
        self.menuController = menuController
        host.rootView = AnyView(model.rootView()
            .environment(\.appMenu) { [weak menuController] in menuController?.menu() }
            .padding(Self.shadowMargin))

        // The menu bar icon: show or hide the iPod, and the app's options.
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = StatusIcon.image()
        statusItem.button?.toolTip = "ClickWheel"
        let statusMenu = NSMenu()
        statusMenu.delegate = menuController
        statusItem.menu = statusMenu
        self.statusItem = statusItem

        // Stay life size: re-measure whenever the window lands on another display.
        model.display.update(for: window.screen)
        model.display.$geometry
            // Resize after SwiftUI finishes the update that changed the model;
            // resizing inside it left the window showing the previous model.
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak window] geometry in
                guard let self, let window else { return }
                window.resizeKeepingTopLeft(to: self.windowSize(for: geometry))
            }
            .store(in: &cancellables)
        // A release that happens in another app never reaches us: drop any press
        // (and stop fast-forward/rewind) when ClickWheel loses focus.
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .merge(with: NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification, object: window))
            .sink { [weak model] _ in model?.input.cancel() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSWindow.didChangeScreenNotification, object: window)
            .sink { [weak model, weak window] _ in model?.display.update(for: window?.screen) }
            .store(in: &cancellables)

        model.settings.$keepOnTop
            .sink { [weak window] onTop in window?.level = onTop ? .floating : .normal }
            .store(in: &cancellables)

        // The trackpad as the wheel, while the pointer is over the iPod.
        trackpadMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rotate, .scrollWheel]) { [weak model, weak window] event in
            guard let model, let window, event.window === window else { return event }
            if event.type == .rotate {
                model.input.rotate(degrees: Double(event.rotation))
            } else {
                model.input.scrollWheel(deltaY: event.scrollingDeltaY,
                                        precise: event.hasPreciseScrollingDeltas,
                                        momentum: event.momentumPhase != [])
            }
            return nil
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak model] event in
            guard let model else { return event }
            // Key-ups always count, even with ⌘ held, so a hold can't get stuck;
            // key-downs with modifiers belong to menu shortcuts.
            if event.type == .keyDown, !event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
                return event
            }
            let key = event.type == .keyDown
                ? KeyMap.keyDown(code: event.keyCode, isRepeat: event.isARepeat)
                : KeyMap.keyUp(code: event.keyCode)
            guard let key else {
                // Swallow repeats of mapped keys so they don't beep.
                return KeyMap.keyUp(code: event.keyCode) != nil ? nil : event
            }
            model.input.handle(key)
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

    // No applicationShouldTerminateAfterLastWindowClosed: hiding the iPod
    // (menu bar icon › Hide) leaves no visible window, and that must not quit.

    /// Clicking the Dock icon brings a hidden iPod back.
    @MainActor
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuController?.showWindow()
        return false
    }
}
