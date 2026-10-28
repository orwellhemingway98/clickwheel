import XCTest
@testable import ClickWheel

final class TimeFormatTests: XCTestCase {
    func testElapsed() {
        XCTAssertEqual(TimeFormat.elapsed(83), "1:23")
        XCTAssertEqual(TimeFormat.elapsed(5), "0:05")
        XCTAssertEqual(TimeFormat.elapsed(3725), "1:02:05")
    }

    func testElapsedInvalidIsZero() {
        XCTAssertEqual(TimeFormat.elapsed(-4), "0:00")
        XCTAssertEqual(TimeFormat.elapsed(.nan), "0:00")
        XCTAssertEqual(TimeFormat.elapsed(.infinity), "0:00")
    }

    func testRemaining() {
        XCTAssertEqual(TimeFormat.remaining(position: 83, duration: 200), "-1:57")
        XCTAssertEqual(TimeFormat.remaining(position: 250, duration: 200), "-0:00")
        XCTAssertEqual(TimeFormat.remaining(position: 10, duration: 0), "-0:00")
    }

    func testProgressClamped() {
        XCTAssertEqual(TimeFormat.progress(position: 50, duration: 200), 0.25)
        XCTAssertEqual(TimeFormat.progress(position: 250, duration: 200), 1)
        XCTAssertEqual(TimeFormat.progress(position: 10, duration: 0), 0)
        XCTAssertEqual(TimeFormat.progress(position: -5, duration: 200), 0)
        XCTAssertEqual(TimeFormat.progress(position: .nan, duration: 200), 0)
    }
}
