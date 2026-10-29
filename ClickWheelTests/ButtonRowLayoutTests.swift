import XCTest
@testable import ClickWheel

final class ButtonRowLayoutTests: XCTestCase {
    // 3G at 1 pt per mm.
    private let row = ButtonRowLayout(diameter: 10.9, spacing: 13.3)

    func testEachCentreMapsToItsButton() {
        XCTAssertEqual(row.button(at: CGPoint(x: -19.95, y: 0)), .previous)
        XCTAssertEqual(row.button(at: CGPoint(x: -6.65, y: 0)), .menu)
        XCTAssertEqual(row.button(at: CGPoint(x: 6.65, y: 0)), .playPause)
        XCTAssertEqual(row.button(at: CGPoint(x: 19.95, y: 0)), .next)
    }

    func testInsideTheCircle() {
        XCTAssertEqual(row.button(at: CGPoint(x: -6.65 + 4, y: 3)), .menu)
    }

    func testGapsAndOutsideAreNothing() {
        XCTAssertNil(row.button(at: .zero), "between MENU and ▶❚❚")
        XCTAssertNil(row.button(at: CGPoint(x: 6.65, y: 6)), "below a button")
        XCTAssertNil(row.button(at: CGPoint(x: 27, y: 0)), "past the last button")
    }

    func testCentres() {
        for (center, expected) in zip(row.centers, [-19.95, -6.65, 6.65, 19.95]) {
            XCTAssertEqual(center.x, CGFloat(expected), accuracy: 1e-9)
        }
        XCTAssertEqual(ButtonRowLayout.order, [.previous, .menu, .playPause, .next])
    }
}
