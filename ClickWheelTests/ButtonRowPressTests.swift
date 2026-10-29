import XCTest
@testable import ClickWheel

final class ButtonRowPressTests: XCTestCase {
    private let layout = ButtonRowLayout(diameter: 10.9, spacing: 13.3)
    private let onNext = CGPoint(x: 19.95, y: 0)

    func testTapPressesThenReleases() {
        var p = ButtonRowPress()
        XCTAssertEqual(p.changed(start: onNext, location: onNext, layout: layout), .press(.next))
        XCTAssertEqual(p.changed(start: onNext, location: CGPoint(x: 20.5, y: 0.5), layout: layout), nil)
        XCTAssertEqual(p.ended(), .release(.next))
    }

    func testMovingSixPointsCancels() {
        var p = ButtonRowPress()
        _ = p.changed(start: onNext, location: onNext, layout: layout)
        XCTAssertEqual(p.changed(start: onNext, location: CGPoint(x: 19.95, y: 6), layout: layout), .cancel)
        XCTAssertNil(p.ended())
    }

    func testCancelledPressDoesNotComeBack() {
        var p = ButtonRowPress()
        _ = p.changed(start: onNext, location: onNext, layout: layout)
        _ = p.changed(start: onNext, location: CGPoint(x: 19.95, y: 8), layout: layout)
        XCTAssertNil(p.changed(start: onNext, location: onNext, layout: layout), "dragging back must not press again")
        XCTAssertNil(p.ended())
    }

    func testLeavingTheButtonCancels() {
        var p = ButtonRowPress()
        let rim = CGPoint(x: 19.95 + 5, y: 0)          // inside, near the rim
        _ = p.changed(start: rim, location: rim, layout: layout)
        XCTAssertEqual(p.changed(start: rim, location: CGPoint(x: 19.95 + 5.6, y: 0), layout: layout), .cancel)
    }

    func testStartingInAGapDoesNothing() {
        var p = ButtonRowPress()
        XCTAssertNil(p.changed(start: .zero, location: .zero, layout: layout))
        XCTAssertNil(p.changed(start: .zero, location: CGPoint(x: 6.65, y: 0), layout: layout), "sliding onto a button doesn't press it")
        XCTAssertNil(p.ended())
    }

    func testInterruptedGestureCancelsOnce() {
        var p = ButtonRowPress()
        _ = p.changed(start: onNext, location: onNext, layout: layout)
        XCTAssertEqual(p.interrupted(), .cancel)
        XCTAssertNil(p.interrupted())
    }
}
