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
        XCTAssertEqual(l.counter, ScreenTheme.counterOrigin)
        XCTAssertEqual(NowPlayingLayout(canvas: CGSize(width: 225, height: 180)).infoWidth, 127)
    }

    func testPortraitNowPlayingStacksCounterArtTextAndBar() {
        let l = NowPlayingLayout(canvas: CGSize(width: 180, height: 240))
        XCTAssertTrue(l.centred)
        XCTAssertEqual(l.counter, CGPoint(x: 0, y: 22), "centred on its own row")
        XCTAssertEqual(l.art, CGRect(x: 50, y: 42, width: 80, height: 80))
        XCTAssertEqual(l.infoOrigin, CGPoint(x: 8, y: 140))
        XCTAssertEqual(l.infoWidth, 164)
        XCTAssertEqual(l.bar, CGRect(x: 15, y: 206, width: 150, height: 11))
        // Measured line heights of the Source Sans 3 stack (title 17.9, two
        // subtitles 15.9, 8.5 apart); the counter's line is about 16.
        let stackTop = l.infoOrigin.y - ScreenTheme.titleTextSize / 2
        XCTAssertLessThan(l.counter.y + 16, l.art.minY, "the counter clears the art")
        XCTAssertGreaterThan(stackTop, l.art.maxY + ScreenTheme.artShadow, "the text clears the art's shadow")
        XCTAssertLessThan(stackTop + 17.9 + 8.5 + 15.9 + 8.5 + 15.9, l.bar.minY, "the album line clears the bar")
        XCTAssertLessThan(l.bar.maxY + ScreenTheme.timeGap + 14, 240, "the times stay on screen")
    }

    func testATallerPortraitScreenGivesTheArtTheExtraRoom() {
        let l = NowPlayingLayout(canvas: CGSize(width: 180, height: 282))
        XCTAssertEqual(l.counter, CGPoint(x: 0, y: 22))
        XCTAssertEqual(l.art, CGRect(x: 29, y: 42, width: 122, height: 122))
        XCTAssertEqual(l.infoOrigin, CGPoint(x: 8, y: 182))
        XCTAssertEqual(l.bar, CGRect(x: 15, y: 248, width: 150, height: 11))
        let stackTop = l.infoOrigin.y - ScreenTheme.titleTextSize / 2
        XCTAssertGreaterThan(stackTop, l.art.maxY + ScreenTheme.artShadow)
        XCTAssertLessThan(stackTop + 17.9 + 8.5 + 15.9 + 8.5 + 15.9, l.bar.minY)
        XCTAssertLessThan(l.bar.maxY + ScreenTheme.timeGap + 14, 282)
    }
}
