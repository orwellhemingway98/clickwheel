import XCTest
@testable import ClickWheel

final class WheelGestureTrackerTests: XCTestCase {
    private func p(_ deg: Double, r: Double = 50) -> CGPoint {
        let rad = deg * .pi / 180
        return CGPoint(x: r * cos(rad), y: r * sin(rad))
    }

    func testClockwiseTwentyDegreesIsOneStepWithCarry() {
        var t = WheelGestureTracker()
        t.begin(at: p(0))
        XCTAssertEqual(t.move(to: p(20)), 1)
        XCTAssertEqual(t.move(to: p(30)), 1)
    }

    func testCounterClockwiseThirtyDegreesIsMinusTwo() {
        var t = WheelGestureTracker()
        t.begin(at: p(0))
        XCTAssertEqual(t.move(to: p(-30)), -2)
    }

    func testCrossingSeamClockwise() {
        var t = WheelGestureTracker()
        t.begin(at: p(350))
        XCTAssertEqual(t.move(to: p(10)), 1)
    }

    func testCrossingSeamCounterClockwise() {
        var t = WheelGestureTracker()
        t.begin(at: p(10))
        XCTAssertEqual(t.move(to: p(350)), -1)
    }

    func testDirectionChangeCancelsCarry() {
        var t = WheelGestureTracker()
        t.begin(at: p(0))
        XCTAssertEqual(t.move(to: p(10)), 0)
        XCTAssertEqual(t.move(to: p(-10)), 0)
        XCTAssertEqual(t.move(to: p(-25)), -1)
    }

    func testDeadZoneIgnored() {
        var t = WheelGestureTracker()
        t.begin(at: p(0))
        XCTAssertEqual(t.move(to: p(90, r: 5)), 0)
        // Leaving the dead zone re-anchors rather than jumping.
        XCTAssertEqual(t.move(to: p(20)), 0)
        XCTAssertEqual(t.move(to: p(40)), 1)
    }

    func testDragThroughCenterReanchors() {
        var t = WheelGestureTracker()
        t.begin(at: p(0))
        XCTAssertEqual(t.move(to: p(90, r: 5)), 0)
        XCTAssertEqual(t.move(to: p(170)), 0)
        XCTAssertEqual(t.move(to: p(190)), 1)
    }

    func testEndResetsCarry() {
        var t = WheelGestureTracker()
        t.begin(at: p(0))
        _ = t.move(to: p(10))
        t.end()
        t.begin(at: p(0))
        XCTAssertEqual(t.move(to: p(10)), 0)
    }

    func testQuantisedToSectors() {
        var t = WheelGestureTracker()
        t.begin(at: p(0))
        XCTAssertEqual(t.move(to: p(3)), 0)
        XCTAssertEqual(t.move(to: p(15.1)), 1)
    }

    func testLiftWithin150msContinues() {
        var t = WheelGestureTracker()
        t.begin(at: p(0), now: 0.9)
        XCTAssertEqual(t.move(to: p(10)), 0)
        t.end(now: 1.0)
        t.begin(at: p(10), now: 1.1)
        XCTAssertEqual(t.move(to: p(16)), 1)
    }

    func testLiftAfter150msResets() {
        var t = WheelGestureTracker()
        t.begin(at: p(0), now: 0.9)
        XCTAssertEqual(t.move(to: p(10)), 0)
        t.end(now: 1.0)
        t.begin(at: p(10), now: 1.3)
        XCTAssertEqual(t.move(to: p(16)), 0)
    }

    func testSixSectorsPerStepGivesSixteenPerTurn() {
        var t = WheelGestureTracker(sectorsPerStep: 6)
        t.begin(at: p(0))
        XCTAssertEqual(t.move(to: p(90)), 4)
    }
}
