import XCTest
@testable import ClickWheel

final class ClassicLayoutTests: XCTestCase {
    func testSplitScreenOnTheMainMenuAndMusicOnly() {
        XCTAssertTrue(ClassicLayout.isSplit(depth: 1, title: "iPod"))
        XCTAssertTrue(ClassicLayout.isSplit(depth: 2, title: "Music"))
        XCTAssertFalse(ClassicLayout.isSplit(depth: 2, title: "Settings"))
        XCTAssertFalse(ClassicLayout.isSplit(depth: 3, title: "Music"), "a deeper list called Music is full width")
        XCTAssertFalse(ClassicLayout.isSplit(depth: 3, title: "Playlists"))
    }

    func testTheListTakesTheLeftHalf() {
        XCTAssertEqual(ClassicLayout.listWidth(canvasWidth: 240), 120)
    }

    func testKenBurnsMovesFromRestToItsFurthestPoint() {
        let start = ClassicLayout.kenBurns(phase: 0)
        XCTAssertEqual(start.scale, 1.0)
        XCTAssertEqual(start.offset, .zero)
        let end = ClassicLayout.kenBurns(phase: 1)
        XCTAssertEqual(end.scale, 1.15, accuracy: 0.0001)
        XCTAssertEqual(end.offset, CGSize(width: -8, height: -5))
        let mid = ClassicLayout.kenBurns(phase: 0.5)
        XCTAssertEqual(mid.scale, 1.075, accuracy: 0.0001)
        XCTAssertEqual(mid.offset, CGSize(width: -4, height: -2.5))
        XCTAssertEqual(ClassicLayout.kenBurnsDuration, 14)
    }
}
