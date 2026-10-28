import XCTest
@testable import ClickWheel

@MainActor
final class NavigatorModesTests: XCTestCase {
    private var spy: SpyPlayerControls!
    private var settings: AppSettings!
    private var suiteName: String!
    private var clock: TimeInterval = 100
    private var moved: [Int] = []

    override func setUp() async throws {
        suiteName = "NavigatorModesTests-\(UUID().uuidString)"
        settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        spy = SpyPlayerControls()
        clock = 100
        moved = []
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func navigator(music: [MenuItem]? = nil, shuffle: Bool = false) -> Navigator {
        Navigator(player: spy, settings: settings,
                  musicMenu: music.map { items in { MenuScreen(title: "Music", items: items) } },
                  shuffle: shuffle ? {} : nil,
                  now: { [unowned self] in self.clock },
                  onRowsMoved: { [unowned self] in self.moved.append($0) })
    }

    private func menu(_ nav: Navigator) -> MenuScreen? {
        if case .menu(let screen) = nav.current { return screen }
        return nil
    }

    private func track(_ id: String = "t1", position: Double = 50) -> NowPlayingInfo {
        NowPlayingInfo(trackID: id, title: "Song", artist: "A", album: "B", duration: 200,
                       position: position, index: nil, count: nil, source: .appleMusic)
    }

    /// Opens Now Playing from the root (it's the last row once a track is set).
    private func openNowPlaying(_ nav: Navigator) {
        nav.handle(.scroll(steps: 10))
        nav.handle(.center)
    }

    // MARK: Root menu

    func testRootWithoutAndWithTrack() {
        let nav = navigator(music: [], shuffle: true)
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Music", "Extras", "Settings", "Shuffle Songs"])
        nav.setTrack(track())
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Music", "Extras", "Settings", "Shuffle Songs", "Now Playing"])
    }

    func testNowPlayingRowRemovedWhileSelectedClamps() {
        let nav = navigator(music: [], shuffle: true)
        nav.setTrack(track())
        nav.handle(.scroll(steps: 4))
        XCTAssertEqual(menu(nav)?.items[menu(nav)!.selectedIndex].label, "Now Playing")
        nav.setTrack(nil)
        XCTAssertEqual(menu(nav)?.items[menu(nav)!.selectedIndex].label, "Shuffle Songs")
    }

    func testNowPlayingRowAddedKeepsSelection() {
        let nav = navigator(music: [], shuffle: true)
        nav.handle(.scroll(steps: 1))
        nav.setTrack(track())
        XCTAssertEqual(menu(nav)?.items[menu(nav)!.selectedIndex].label, "Extras")
    }

    func testMenuHoldJumpsToRoot() {
        let nav = navigator()
        nav.handle(.center)            // Extras
        nav.handle(.center)            // Clock
        XCTAssertEqual(nav.stack.count, 3)
        nav.handle(.menuHold)
        XCTAssertEqual(nav.stack.count, 1)
        XCTAssertEqual(nav.lastNavigation, .back)
    }

    func testPushSetsForwardDirection() {
        let nav = navigator()
        nav.handle(.center)
        XCTAssertEqual(nav.lastNavigation, .forward)
        nav.handle(.menu)
        XCTAssertEqual(nav.lastNavigation, .back)
    }

    // MARK: Acceleration and Quick Scroll

    private func longList(_ nav: Navigator) {
        let items = (0..<50).map { MenuItem(String(UnicodeScalar(65 + $0 % 26)!) + "song\($0)", quickScrollList: true, action: .run {}) }
        nav.handle(.center)  // Music
        nav.handle(.center)  // the long list (opens via load)
        _ = items
    }

    private func fastSpin(_ nav: Navigator, steps: Int, every dt: Double = 0.02) {
        for _ in 0..<steps {
            clock += dt
            nav.handle(.scroll(steps: 1))
        }
    }

    func testFastScrollAcceleratesAndShowsLetterThenFades() async {
        let rows = (0..<50).map { MenuItem(["Alpha", "Bravo", "Charlie", "Delta", "Echo"][$0 / 10] + " \($0)", action: .run {}) }
        let nav = navigator(music: [MenuItem("Songs", quickScrollList: true, action: .load(title: "Songs", empty: "No songs") { rows })])
        nav.handle(.center)          // Music
        nav.handle(.center)          // Songs
        await nav.lastTask?.value
        fastSpin(nav, steps: 6)
        XCTAssertGreaterThan(menu(nav)!.selectedIndex, 6)
        XCTAssertNotNil(nav.quickScrollLetter)
        nav.handle(.tick(now: clock + 0.5))
        XCTAssertNotNil(nav.quickScrollLetter)
        nav.handle(.tick(now: clock + 1.0))
        XCTAssertNil(nav.quickScrollLetter)
    }

    func testLetterClearsAfterLongTickGap() async {
        let rows = (0..<50).map { MenuItem("Row \($0)", action: .run {}) }
        let nav = navigator(music: [MenuItem("Songs", quickScrollList: true, action: .load(title: "Songs", empty: "No songs") { rows })])
        nav.handle(.center); nav.handle(.center)
        await nav.lastTask?.value
        fastSpin(nav, steps: 6)
        nav.handle(.tick(now: clock + 10))
        XCTAssertNil(nav.quickScrollLetter)
    }

    func testNoLetterInListsWithoutQuickScroll() {
        let nav = navigator(music: (0..<50).map { MenuItem("Row \($0)", action: .run {}) })
        nav.handle(.center)
        fastSpin(nav, steps: 6)
        XCTAssertNil(nav.quickScrollLetter)
    }

    func testFastScrollClampsAtEndAndReportsActualRows() {
        let nav = navigator(music: (0..<5).map { MenuItem("Row \($0)", action: .run {}) })
        nav.handle(.center)
        moved = []
        fastSpin(nav, steps: 8)
        XCTAssertEqual(menu(nav)?.selectedIndex, 4)
        XCTAssertEqual(moved.reduce(0, +), 4)
        XCTAssertFalse(moved.contains(0))
    }

    func testIndexLetter() {
        XCTAssertEqual(Navigator.indexLetter(for: "Ólafur Arnalds"), "O")
        XCTAssertEqual(Navigator.indexLetter(for: "50 Cent"), "#")
        XCTAssertEqual(Navigator.indexLetter(for: "the Beatles"), "T")
        XCTAssertEqual(Navigator.indexLetter(for: ""), "#")
    }

    // MARK: Now Playing modes

    func testWheelOnNowPlayingShowsVolumeThenExpires() {
        let nav = navigator()
        nav.setTrack(track())
        openNowPlaying(nav)
        nav.handle(.scroll(steps: 1))
        XCTAssertEqual(spy.calls.last, "adjustVolume(3)")
        guard case .volume = nav.nowPlayingMode else { return XCTFail("expected volume mode") }
        nav.handle(.tick(now: clock + 2.1))
        XCTAssertEqual(nav.nowPlayingMode, .normal)
    }

    func testVolumeIsNeverAccelerated() {
        let nav = navigator()
        nav.setTrack(track())
        openNowPlaying(nav)
        fastSpin(nav, steps: 8)
        XCTAssertEqual(spy.calls.filter { $0.hasPrefix("adjustVolume") }, Array(repeating: "adjustVolume(3)", count: 8))
    }

    func testCenterScrubsAndWheelSeeks() {
        let nav = navigator()
        nav.setTrack(track(position: 50))
        openNowPlaying(nav)
        nav.handle(.center)
        guard case .scrubbing(let position, _) = nav.nowPlayingMode else { return XCTFail("expected scrubbing") }
        XCTAssertEqual(position, 50)
        nav.handle(.scroll(steps: 1))
        XCTAssertEqual(spy.calls.last, "setPosition(52.0)")
        nav.handle(.tick(now: clock + 3.1))
        XCTAssertEqual(nav.nowPlayingMode, .normal)
    }

    func testMenuLeavesScrubbingWithoutPopping() {
        let nav = navigator()
        nav.setTrack(track())
        openNowPlaying(nav)
        nav.handle(.center)
        nav.handle(.menu)
        XCTAssertEqual(nav.nowPlayingMode, .normal)
        guard case .nowPlaying = nav.current else { return XCTFail("should still be on Now Playing") }
    }

    func testTrackChangeEndsScrubbing() {
        let nav = navigator()
        nav.setTrack(track("t1"))
        openNowPlaying(nav)
        nav.handle(.center)
        nav.setTrack(track("t2"))
        XCTAssertEqual(nav.nowPlayingMode, .normal)
    }

    // MARK: Seeking and transport

    func testSeekHoldRepeatsUntilReleased() {
        let nav = navigator()
        nav.handle(.seekForward(active: true))
        nav.handle(.tick(now: clock + 0.1))
        nav.handle(.tick(now: clock + 0.25))
        nav.handle(.tick(now: clock + 0.5))
        nav.handle(.seekForward(active: false))
        nav.handle(.tick(now: clock + 0.75))
        XCTAssertEqual(spy.calls, ["seek(5.0)", "seek(5.0)"])
    }

    func testRewindHoldSeeksBackward() {
        let nav = navigator()
        nav.handle(.seekBackward(active: true))
        nav.handle(.tick(now: clock + 0.25))
        XCTAssertEqual(spy.calls, ["seek(-5.0)"])
    }

    func testPreviousRestartsOrGoesBack() {
        let nav = navigator()
        nav.handle(.previous)
        XCTAssertEqual(spy.calls, ["restartOrPrevious"])
    }

    // MARK: Extras

    func testStopwatchScreen() {
        let nav = navigator()
        nav.handle(.center)                 // Extras
        nav.handle(.scroll(steps: 1))       // Stopwatch
        nav.handle(.center)
        guard case .stopwatch = nav.current else { return XCTFail("expected stopwatch") }
        nav.handle(.center)                 // start at 100
        XCTAssertEqual(nav.stopwatch.elapsed(now: 101.25), 1.25, accuracy: 0.001)
        clock = 102
        nav.handle(.center)                 // stop at 102
        XCTAssertEqual(nav.stopwatch.elapsed(now: 200), 2, accuracy: 0.001)
        nav.handle(.playPause)              // reset, not play/pause
        XCTAssertEqual(nav.stopwatch.elapsed(now: 200), 0)
        XCTAssertEqual(spy.calls, [])
    }

    func testStopwatchFormat() {
        XCTAssertEqual(TimeFormat.stopwatch(61.25), "01:01.2")
        XCTAssertEqual(TimeFormat.stopwatch(0), "00:00.0")
    }
}
