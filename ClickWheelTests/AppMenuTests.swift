import AppKit
import XCTest
@testable import ClickWheel

@MainActor
final class AppMenuTests: XCTestCase {
    private let shown = AppMenuState(windowVisible: true, keepOnTop: true, launchAtLogin: false)

    func testRowsTopToBottom() {
        XCTAssertEqual(AppMenu.rows(shown).map { $0?.title }, [
            "Hide ClickWheel", nil, "Keep on Top", "Launch at Login", nil, "Quit ClickWheel"])
        XCTAssertEqual(AppMenu.rows(shown).compactMap { $0?.command },
                       [.toggleWindow, .keepOnTop, .launchAtLogin, .quit])
    }

    func testHiddenWindowOffersShow() {
        var hidden = shown
        hidden.windowVisible = false
        XCTAssertEqual(AppMenu.rows(hidden).first??.title, "Show ClickWheel")
    }

    func testTicksFollowTheSettings() {
        func ticks(_ s: AppMenuState) -> [Bool] { AppMenu.rows(s).compactMap { $0?.isOn } }
        XCTAssertEqual(ticks(shown), [false, true, false, false])
        XCTAssertEqual(ticks(AppMenuState(windowVisible: true, keepOnTop: false, launchAtLogin: true)),
                       [false, false, true, false])
    }

    func testBuiltMenuShowsTheRowsAndRunsTheirCommands() {
        var ran: [AppMenuCommand] = []
        let menu = NSMenu()
        AppMenu.fill(menu, state: shown) { ran.append($0) }
        XCTAssertEqual(menu.items.map(\.title), ["Hide ClickWheel", "", "Keep on Top", "Launch at Login", "", "Quit ClickWheel"])
        XCTAssertEqual(menu.items.map(\.isSeparatorItem), [false, true, false, false, true, false])
        XCTAssertEqual(menu.items[2].state, .on)
        XCTAssertEqual(menu.items[3].state, .off)
        menu.performActionForItem(at: 3)
        menu.performActionForItem(at: 0)
        XCTAssertEqual(ran, [.launchAtLogin, .toggleWindow])
    }

    func testFillingAgainReplacesTheRows() {
        let menu = NSMenu()
        AppMenu.fill(menu, state: shown) { _ in }
        var hidden = shown
        hidden.windowVisible = false
        AppMenu.fill(menu, state: hidden) { _ in }
        XCTAssertEqual(menu.items.count, 6)
        XCTAssertEqual(menu.items.first?.title, "Show ClickWheel")
    }

    func testMenuBarIconIsATemplateDrawnInCode() {
        let icon = StatusIcon.image()
        XCTAssertTrue(icon.isTemplate, "template images follow the menu bar's light or dark look")
        XCTAssertEqual(icon.size, NSSize(width: 18, height: 18))
        let rep = NSBitmapImageRep(data: icon.tiffRepresentation!)!
        let inked = (0..<rep.pixelsWide).flatMap { x in (0..<rep.pixelsHigh).map { (x, $0) } }
            .filter { rep.colorAt(x: $0.0, y: $0.1)!.alphaComponent > 0.5 }.count
        XCTAssertGreaterThan(inked, 20, "something is drawn")
        XCTAssertLessThan(inked, rep.pixelsWide * rep.pixelsHigh / 2, "an outline, not a blob")
    }
}

@MainActor
final class AppMenuControllerTests: XCTestCase {
    private final class FakeLoginItem: LoginItem {
        var isEnabled = false
        var failNext = false
        func setEnabled(_ on: Bool) throws {
            if failNext { failNext = false; throw CocoaError(.featureUnsupported) }
            isEnabled = on
        }
    }

    private var settings: AppSettings!
    private var window: NSWindow!
    private var login: FakeLoginItem!
    private var errors: [Error] = []

    override func setUp() {
        let defaults = UserDefaults(suiteName: "AppMenuControllerTests")!
        defaults.removePersistentDomain(forName: "AppMenuControllerTests")
        settings = AppSettings(defaults: defaults)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 50, height: 50),
                          styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        login = FakeLoginItem()
        errors = []
    }

    override func tearDown() { window.orderOut(nil) }

    private func controller() -> AppMenuController {
        AppMenuController(window: window, settings: settings, loginItem: login,
                          onError: { [unowned self] in self.errors.append($0) })
    }

    func testStateReadsTheWindowSettingsAndLoginItem() {
        window.orderFront(nil)
        settings.keepOnTop = false
        login.isEnabled = true
        XCTAssertEqual(controller().state,
                       AppMenuState(windowVisible: true, keepOnTop: false, launchAtLogin: true))
    }

    func testToggleWindowHidesAndShowsTheIPod() {
        let c = controller()
        window.orderFront(nil)
        c.perform(.toggleWindow)
        XCTAssertFalse(window.isVisible)
        c.perform(.toggleWindow)
        XCTAssertTrue(window.isVisible)
    }

    func testKeepOnTopFlipsTheSetting() {
        settings.keepOnTop = true
        controller().perform(.keepOnTop)
        XCTAssertFalse(settings.keepOnTop)
    }

    func testLaunchAtLoginFlipsTheLoginItem() {
        let c = controller()
        c.perform(.launchAtLogin)
        XCTAssertTrue(login.isEnabled)
        c.perform(.launchAtLogin)
        XCTAssertFalse(login.isEnabled)
        XCTAssertTrue(errors.isEmpty)
    }

    func testLoginItemFailureIsReportedAndLeavesItOff() {
        login.failNext = true
        controller().perform(.launchAtLogin)
        XCTAssertFalse(login.isEnabled)
        XCTAssertEqual(errors.count, 1)
    }

    func testMenuIsBuiltFreshFromTheCurrentState() {
        let c = controller()
        window.orderOut(nil)
        XCTAssertEqual(c.menu().items.first?.title, "Show ClickWheel")
        window.orderFront(nil)
        XCTAssertEqual(c.menu().items.first?.title, "Hide ClickWheel")
    }
}
