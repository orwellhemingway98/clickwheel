import XCTest
@testable import ClickWheel

private final class FakeCoverFlow: CoverFlowSource {
    var result: [CoverFlowAlbum] = []
    private(set) var played: [(ids: [String], start: Int)] = []

    private(set) var albumLoads = 0
    func albums() async throws -> [CoverFlowAlbum] { albumLoads += 1; return result }
    func play(trackIDs: [String], startIndex: Int) async throws { played.append((trackIDs, startIndex)) }
}

@MainActor
final class NavigatorCoverFlowTests: XCTestCase {
    private var spy: SpyPlayerControls!
    private var settings: AppSettings!
    private var suiteName: String!
    private var source: FakeCoverFlow!

    override func setUp() async throws {
        suiteName = "NavigatorCoverFlowTests-\(UUID().uuidString)"
        settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        spy = SpyPlayerControls()
        source = FakeCoverFlow()
        source.result = [
            CoverFlowAlbum(name: "One", artist: "A", trackIDs: ["1a", "1b"], trackNames: ["x", "y"]),
            CoverFlowAlbum(name: "Two", artist: "B", trackIDs: ["2a", "2b", "2c"], trackNames: ["p", "q", "r"]),
        ]
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func navigator(_ model: IPodModel) -> Navigator {
        Navigator(player: spy, settings: settings,
                  musicMenu: { MenuScreen(title: "Music", items: [MenuItem("Playlists", action: .run {})]) },
                  profile: model.spec.firmware, coverFlow: source)
    }

    private func menu(_ nav: Navigator) -> MenuScreen? {
        if case .menu(let screen) = nav.current { return screen }
        return nil
    }

    private func coverFlow(_ nav: Navigator) -> CoverFlowState? {
        if case .coverFlow(let state) = nav.current { return state }
        return nil
    }

    private func openCoverFlow(_ nav: Navigator) async {
        nav.handle(.center)                 // Music (first row of the main menu)
        XCTAssertEqual(menu(nav)?.title, "Music")
        XCTAssertEqual(menu(nav)?.items.first?.label, "Cover Flow")
        nav.handle(.center)
        await nav.lastTask?.value
    }

    func testOnlyTheClassicStyleHasCoverFlow() {
        for model in IPodModel.allCases where model.spec.firmware.menuStyle != .classic {
            let nav = navigator(model)
            guard let music = menu(nav)?.items.firstIndex(where: { $0.label == "Music" }) else { continue }
            nav.choose(row: music)
            XCTAssertFalse(menu(nav)?.items.contains { $0.label == "Cover Flow" } ?? false, model.generationName)
        }
    }

    func testOpeningLoadsTheAlbums() async {
        let nav = navigator(.classic)
        await openCoverFlow(nav)
        XCTAssertEqual(coverFlow(nav)?.loading, false)
        XCTAssertEqual(coverFlow(nav)?.albums.map(\.name), ["One", "Two"])
    }

    func testTheWheelMovesCoversAndCentreFlipsThenPlays() async {
        let nav = navigator(.nanoThirdGen)
        await openCoverFlow(nav)
        nav.handle(.scroll(steps: 1))
        XCTAssertEqual(coverFlow(nav)?.index, 1)
        nav.handle(.center)
        XCTAssertEqual(coverFlow(nav)?.flipped, true)
        nav.handle(.scroll(steps: 2))
        nav.handle(.center)
        await nav.lastTask?.value
        XCTAssertEqual(source.played.first?.ids, ["2a", "2b", "2c"])
        XCTAssertEqual(source.played.first?.start, 2)
        guard case .nowPlaying = nav.current else { return XCTFail("Now Playing follows a pick") }
    }

    func testMenuFlipsBackThenLeaves() async {
        let nav = navigator(.classic)
        await openCoverFlow(nav)
        nav.handle(.center)
        nav.handle(.menu)
        XCTAssertEqual(coverFlow(nav)?.flipped, false)
        nav.handle(.menu)
        XCTAssertEqual(menu(nav)?.title, "Music")
    }

    func testReopeningIsAFreshScreenWithTheAlbumsRemembered() async {
        let nav = navigator(.classic)
        await openCoverFlow(nav)
        let firstID = coverFlow(nav)?.id
        nav.handle(.scroll(steps: 1))
        nav.handle(.menu)
        XCTAssertEqual(menu(nav)?.title, "Music")
        nav.handle(.center)
        await nav.lastTask?.value
        XCTAssertNotEqual(coverFlow(nav)?.id, firstID, "each opening gets its own screen")
        XCTAssertEqual(coverFlow(nav)?.loading, false, "the albums are remembered")
        XCTAssertEqual(source.albumLoads, 1)
    }

    func testALateLoadDoesNotResetAScreenThatIsAlreadyFilled() async {
        let nav = navigator(.classic)
        await openCoverFlow(nav)
        nav.handle(.scroll(steps: 1))
        nav.handle(.center)
        XCTAssertEqual(coverFlow(nav)?.flipped, true)
        XCTAssertEqual(coverFlow(nav)?.index, 1)
    }

    func testReopeningReturnsToTheAlbumYouLeftOn() async {
        let nav = navigator(.classic)
        await openCoverFlow(nav)
        nav.handle(.scroll(steps: 1))
        nav.handle(.menu)
        nav.handle(.center)
        XCTAssertEqual(coverFlow(nav)?.index, 1)
        XCTAssertEqual(coverFlow(nav)?.flipped, false)
    }
}
