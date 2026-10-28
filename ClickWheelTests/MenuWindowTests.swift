import XCTest
@testable import ClickWheel

final class MenuWindowTests: XCTestCase {
    func testSelectionInsideWindowKeepsStart() {
        XCTAssertEqual(MenuWindow.start(previous: 0, selected: 3, visible: 7, count: 20), 0)
    }

    func testScrollingPastBottomShiftsByOne() {
        XCTAssertEqual(MenuWindow.start(previous: 0, selected: 7, visible: 7, count: 20), 1)
    }

    func testScrollingAboveTopShiftsUp() {
        XCTAssertEqual(MenuWindow.start(previous: 5, selected: 3, visible: 7, count: 20), 3)
    }

    func testShortListAlwaysStartsAtZero() {
        XCTAssertEqual(MenuWindow.start(previous: 4, selected: 1, visible: 7, count: 2), 0)
    }

    func testStartNeverLeavesEmptyRowsAtEnd() {
        XCTAssertEqual(MenuWindow.start(previous: 15, selected: 15, visible: 7, count: 20), 13)
    }
}
