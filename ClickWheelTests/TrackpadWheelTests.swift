import XCTest
@testable import ClickWheel

final class TrackpadWheelTests: XCTestCase {
    func testClockwiseRotationScrollsDown() {
        var t = TrackpadWheel()
        // NSEvent.rotation is counter-clockwise positive, so clockwise is negative.
        XCTAssertEqual(t.rotate(degrees: -10, degreesPerStep: 15), 0)
        XCTAssertEqual(t.rotate(degrees: -10, degreesPerStep: 15), 1)
        XCTAssertEqual(t.rotate(degrees: 40, degreesPerStep: 15), -2)
    }

    func testRotationUsesTheModelsStep() {
        var t = TrackpadWheel()
        XCTAssertEqual(t.rotate(degrees: -45, degreesPerStep: 22.5), 2)
    }

    func testPreciseSwipeOneStepPerTwentyPoints() {
        var t = TrackpadWheel()
        // Swiping up (content moves up, negative delta) goes down the list.
        XCTAssertEqual(t.scroll(deltaY: -15, precise: true, momentum: false), 0)
        XCTAssertEqual(t.scroll(deltaY: -10, precise: true, momentum: false), 1)
        XCTAssertEqual(t.scroll(deltaY: 45, precise: true, momentum: false), -2)
    }

    func testMouseWheelNotchIsOneStep() {
        var t = TrackpadWheel()
        XCTAssertEqual(t.scroll(deltaY: -1, precise: false, momentum: false), 1)
        XCTAssertEqual(t.scroll(deltaY: 3, precise: false, momentum: false), -3)
    }

    func testMomentumIsIgnored() {
        var t = TrackpadWheel()
        XCTAssertEqual(t.scroll(deltaY: -200, precise: true, momentum: true), 0)
    }

    func testReversingDirectionDropsTheRemainder() {
        var t = TrackpadWheel()
        _ = t.scroll(deltaY: -15, precise: true, momentum: false)
        XCTAssertEqual(t.scroll(deltaY: 15, precise: true, momentum: false), 0)
        XCTAssertEqual(t.scroll(deltaY: 5, precise: true, momentum: false), -1)
    }
}
