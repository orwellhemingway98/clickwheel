import XCTest
@testable import ClickWheel

final class ClickRateLimiterTests: XCTestCase {
    func testClicksAreSpacedAtLeast25ms() {
        var limiter = ClickRateLimiter()
        XCTAssertTrue(limiter.shouldClick(now: 0))
        XCTAssertFalse(limiter.shouldClick(now: 0.01))
        XCTAssertTrue(limiter.shouldClick(now: 0.03))
    }

    func testRefusedClickDoesNotPushTheWindow() {
        var limiter = ClickRateLimiter()
        XCTAssertTrue(limiter.shouldClick(now: 0))
        XCTAssertFalse(limiter.shouldClick(now: 0.02))
        XCTAssertTrue(limiter.shouldClick(now: 0.026))
    }
}
