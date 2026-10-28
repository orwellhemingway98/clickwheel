import XCTest
@testable import ClickWheel

final class KeyMapTests: XCTestCase {
    func testMappedKeys() {
        XCTAssertEqual(KeyMap.event(forKeyCode: 126), .scroll(steps: -1))
        XCTAssertEqual(KeyMap.event(forKeyCode: 125), .scroll(steps: 1))
        XCTAssertEqual(KeyMap.event(forKeyCode: 36), .center)
        XCTAssertEqual(KeyMap.event(forKeyCode: 53), .menu)
        XCTAssertEqual(KeyMap.event(forKeyCode: 49), .playPause)
    }

    func testUnmappedKeyIsNil() {
        XCTAssertNil(KeyMap.event(forKeyCode: 0))
    }
}
