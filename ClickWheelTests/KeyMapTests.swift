import XCTest
@testable import ClickWheel

final class KeyMapTests: XCTestCase {
    func testArrowsScrollAndRepeat() {
        XCTAssertEqual(KeyMap.keyDown(code: 126, isRepeat: false), .scroll(-1))
        XCTAssertEqual(KeyMap.keyDown(code: 125, isRepeat: true), .scroll(1))
        XCTAssertNil(KeyMap.keyUp(code: 125))
    }

    func testButtonsPressAndRelease() {
        XCTAssertEqual(KeyMap.keyDown(code: 123, isRepeat: false), .press(.previous))
        XCTAssertEqual(KeyMap.keyUp(code: 123), .release(.previous))
        XCTAssertEqual(KeyMap.keyDown(code: 124, isRepeat: false), .press(.next))
        XCTAssertEqual(KeyMap.keyDown(code: 36, isRepeat: false), .press(.center))
        XCTAssertEqual(KeyMap.keyDown(code: 76, isRepeat: false), .press(.center))
        XCTAssertEqual(KeyMap.keyDown(code: 53, isRepeat: false), .press(.menu))
        XCTAssertEqual(KeyMap.keyDown(code: 49, isRepeat: false), .press(.playPause))
    }

    func testKeyRepeatDoesNotRepress() {
        XCTAssertNil(KeyMap.keyDown(code: 124, isRepeat: true))
    }

    func testUnmappedKey() {
        XCTAssertNil(KeyMap.keyDown(code: 0, isRepeat: false))
        XCTAssertNil(KeyMap.keyUp(code: 0))
    }
}
