import XCTest
@testable import ClickWheel

@MainActor
final class NavigatorTests: XCTestCase {
    private var spy: SpyPlayerControls!
    private var settings: AppSettings!
    private var nav: Navigator!
    private var stepCount = 0
    private var suiteName: String!

    override func setUp() async throws {
        suiteName = "NavigatorTests-\(UUID().uuidString)"
        spy = SpyPlayerControls()
        settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        stepCount = 0
        nav = Navigator(player: spy, settings: settings, onScrollStep: { [unowned self] in self.stepCount += 1 })
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private var menu: MenuScreen? {
        if case .menu(let screen) = nav.current { return screen }
        return nil
    }

    private var isNowPlaying: Bool {
        if case .nowPlaying = nav.current { return true }
        return false
    }

    func testStartsAtRootWithFirstItemSelected() {
        XCTAssertEqual(menu?.title, "ClickWheel")
        XCTAssertEqual(menu?.items.map(\.label), ["Now Playing", "Settings"])
        XCTAssertEqual(menu?.selectedIndex, 0)
    }

    func testScrollMovesSelectionClamped() {
        nav.handle(.scroll(steps: 5))
        XCTAssertEqual(menu?.selectedIndex, 1)
        nav.handle(.scroll(steps: -9))
        XCTAssertEqual(menu?.selectedIndex, 0)
    }

    func testCenterOnSettingsPushes() {
        nav.handle(.scroll(steps: 1))
        nav.handle(.center)
        XCTAssertEqual(menu?.title, "Settings")
    }

    func testMenuPopsAndRestoresSelection() {
        nav.handle(.scroll(steps: 1))
        nav.handle(.center)
        nav.handle(.menu)
        XCTAssertEqual(menu?.title, "ClickWheel")
        XCTAssertEqual(menu?.selectedIndex, 1)
    }

    func testMenuAtRootIsNoOp() {
        nav.handle(.menu)
        XCTAssertEqual(nav.stack.count, 1)
    }

    func testCenterOnNowPlayingShowsNowPlaying() {
        nav.handle(.center)
        XCTAssertTrue(isNowPlaying)
        nav.handle(.menu)
        XCTAssertEqual(menu?.title, "ClickWheel")
    }

    func testScrollOnNowPlayingAdjustsVolume() {
        nav.handle(.center)
        nav.handle(.scroll(steps: 2))
        XCTAssertEqual(spy.calls, ["adjustVolume(6)"])
    }

    func testTransportEventsForwardedEverywhere() {
        nav.handle(.playPause)
        nav.handle(.next)
        nav.handle(.previous)
        XCTAssertEqual(spy.calls, ["playPause", "next", "previous"])
    }

    func testSourceCycles() {
        nav.handle(.scroll(steps: 1))
        nav.handle(.center)
        let source = { self.menu?.items.first { $0.label == "Source" } }
        XCTAssertEqual(source()?.detail(), "Auto")
        nav.handle(.center)
        XCTAssertEqual(settings.sourceMode, .appleMusic)
        XCTAssertEqual(source()?.detail(), "Apple Music")
        nav.handle(.center)
        XCTAssertEqual(settings.sourceMode, .spotify)
        XCTAssertEqual(source()?.detail(), "Spotify")
        nav.handle(.center)
        XCTAssertEqual(settings.sourceMode, .auto)
    }

    func testClickerToggles() {
        nav.handle(.scroll(steps: 1))
        nav.handle(.center)
        nav.handle(.scroll(steps: 1))
        nav.handle(.center)
        XCTAssertFalse(settings.clickerEnabled)
        XCTAssertEqual(menu?.items[1].detail(), "Off")
    }

    func testScrollStepCallbackFiresOnlyWhenSelectionMoves() {
        nav.handle(.scroll(steps: -1))
        XCTAssertEqual(stepCount, 0)
        nav.handle(.scroll(steps: 1))
        XCTAssertEqual(stepCount, 1)
    }
}
