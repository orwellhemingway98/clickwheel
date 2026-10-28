import XCTest
@testable import ClickWheel

/// A loader that waits until the test releases it.
@MainActor
private final class Gate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var opened = false

    func wait() async {
        if opened { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        opened = true
        continuation?.resume()
        continuation = nil
    }
}

private struct Boom: Error {}

@MainActor
final class NavigatorLoadingTests: XCTestCase {
    private var spy: SpyPlayerControls!
    private var settings: AppSettings!
    private var suiteName: String!
    private var steps = 0
    private var played = 0

    override func setUp() async throws {
        suiteName = "NavigatorLoadingTests-\(UUID().uuidString)"
        settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        spy = SpyPlayerControls()
        steps = 0
        played = 0
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    /// A navigator whose Music menu is `items`; the test opens Music, then works inside it.
    private func navigator(_ items: [MenuItem]) -> Navigator {
        let nav = Navigator(player: spy, settings: settings,
                            musicMenu: { MenuScreen(title: "Music", items: items) },
                            onPlayed: { [unowned self] in self.played += 1 },
                            onScrollStep: { [unowned self] in self.steps += 1 })
        nav.handle(.center) // root row 0 is Music
        steps = 0
        return nav
    }

    private func menu(_ nav: Navigator) -> MenuScreen? {
        if case .menu(let screen) = nav.current { return screen }
        return nil
    }

    private func item(_ label: String) -> MenuItem { MenuItem(label, action: .run {}) }

    func testMusicRootWhenProvided() {
        let nav = Navigator(player: spy, settings: settings, musicMenu: { MenuScreen(title: "Music", items: []) })
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Music", "Now Playing", "Settings"])
    }

    func testLoadShowsLoadingThenItems() async {
        let gate = Gate()
        let nav = navigator([MenuItem("Playlists", action: .load(title: "Playlists", empty: "No playlists") { [self] in
            await gate.wait()
            return [item("A"), item("B")]
        })])
        nav.handle(.center)
        XCTAssertEqual(menu(nav)?.title, "Playlists")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Loading…"])
        gate.open()
        await nav.lastTask?.value
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["A", "B"])
        XCTAssertEqual(menu(nav)?.selectedIndex, 0)
    }

    func testLoadEmptyShowsEmptyRow() async {
        let nav = navigator([MenuItem("Playlists", action: .load(title: "Playlists", empty: "No playlists") { [] })])
        nav.handle(.center)
        await nav.lastTask?.value
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["No playlists"])
        XCTAssertEqual(menu(nav)?.items.first?.isSelectable, false)
    }

    func testLoadFailureShowsError() async {
        let nav = navigator([MenuItem("Albums", action: .load(title: "Albums", empty: "No albums") { throw Boom() })])
        nav.handle(.center)
        await nav.lastTask?.value
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Couldn't load library"])
    }

    func testStaleLoadDiscardedAfterMenu() async {
        let gate = Gate()
        let nav = navigator([MenuItem("Playlists", action: .load(title: "Playlists", empty: "No playlists") { [self] in
            await gate.wait()
            return [item("Late")]
        })])
        nav.handle(.center)
        nav.handle(.menu)
        gate.open()
        await nav.lastTask?.value
        XCTAssertEqual(menu(nav)?.title, "Music")
        for case .menu(let screen) in nav.stack {
            XCTAssertFalse(screen.items.map(\.label).contains("Late"))
        }
    }

    func testPlaceholderRowsIgnoreInput() async {
        let gate = Gate()
        let nav = navigator([MenuItem("Songs", action: .load(title: "Songs", empty: "No songs") { [self] in
            await gate.wait()
            return []
        })])
        nav.handle(.center)
        let depth = nav.stack.count
        nav.handle(.scroll(steps: 1))
        nav.handle(.scroll(steps: -1))
        nav.handle(.center)
        XCTAssertEqual(menu(nav)?.selectedIndex, 0)
        XCTAssertEqual(steps, 0)
        XCTAssertEqual(nav.stack.count, depth)
        gate.open()
        await nav.lastTask?.value
    }

    func testScrollSkipsNonSelectableRows() {
        let nav = navigator([item("A"), .placeholder("—"), item("B")])
        nav.handle(.scroll(steps: 1))
        XCTAssertEqual(menu(nav)?.selectedIndex, 2)
        XCTAssertEqual(steps, 1)
    }

    func testSelectionStartsOnFirstSelectableRow() {
        let nav = navigator([.placeholder("—"), item("A")])
        XCTAssertEqual(menu(nav)?.selectedIndex, 1)
    }

    func testPlaySuccessPushesNowPlayingAndNotifies() async {
        let nav = navigator([MenuItem("Song", action: .play {})])
        nav.handle(.center)
        await nav.lastTask?.value
        guard case .nowPlaying = nav.current else { return XCTFail("expected Now Playing") }
        XCTAssertEqual(played, 1)
        nav.handle(.menu)
        XCTAssertEqual(menu(nav)?.title, "Music")
    }

    func testPlayFailureStaysOnList() async {
        let nav = navigator([MenuItem("Song", action: .play { throw Boom() })])
        nav.handle(.center)
        await nav.lastTask?.value
        XCTAssertEqual(menu(nav)?.title, "Music")
        XCTAssertEqual(played, 0)
    }
}
