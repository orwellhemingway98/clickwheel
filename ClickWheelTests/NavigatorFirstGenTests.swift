import XCTest
@testable import ClickWheel

@MainActor
final class NavigatorFirstGenTests: XCTestCase {
    private var spy: SpyPlayerControls!
    private var settings: AppSettings!
    private var suiteName: String!
    private var clock: TimeInterval = 100

    override func setUp() async throws {
        suiteName = "NavigatorFirstGenTests-\(UUID().uuidString)"
        settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        spy = SpyPlayerControls()
        clock = 100
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func navigator(_ model: IPodModel = .firstGen, rows: [MenuItem] = []) -> Navigator {
        Navigator(player: spy, settings: settings,
                  musicMenu: { MenuScreen(title: "Music", items: rows) },
                  shuffle: {},
                  profile: model.spec.firmware,
                  browse: { MenuScreen(title: "Browse", items: [
                      MenuItem("Artists", action: .run {}), MenuItem("Albums", action: .run {}), MenuItem("Songs", action: .run {}),
                  ]) },
                  playlists: { MenuItem("Playlists", action: .push { MenuScreen(title: "Playlists", items: rows) }) },
                  now: { [unowned self] in self.clock })
    }

    private func menu(_ nav: Navigator) -> MenuScreen? {
        if case .menu(let screen) = nav.current { return screen }
        return nil
    }

    private func open(_ nav: Navigator, _ label: String) {
        guard let index = menu(nav)?.items.firstIndex(where: { $0.label == label }) else { return XCTFail("no \(label)") }
        nav.handle(.scroll(steps: index - menu(nav)!.selectedIndex))
        nav.handle(.center)
    }

    private let track = NowPlayingInfo(trackID: "t", title: "T", artist: "A", album: "B", duration: 100,
                                       position: 10, index: nil, count: nil, source: .appleMusic)

    func testFirstGenRoot() {
        let nav = navigator()
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Playlists", "Browse", "Extras", "Settings", "Backlight"])
        nav.setTrack(track)
        XCTAssertEqual(menu(nav)?.items.last?.label, "Now Playing")
    }

    func testBrowseMenu() {
        let nav = navigator()
        open(nav, "Browse")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Artists", "Albums", "Songs"])
    }

    func testExtrasHasClockOnly() {
        let nav = navigator()
        open(nav, "Extras")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Clock"])
    }

    func testSettingsPerModel() {
        let first = navigator()
        open(first, "Settings")
        XCTAssertEqual(menu(first)?.items.map(\.label), ["Model", "Source", "Backlight Timer", "Clicker"])
        let fifth = navigator(.fifthGen)
        open(fifth, "Settings")
        XCTAssertEqual(menu(fifth)?.items.map(\.label), ["Model", "Source", "Clicker"])
    }

    func testModelRowOpensTheList() {
        settings.model = .firstGen
        let nav = navigator()
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.items.first?.detail(), "1st gen")
        XCTAssertTrue(menu(nav)?.items.first?.opensSubmenu == true)
        nav.handle(.center)
        XCTAssertEqual(menu(nav)?.title, "Model")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["1st generation", "2nd generation", "5th generation"])
        XCTAssertEqual(menu(nav)?.items.map { $0.detail() }, ["✓ 2001", "2002", "2005"])
        XCTAssertEqual(menu(nav)?.selectedIndex, 0)
    }

    func testModelListAlwaysOpensAtTheTop() {
        settings.model = .fifthGen
        let nav = navigator(.fifthGen)
        open(nav, "Settings")
        nav.handle(.center)
        XCTAssertEqual(menu(nav)?.title, "Model")
        XCTAssertEqual(menu(nav)?.selectedIndex, 0, "like every iPod list, it starts at the top")
        XCTAssertEqual(menu(nav)?.items.last?.detail(), "✓ 2005", "the tick still marks the current model")
        nav.handle(.scroll(steps: 1))
        nav.handle(.center)
        XCTAssertEqual(settings.model, .secondGen, "one step down from the top is the 2nd generation")
    }

    func testSelectingAModelSwitchesAndPersists() {
        settings.model = .firstGen
        let nav = navigator()
        open(nav, "Settings")
        nav.handle(.center)
        open(nav, "2nd generation")
        XCTAssertEqual(settings.model, .secondGen)
        XCTAssertEqual(AppSettings(defaults: UserDefaults(suiteName: suiteName)!).model, .secondGen)
    }

    func testSelectingTheCurrentModelGoesBack() {
        settings.model = .firstGen
        let nav = navigator()
        open(nav, "Settings")
        nav.handle(.center)
        nav.handle(.center)                 // "1st generation" is current
        XCTAssertEqual(settings.model, .firstGen)
        XCTAssertEqual(menu(nav)?.title, "Settings")
    }

    func testBacklightTimerRowCycles() {
        let nav = navigator()
        open(nav, "Settings")
        open(nav, "Backlight Timer")
        XCTAssertEqual(settings.backlightTimer, .twenty)
        XCTAssertEqual(menu(nav)?.items[2].detail(), "20 s")
    }

    func testHoldMenuTogglesBacklightOnFirstGen() {
        settings.backlightTimer = .ten
        let nav = navigator()
        open(nav, "Extras")
        nav.handle(.menuHold)                   // input woke it, so the hold turns it off
        XCTAssertFalse(nav.backlight.isOn)
        XCTAssertEqual(menu(nav)?.title, "Extras", "hold MENU must not leave the screen on 1G")
        nav.handle(.menuHold)
        XCTAssertTrue(nav.backlight.isOn)
    }

    func testHoldMenuStillGoesHomeOnFifthGen() {
        let nav = navigator(.fifthGen)
        nav.handle(.center)
        nav.handle(.menuHold)
        XCTAssertEqual(nav.stack.count, 1)
    }

    func testBacklightRowToggles() {
        let nav = navigator()
        open(nav, "Backlight")                  // the scroll woke it; the row turns it off
        XCTAssertFalse(nav.backlight.isOn)
    }

    func testInputWakesAndTickExpires() {
        settings.backlightTimer = .five
        let nav = navigator()
        nav.handle(.scroll(steps: 1))
        XCTAssertTrue(nav.backlight.isOn)
        nav.handle(.tick(now: clock + 4.9))
        XCTAssertTrue(nav.backlight.isOn)
        nav.handle(.tick(now: clock + 5.1))
        XCTAssertFalse(nav.backlight.isOn)
    }

    func testNoQuickScrollOnFirstGen() async {
        let rows = (0..<50).map { MenuItem("Row \($0)", action: .run {}) }
        let nav = Navigator(player: spy, settings: settings, profile: IPodModel.firstGen.spec.firmware,
                            browse: { MenuScreen(title: "Browse", items: [
                                MenuItem("Songs", quickScrollList: true, action: .load(title: "Songs", empty: "No songs") { rows }),
                            ]) },
                            now: { [unowned self] in self.clock })
        open(nav, "Browse")
        nav.handle(.center)
        await nav.lastTask?.value
        for _ in 0..<8 { clock += 0.02; nav.handle(.scroll(steps: 1)) }
        XCTAssertNil(nav.quickScrollLetter)
        XCTAssertGreaterThan(menu(nav)!.selectedIndex, 8, "acceleration still works")
    }

    func testSetProfileResetsToNewRoot() {
        let nav = navigator(.fifthGen)
        nav.setTrack(track)
        nav.handle(.scroll(steps: 10))
        nav.handle(.center)                     // Now Playing
        nav.handle(.center)                     // scrubbing
        nav.setProfile(IPodModel.firstGen.spec.firmware)
        XCTAssertEqual(nav.stack.count, 1)
        XCTAssertEqual(nav.nowPlayingMode, .normal)
        XCTAssertEqual(menu(nav)?.items.first?.label, "Playlists")
        XCTAssertEqual(menu(nav)?.items.last?.label, "Now Playing")
    }

    func testFirstGenUsesSixRows() {
        let rows = (0..<20).map { MenuItem("Row \($0)", action: .run {}) }
        let nav = navigator(rows: rows)
        open(nav, "Playlists")
        nav.handle(.scroll(steps: 7))
        XCTAssertEqual(menu(nav)?.windowStart, 2)
    }

    func testChangingModelFromSettingsLeavesAWorkingMenu() {
        let nav = navigator(.fifthGen)
        settings.model = .fifthGen
        // As in the app: a model change switches the navigator's firmware.
        let observer = settings.$model.dropFirst().sink { [unowned nav] model in nav.setProfile(model.spec.firmware) }
        defer { observer.cancel() }
        open(nav, "Settings")
        nav.handle(.center)                      // Model list
        open(nav, "1st generation")              // 5th gen → 1st gen
        XCTAssertEqual(settings.model, .firstGen)
        XCTAssertEqual(nav.stack.count, 1)
        XCTAssertEqual(menu(nav)?.title, "iPod", "the new model's main menu, not the old Settings screen")
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.title, "Settings")
        nav.handle(.menu)
        XCTAssertEqual(menu(nav)?.title, "iPod", "MENU goes back from Settings")
    }

    // MARK: - Backlight review fixes

    private func row(_ nav: Navigator, _ label: String) {
        guard let index = menu(nav)?.items.firstIndex(where: { $0.label == label }) else { return XCTFail("no \(label)") }
        nav.handle(.scroll(steps: index - menu(nav)!.selectedIndex))
    }

    func testBacklightRowTurnsOnThenOff() {
        settings.backlightTimer = .ten
        let nav = navigator()
        row(nav, "Backlight")
        nav.handle(.tick(now: clock + 11))          // let it go dark
        XCTAssertFalse(nav.backlight.isOn)
        clock += 11
        nav.handle(.center)
        XCTAssertTrue(nav.backlight.isOn, "Backlight row lights a dark screen")
        nav.handle(.center)
        XCTAssertFalse(nav.backlight.isOn, "Backlight row turns a lit screen off")
    }

    func testTimerChangeAppliesImmediately() {
        settings.backlightTimer = .twenty
        let nav = navigator()
        open(nav, "Settings")
        row(nav, "Backlight Timer")
        nav.handle(.center)                         // 20 s → Always
        XCTAssertEqual(settings.backlightTimer, .always)
        nav.handle(.tick(now: clock + 1000))
        XCTAssertTrue(nav.backlight.isOn, "Always never times out")
        nav.handle(.center)                         // Always → Off
        nav.handle(.center)                         // Off → 2 s
        XCTAssertEqual(settings.backlightTimer, .two)
        nav.handle(.tick(now: clock + 3))
        XCTAssertFalse(nav.backlight.isOn, "the new 2 s timer applies; Always doesn't linger")
    }

    func testTickDoesNotRepublishWhenNothingChanges() {
        let nav = navigator(.fifthGen)
        var changes = 0
        let observer = nav.objectWillChange.sink { changes += 1 }
        defer { observer.cancel() }
        for i in 1...10 { nav.handle(.tick(now: clock + Double(i) / 10)) }
        XCTAssertEqual(changes, 0)
    }
}
