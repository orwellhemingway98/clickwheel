import XCTest
@testable import ClickWheel

final class MarqueeTests: XCTestCase {
    func testPausesThenScrollsThenHoldsThenRestarts() {
        XCTAssertEqual(Marquee.offset(elapsed: 0.5, overflow: 40), 0)
        XCTAssertEqual(Marquee.offset(elapsed: 1.5, overflow: 40), 15, accuracy: 0.001)
        XCTAssertEqual(Marquee.offset(elapsed: 2.5, overflow: 40), 40, accuracy: 0.001)
        // Cycle = 1 s pause + 40/30 s scroll + 1 s hold = 3.33 s.
        XCTAssertEqual(Marquee.offset(elapsed: 3.3, overflow: 40), 40, accuracy: 0.001)
        XCTAssertEqual(Marquee.offset(elapsed: 3.4, overflow: 40), 0)
    }

    func testTextThatFitsNeverMoves() {
        XCTAssertEqual(Marquee.offset(elapsed: 5, overflow: 0), 0)
        XCTAssertEqual(Marquee.offset(elapsed: 5, overflow: -10), 0)
    }
}
