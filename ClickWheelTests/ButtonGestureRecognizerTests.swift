import XCTest
@testable import ClickWheel

final class ButtonGestureRecognizerTests: XCTestCase {
    private var r = ButtonGestureRecognizer()

    override func setUp() { r = ButtonGestureRecognizer() }

    private func tap(_ b: WheelButton) -> [WheelEvent] {
        _ = r.press(b, now: 0)
        return r.poll(now: 0.1) + r.release(b, now: 0.2)
    }

    func testQuickTaps() {
        XCTAssertEqual(tap(.menu), [.menu])
        XCTAssertEqual(tap(.previous), [.previous])
        XCTAssertEqual(tap(.next), [.next])
        XCTAssertEqual(tap(.playPause), [.playPause])
        XCTAssertEqual(tap(.center), [.center])
    }

    func testPollBeforeThresholdDoesNothing() {
        _ = r.press(.menu, now: 0)
        XCTAssertEqual(r.poll(now: 0.79), [])
    }

    func testMenuHoldJumpsHomeOnceAndReleaseIsSilent() {
        _ = r.press(.menu, now: 0)
        XCTAssertEqual(r.poll(now: 0.9), [.menuHold])
        XCTAssertEqual(r.poll(now: 1.5), [])
        XCTAssertEqual(r.release(.menu, now: 2), [])
    }

    func testNextHoldSeeksUntilRelease() {
        _ = r.press(.next, now: 0)
        XCTAssertEqual(r.poll(now: 0.85), [.seekForward(active: true)])
        XCTAssertEqual(r.release(.next, now: 3), [.seekForward(active: false)])
    }

    func testPreviousHoldRewinds() {
        _ = r.press(.previous, now: 0)
        XCTAssertEqual(r.poll(now: 1), [.seekBackward(active: true)])
        XCTAssertEqual(r.release(.previous, now: 2), [.seekBackward(active: false)])
    }

    func testButtonsWithoutHoldStillTapOnLongPress() {
        _ = r.press(.playPause, now: 0)
        XCTAssertEqual(r.poll(now: 2), [])
        XCTAssertEqual(r.release(.playPause, now: 2), [.playPause])
    }

    func testSecondPressCancelsFirstWithoutTap() {
        _ = r.press(.next, now: 0)
        XCTAssertEqual(r.poll(now: 1), [.seekForward(active: true)])
        XCTAssertEqual(r.press(.menu, now: 1.2), [.seekForward(active: false)])
        XCTAssertEqual(r.release(.next, now: 1.3), [])
        XCTAssertEqual(r.release(.menu, now: 1.4), [.menu])
    }

    func testReleaseOfUnpressedButtonIsIgnored() {
        XCTAssertEqual(r.release(.center, now: 1), [])
    }
}
