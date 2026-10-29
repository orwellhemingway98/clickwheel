import XCTest
@testable import ClickWheel

final class PortraitScreenTests: XCTestCase {
    func testEveryColourModelsRowsFitItsCanvas() {
        for model in IPodModel.allCases where model.spec.display.kind == .color {
            let rows = CGFloat(model.spec.firmware.visibleRows)
            XCTAssertLessThanOrEqual(ScreenTheme.headerHeight + rows * ScreenTheme.rowHeight,
                                     model.spec.display.designSize.height, model.generationName)
        }
    }

    func testTheClassicSplitsOnlyOnALandscapeCanvas() {
        XCTAssertTrue(ClassicLayout.splits(canvas: CGSize(width: 240, height: 180)))
        XCTAssertFalse(ClassicLayout.splits(canvas: CGSize(width: 180, height: 240)))
    }

    func testLandscapeNowPlayingKeepsTodaysPositions() {
        let l = NowPlayingLayout(canvas: CGSize(width: 240, height: 180))
        XCTAssertEqual(l.art, ScreenTheme.artFrame)
        XCTAssertEqual(l.infoOrigin, ScreenTheme.infoOrigin)
        XCTAssertEqual(l.infoWidth, 142)
        XCTAssertFalse(l.centred)
        XCTAssertEqual(l.bar, ScreenTheme.barFrame(canvasWidth: 240))
        XCTAssertEqual(NowPlayingLayout(canvas: CGSize(width: 225, height: 180)).infoWidth, 127)
    }

    func testPortraitNowPlayingStacksArtOverCentredText() {
        let l = NowPlayingLayout(canvas: CGSize(width: 180, height: 240))
        XCTAssertEqual(l.art, CGRect(x: 42, y: 30, width: 96, height: 96))
        XCTAssertEqual(l.infoOrigin, CGPoint(x: 8, y: 146))
        XCTAssertEqual(l.infoWidth, 164)
        XCTAssertTrue(l.centred)
        XCTAssertEqual(l.bar, CGRect(x: 15, y: 196, width: 150, height: 11))
    }
}
