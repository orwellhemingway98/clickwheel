import AppKit
import ServiceManagement

/// What the app menu shows. The same menu opens from the menu bar icon and
/// from right-clicking the iPod.
struct AppMenuState: Equatable {
    var windowVisible: Bool
    var keepOnTop: Bool
    var launchAtLogin: Bool
}

enum AppMenuCommand: Equatable {
    case toggleWindow, keepOnTop, launchAtLogin, quit
}

struct AppMenuRow: Equatable {
    let title: String
    let command: AppMenuCommand
    let isOn: Bool
}

enum AppMenu {
    /// The rows top to bottom; nil is a separator.
    static func rows(_ state: AppMenuState) -> [AppMenuRow?] {
        [AppMenuRow(title: state.windowVisible ? "Hide ClickWheel" : "Show ClickWheel", command: .toggleWindow, isOn: false),
         nil,
         AppMenuRow(title: "Keep on Top", command: .keepOnTop, isOn: state.keepOnTop),
         AppMenuRow(title: "Launch at Login", command: .launchAtLogin, isOn: state.launchAtLogin),
         nil,
         AppMenuRow(title: "Quit ClickWheel", command: .quit, isOn: false)]
    }

    /// Replaces `menu`'s items with the rows for `state`.
    @MainActor
    static func fill(_ menu: NSMenu, state: AppMenuState, perform: @escaping (AppMenuCommand) -> Void) {
        menu.removeAllItems()
        for row in rows(state) {
            guard let row else { menu.addItem(.separator()); continue }
            let item = CommandItem(title: row.title, keyEquivalent: row.command == .quit ? "q" : "") { perform(row.command) }
            item.state = row.isOn ? .on : .off
            menu.addItem(item)
        }
    }

    /// A menu item that runs a closure.
    private final class CommandItem: NSMenuItem {
        private let run: () -> Void

        init(title: String, keyEquivalent: String, run: @escaping () -> Void) {
            self.run = run
            super.init(title: title, action: #selector(fire), keyEquivalent: keyEquivalent)
            target = self
        }

        required init(coder: NSCoder) { fatalError("not used") }

        @objc private func fire() { run() }
    }
}

/// Starting ClickWheel when you log in.
protocol LoginItem: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ on: Bool) throws
}

/// The app itself as a login item (System Settings › General › Login Items).
final class MainAppLoginItem: LoginItem {
    /// Waiting for approval in System Settings counts as on, so choosing it
    /// again turns it off.
    var isEnabled: Bool { [.enabled, .requiresApproval].contains(SMAppService.mainApp.status) }

    func setEnabled(_ on: Bool) throws {
        if on {
            try SMAppService.mainApp.register()
            // macOS may want the person to allow it in System Settings first.
            if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

/// Runs the app menu's commands against the iPod window, the settings and
/// the login item, and builds the menu from their current state.
@MainActor
final class AppMenuController: NSObject, NSMenuDelegate {
    private let window: NSWindow
    private let settings: AppSettings
    private let loginItem: LoginItem
    private let onError: (Error) -> Void
    private let hideApp: () -> Void

    init(window: NSWindow, settings: AppSettings, loginItem: LoginItem,
         onError: @escaping (Error) -> Void,
         hideApp: @escaping () -> Void = { NSApp.hide(nil) }) {
        self.window = window
        self.settings = settings
        self.loginItem = loginItem
        self.onError = onError
        self.hideApp = hideApp
    }

    var state: AppMenuState {
        AppMenuState(windowVisible: window.isVisible, keepOnTop: settings.keepOnTop,
                     launchAtLogin: loginItem.isEnabled)
    }

    func perform(_ command: AppMenuCommand) {
        switch command {
        case .toggleWindow: window.isVisible ? hideWindow() : showWindow()
        case .keepOnTop: settings.keepOnTop.toggle()
        case .launchAtLogin:
            do { try loginItem.setEnabled(!loginItem.isEnabled) } catch { onError(error) }
        case .quit: NSApp.terminate(nil)
        }
    }

    func showWindow() {
        // A hidden app asking politely (`activate()`) is refused from the menu
        // bar icon, so the iPod would come back without the keyboard.
        NSApp.unhide(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Hides the iPod and the app with it, so the keyboard goes back to the
    /// app you were using rather than steering music with nothing on screen.
    private func hideWindow() {
        window.orderOut(nil)
        hideApp()
    }

    func menu() -> NSMenu {
        let menu = NSMenu()
        AppMenu.fill(menu, state: state) { [weak self] in self?.perform($0) }
        return menu
    }

    /// The menu bar icon's menu is refreshed each time it opens.
    func menuNeedsUpdate(_ menu: NSMenu) {
        AppMenu.fill(menu, state: state) { [weak self] in self?.perform($0) }
    }
}

/// The menu bar icon: a small iPod outline, drawn in code.
enum StatusIcon {
    static func image() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            NSColor.black.set()
            let body = NSBezierPath(roundedRect: NSRect(x: 4.6, y: 1.6, width: 8.8, height: 14.8), xRadius: 1.8, yRadius: 1.8)
            body.lineWidth = 1.2
            body.stroke()
            NSBezierPath(roundedRect: NSRect(x: 6.2, y: 3.2, width: 5.6, height: 4.2), xRadius: 0.5, yRadius: 0.5).fill()
            let wheel = NSBezierPath(ovalIn: NSRect(x: 6.5, y: 9.1, width: 5, height: 5))
            wheel.lineWidth = 1.1
            wheel.stroke()
            NSBezierPath(ovalIn: NSRect(x: 8.25, y: 10.85, width: 1.5, height: 1.5)).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
