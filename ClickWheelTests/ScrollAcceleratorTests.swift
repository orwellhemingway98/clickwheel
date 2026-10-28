import XCTest
@testable import ClickWheel

final class ScrollAcceleratorTests: XCTestCase {
    /// Feeds `count` steps at a constant wheel speed and returns the last multiplier.
    private func multiplier(atDegreesPerSecond speed: Double, count: Int = 8, direction: Int = 1) -> Int {
        var a = ScrollAccelerator()
        let dt = 15 / speed
        var last = 0
        for i in 0..<count { last = a.multiplier(forStep: direction, now: Double(i) * dt) }
        return last
    }

    func testSlowSpinIsOneToOne() { XCTAssertEqual(multiplier(atDegreesPerSecond: 200), 1) }
    func testModerateSpinDoubles() { XCTAssertEqual(multiplier(atDegreesPerSecond: 350), 2) }
    func testFastSpinQuadruples() { XCTAssertEqual(multiplier(atDegreesPerSecond: 450), 4) }
    func testVeryFastSpinIsCapped() { XCTAssertEqual(multiplier(atDegreesPerSecond: 700), 8) }
    func testCounterClockwiseAcceleratesToo() { XCTAssertEqual(multiplier(atDegreesPerSecond: 450, direction: -1), 4) }

    func testFirstStepIsOneToOne() {
        var a = ScrollAccelerator()
        XCTAssertEqual(a.multiplier(forStep: 1, now: 0), 1)
    }

    func testPauseResets() {
        var a = ScrollAccelerator()
        for i in 0..<8 { _ = a.multiplier(forStep: 1, now: Double(i) * 0.02) }
        XCTAssertEqual(a.multiplier(forStep: 1, now: 0.14 + 0.3), 1)
    }

    func testDirectionChangeResets() {
        var a = ScrollAccelerator()
        for i in 0..<8 { _ = a.multiplier(forStep: 1, now: Double(i) * 0.02) }
        XCTAssertEqual(a.multiplier(forStep: -1, now: 0.16), 1)
    }
}
