import XCTest
@testable import ClickWheel

final class ScrollWheelLayoutTests: XCTestCase {
    // 1G diameters at 1 pt per mm.
    private let layout = ScrollWheelLayout(button: 20.7, wheel: 41.1, ring: 52.1)

    private func p(_ degrees: Double, _ r: Double) -> CGPoint {
        CGPoint(x: r * cos(degrees * .pi / 180), y: r * sin(degrees * .pi / 180))
    }

    func testCenterIsSelect() {
        XCTAssertEqual(layout.region(at: .zero), .select)
        XCTAssertEqual(layout.region(at: p(30, 10.35)), .select)
    }

    func testMiddleBandIsTheWheel() {
        XCTAssertEqual(layout.region(at: p(0, 15)), .wheel)
        XCTAssertEqual(layout.region(at: p(200, 20.55)), .wheel)
    }

    func testRingQuadrants() {
        XCTAssertEqual(layout.region(at: p(-90, 23)), .ring(.menu))
        XCTAssertEqual(layout.region(at: p(0, 23)), .ring(.next))
        XCTAssertEqual(layout.region(at: p(90, 23)), .ring(.playPause))
        XCTAssertEqual(layout.region(at: p(180, 23)), .ring(.previous))
    }

    func testOutsideTheRing() {
        XCTAssertEqual(layout.region(at: p(45, 27)), .outside)
    }
}
