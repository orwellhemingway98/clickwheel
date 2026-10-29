import XCTest
@testable import ClickWheel

final class ColourScreenLayoutTests: XCTestCase {
    func testColourScreenDimsOnlyWhenItsBacklightIsOff() {
        XCTAssertEqual(ScreenTheme.dimming(lit: false, backlight: true), 0.6)
        XCTAssertEqual(ScreenTheme.dimming(lit: true, backlight: true), 0)
    }

    func testModelsWithoutABacklightNeverDim() {
        XCTAssertEqual(ScreenTheme.dimming(lit: false, backlight: false), 0)
    }

    func testNowPlayingFitsTheCanvasWidth() {
        XCTAssertEqual(ScreenTheme.barFrame(canvasWidth: 240), CGRect(x: 15, y: 137, width: 210, height: 11))
        XCTAssertEqual(ScreenTheme.infoWidth(canvasWidth: 240), 142)
        XCTAssertEqual(ScreenTheme.barFrame(canvasWidth: 225), CGRect(x: 15, y: 137, width: 195, height: 11))
        XCTAssertEqual(ScreenTheme.infoWidth(canvasWidth: 225), 127)
    }
}
