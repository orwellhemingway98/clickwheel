import XCTest
@testable import ClickWheel

final class CoverFlowStateTests: XCTestCase {
    private func album(_ n: Int, songs: Int = 3) -> CoverFlowAlbum {
        CoverFlowAlbum(name: "A\(n)", artist: "R\(n)",
                       trackIDs: (0..<songs).map { "t\(n)-\($0)" }, trackNames: (0..<songs).map { "S\($0)" })
    }

    private func state(_ count: Int = 5, songs: Int = 3) -> CoverFlowState {
        CoverFlowState(albums: (0..<count).map { album($0, songs: songs) }, loading: false)
    }

    func testArtworkComesFromTheFirstTrack() {
        XCTAssertEqual(album(2).artworkTrackID, "t2-0")
    }

    func testScrollMovesBetweenAlbumsAndStopsAtTheEnds() {
        var s = state()
        s.scroll(2); XCTAssertEqual(s.index, 2)
        s.scroll(10); XCTAssertEqual(s.index, 4)
        s.scroll(-10); XCTAssertEqual(s.index, 0)
    }

    func testCentreFlipsThenPlaysTheChosenSong() {
        var s = state(songs: 4)
        s.scroll(1)
        XCTAssertNil(s.center())
        XCTAssertTrue(s.flipped)
        XCTAssertEqual(s.trackIndex, 0)
        s.scroll(2)
        XCTAssertEqual(s.trackIndex, 2)
        XCTAssertEqual(s.index, 1, "scrolling the back moves the songs, not the albums")
        XCTAssertEqual(s.center(), .play(trackIDs: ["t1-0", "t1-1", "t1-2", "t1-3"], startIndex: 2))
        s.scroll(9); XCTAssertEqual(s.trackIndex, 3)
    }

    func testMenuFlipsBackFirstThenLeaves() {
        var s = state()
        _ = s.center()
        XCTAssertTrue(s.menu())
        XCTAssertFalse(s.flipped)
        XCTAssertFalse(s.menu())
    }

    func testFlippingAgainStartsAtTheFirstSong() {
        var s = state(songs: 5)
        _ = s.center(); s.scroll(3); _ = s.menu()
        _ = s.center()
        XCTAssertEqual(s.trackIndex, 0)
        XCTAssertEqual(s.trackWindowStart, 0)
    }

    func testTheBackShowsSixSongsAndFollowsTheSelection() {
        var s = state(songs: 10)
        _ = s.center()
        s.scroll(7)
        XCTAssertEqual(CoverFlowState.backRows, 6)
        XCTAssertEqual(s.trackWindowStart, 2)
        s.scroll(-7)
        XCTAssertEqual(s.trackWindowStart, 0)
    }

    func testNothingHappensWhileLoadingOrEmpty() {
        var loading = CoverFlowState(albums: [], loading: true)
        loading.scroll(1)
        XCTAssertNil(loading.center())
        XCTAssertFalse(loading.flipped)
        var empty = CoverFlowState(albums: [], loading: false)
        empty.scroll(1)
        XCTAssertEqual(empty.index, 0)
        XCTAssertNil(empty.center())
    }
}
