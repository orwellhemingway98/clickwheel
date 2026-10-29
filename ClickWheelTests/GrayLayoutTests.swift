import XCTest
@testable import ClickWheel

final class GrayLayoutTests: XCTestCase {
    func testFirstGenKeepsItsPositions() {
        for model in [IPodModel.firstGen, .secondGen, .thirdGen] {
            let layout = GrayLayout(model: model)
            XCTAssertEqual(layout.size, CGSize(width: 160, height: 128))
            XCTAssertEqual(layout.rows, 6)
            XCTAssertEqual(layout.infoLinesY, [42, 58, 74])
            XCTAssertEqual(layout.barFrame, CGRect(x: 8, y: 96, width: 144, height: 6))
            XCTAssertEqual(layout.timeY, 106)
            XCTAssertEqual(layout.font, .chicago)
        }
    }

    func testMiniLayout() {
        let layout = GrayLayout(model: .mini)
        XCTAssertEqual(layout.size, CGSize(width: 138, height: 110))
        XCTAssertEqual(layout.rows, 5)
        XCTAssertEqual(layout.infoLinesY, [42, 58])
        XCTAssertEqual(layout.barFrame, CGRect(x: 8, y: 78, width: 122, height: 6))
        XCTAssertEqual(layout.timeY, 88)
        XCTAssertEqual(layout.font, .sans)
    }

    func testMiniRowsFitBelowTheTitle() {
        let layout = GrayLayout(model: .mini)
        XCTAssertLessThanOrEqual(GrayScreenTheme.titleHeight + CGFloat(layout.rows) * GrayScreenTheme.rowHeight,
                                 layout.size.height)
    }
}
