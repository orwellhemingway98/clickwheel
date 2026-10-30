import XCTest
@testable import ClickWheel

/// Checks every model's measurements fit together, so a typo in one spec
/// (a screen bigger than its window, a wheel off the body) is caught here.
final class ModelLayoutSafetyTests: XCTestCase {
    func testScreenFitsInsideItsWindow() {
        for model in IPodModel.allCases {
            let d = model.spec.display
            XCTAssertLessThanOrEqual(d.lcdSize.width, d.windowSize.width, "\(model)")
            XCTAssertLessThanOrEqual(d.lcdSize.height, d.windowSize.height, "\(model)")
        }
    }

    func testWindowSitsOnTheBody() {
        for model in IPodModel.allCases {
            let s = model.spec
            XCTAssertGreaterThan(s.display.windowTop, 0, "\(model)")
            XCTAssertLessThan(s.display.windowSize.width, s.body.width, "\(model)")
            XCTAssertLessThan(s.display.windowTop + s.display.windowSize.height, s.body.height, "\(model)")
        }
    }

    func testControlsSitOnTheBodyBelowTheWindow() {
        for model in IPodModel.allCases {
            let s = model.spec
            let radius = s.controls.outerDiameter / 2
            let centre = s.body.height - s.controls.centerFromBottom
            XCTAssertLessThan(s.controls.outerDiameter, s.body.width, "\(model)")
            XCTAssertLessThan(centre + radius, s.body.height, "\(model)")
            XCTAssertLessThan(s.display.windowTop + s.display.windowSize.height, centre - radius, "\(model)")
            if s.controls.rowButtonDiameter > 0 {
                // The 3G's row of buttons sits between the window and the wheel.
                let row = s.controls.rowCenterFromTop, half = s.controls.rowButtonDiameter / 2
                XCTAssertLessThan(s.display.windowTop + s.display.windowSize.height, row - half, "\(model)")
                XCTAssertLessThan(row + half, centre - radius, "\(model)")
            }
        }
    }

    func testScreenIsLaidOutInItsOwnShape() {
        for model in IPodModel.allCases {
            let d = model.spec.display
            XCTAssertEqual(d.designSize.width / d.designSize.height, d.pixels.width / d.pixels.height,
                           accuracy: 0.01, "\(model)")
        }
    }
}
