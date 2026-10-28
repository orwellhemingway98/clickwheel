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

    func testModelRowCyclesAndPersists() {
        settings.model = .firstGen
        let nav = navigator()
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.items.first?.detail(), "1st gen")
        nav.handle(.center)
        XCTAssertEqual(settings.model, .fifthGen)
        nav.handle(.center)
        XCTAssertEqual(settings.model, .firstGen)
        XCTAssertEqual(AppSettings(defaults: UserDefaults(suiteName: suiteName)!).model, .firstGen)
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
}
