import XCTest
@testable import ClickWheel

final class BacklightTests: XCTestCase {
    func testWakeLightsForTheTimer() {
        var b = Backlight()
        b.wake(now: 0, timer: .ten)
        XCTAssertTrue(b.isOn)
        b.tick(now: 9.9)
        XCTAssertTrue(b.isOn)
        b.tick(now: 10.1)
        XCTAssertFalse(b.isOn)
    }

    func testOffTimerNeverAutoLightsButToggleWorks() {
        var b = Backlight()
        b.wake(now: 0, timer: .off)
        XCTAssertFalse(b.isOn)
        b.toggle(now: 0, timer: .off)
        XCTAssertTrue(b.isOn)
        b.tick(now: 1000)
        XCTAssertTrue(b.isOn, "a manual toggle with timer Off stays on until toggled off")
    }

    func testAlwaysNeverTimesOut() {
        var b = Backlight()
        b.wake(now: 0, timer: .always)
        b.tick(now: 1000)
        XCTAssertTrue(b.isOn)
    }

    func testToggleWhileOnTurnsOff() {
        var b = Backlight()
        b.wake(now: 0, timer: .ten)
        b.toggle(now: 1, timer: .ten)
        XCTAssertFalse(b.isOn)
    }

    func testToggleWhileOffLightsForTheTimer() {
        var b = Backlight()
        b.toggle(now: 0, timer: .five)
        XCTAssertTrue(b.isOn)
        b.tick(now: 5.1)
        XCTAssertFalse(b.isOn)
    }

    func testWakeExtendsTheDeadline() {
        var b = Backlight()
        b.wake(now: 0, timer: .two)
        b.wake(now: 1.5, timer: .two)
        b.tick(now: 3)
        XCTAssertTrue(b.isOn)
    }

    func testTimerLabelsAndSeconds() {
        XCTAssertEqual(BacklightTimer.allCases.map(\.label), ["Off", "2 s", "5 s", "10 s", "20 s", "Always"])
        XCTAssertEqual(BacklightTimer.ten.seconds, 10)
        XCTAssertNil(BacklightTimer.always.seconds)
        XCTAssertNil(BacklightTimer.off.seconds)
    }
}
