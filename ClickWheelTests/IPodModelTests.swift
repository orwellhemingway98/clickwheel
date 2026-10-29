import XCTest
@testable import ClickWheel

final class IPodModelTests: XCTestCase {
    func testFifthGenSpecMatchesCurrentConstants() {
        let s = IPodModel.fifthGen.spec
        XCTAssertEqual(s.body.width, 61.80); XCTAssertEqual(s.body.height, 103.50)
        XCTAssertEqual(s.body.cornerRadius, 6.8)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 52.42, height: 39.94))
        XCTAssertEqual(s.controls.wheelDiameter, 38.10)
        XCTAssertEqual(s.controls.outerDiameter, 38.10)
        XCTAssertEqual(s.controls.buttonDiameter, 13.7)
        XCTAssertEqual(s.controls.centerFromBottom, 30.44)
        XCTAssertEqual(s.controls.sectorsPerStep, 4)
        XCTAssertEqual(s.controls.kind, .clickWheel)
        XCTAssertEqual(s.display.kind, .color)
        XCTAssertEqual(s.firmware.holdMenu, .home)
        XCTAssertTrue(s.firmware.quickScroll)
        XCTAssertEqual(s.firmware.visibleRows, 9)
    }

    func testFirstGenSpec() {
        let s = IPodModel.firstGen.spec
        XCTAssertEqual(s.year, 2001)
        XCTAssertEqual(s.body.width, 61.8); XCTAssertEqual(s.body.height, 102.0)
        XCTAssertEqual(s.body.cornerRadius, 5.7)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 43.0, height: 35.6))
        XCTAssertEqual(s.display.windowTop, 4.6)
        XCTAssertEqual(s.display.pixels, CGSize(width: 160, height: 128))
        XCTAssertEqual(s.display.pixelPitch, 0.248)
        XCTAssertEqual(s.controls.kind, .scrollWheel)
        XCTAssertEqual(s.controls.outerDiameter, 52.1)
        XCTAssertEqual(s.controls.wheelDiameter, 41.1)
        XCTAssertEqual(s.controls.buttonDiameter, 20.7)
        XCTAssertEqual(s.controls.centerFromBottom, 32.3)
        XCTAssertEqual(s.controls.sectorsPerStep, 6)
        XCTAssertEqual(s.firmware.menuStyle, .firstGenLate)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
        XCTAssertFalse(s.firmware.quickScroll)
        XCTAssertTrue(s.firmware.backlight)
        XCTAssertEqual(s.firmware.visibleRows, 6)
        if case .gray = s.display.kind {} else { XCTFail("1G has a gray LCD") }
    }

    func testModelsAreInReleaseOrder() {
        XCTAssertEqual(IPodModel.allCases.map(\.spec.year), IPodModel.allCases.map(\.spec.year).sorted())
        XCTAssertEqual(IPodModel.allCases.map(\.shortName), ["1st gen", "2nd gen", "3rd gen", "mini", "5th gen"])
    }

    func testSecondGenIsTheFirstGenWithATouchWheel() {
        let first = IPodModel.firstGen.spec, second = IPodModel.secondGen.spec
        XCTAssertEqual(second.name, "iPod (2nd generation)")
        XCTAssertEqual(second.year, 2002)
        XCTAssertEqual(second.body, first.body)
        XCTAssertEqual(second.display, first.display)
        XCTAssertEqual(second.firmware, first.firmware)
        XCTAssertEqual(second.controls.kind, .scrollWheel)
        XCTAssertEqual(second.controls.sectorsPerStep, 6)
        XCTAssertTrue(first.controls.wheelTurns, "the 1G wheel physically turns")
        XCTAssertFalse(second.controls.wheelTurns, "the 2G touch wheel stays still")
    }

    func testThirdGenSpecFollowsApplesDrawing() {
        let s = IPodModel.thirdGen.spec
        XCTAssertEqual(s.name, "iPod (3rd generation)")
        XCTAssertEqual(s.year, 2003)
        XCTAssertEqual(s.body.width, 61.80); XCTAssertEqual(s.body.height, 103.49)
        XCTAssertEqual(s.body.edgeBand, 5.9)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 40.29, height: 32.61))
        XCTAssertEqual(s.display.windowTop, 23.54 - 32.61 / 2, accuracy: 0.0001)
        XCTAssertEqual(s.display.pixels, CGSize(width: 160, height: 128))
        XCTAssertEqual(s.controls.kind, .buttonRow)
        XCTAssertEqual(s.controls.wheelDiameter, 38.70)
        XCTAssertEqual(s.controls.outerDiameter, 38.70)
        XCTAssertEqual(s.controls.buttonDiameter, 14.50)
        XCTAssertEqual(s.controls.centerFromBottom, 103.49 - 77.08, accuracy: 0.0001)
        XCTAssertEqual(s.controls.rowButtonDiameter, 10.90)
        XCTAssertEqual(s.controls.rowCenterFromTop, 49.91)
        XCTAssertEqual(s.controls.rowSpacing, 13.3)
        XCTAssertEqual(s.controls.sectorsPerStep, 6)
        XCTAssertFalse(s.controls.wheelTurns)
        XCTAssertEqual(s.firmware.menuStyle, .thirdGenLate)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
        XCTAssertTrue(s.firmware.backlight)
        XCTAssertFalse(s.firmware.quickScroll)
        guard case .gray(let palette) = s.display.kind else { return XCTFail("3G has a gray LCD") }
        XCTAssertEqual(palette.unlitTop, 0x5A915A)
        XCTAssertEqual(palette.litTop, 0xADD8E6)
    }

    func testMiniSpecFollowsApplesDrawing() {
        let s = IPodModel.mini.spec
        XCTAssertEqual(s.name, "iPod mini")
        XCTAssertEqual(s.year, 2004)
        XCTAssertEqual(s.material, .aluminium)
        XCTAssertTrue(s.hasColours)
        XCTAssertEqual(s.body.width, 51.45); XCTAssertEqual(s.body.height, 91.66)
        XCTAssertEqual(s.body.rimWidth, 0)
        XCTAssertEqual(s.body.edgeBand, 8.3)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 33.85, height: 26.19))
        XCTAssertEqual(s.display.windowTop, 91.66 - 72.29 - 26.19 / 2, accuracy: 0.0001)
        XCTAssertEqual(s.display.pixels, CGSize(width: 138, height: 110))
        XCTAssertEqual(s.display.pixelPitch, 0.22)
        XCTAssertFalse(s.display.pixelCrisp)
        XCTAssertEqual(s.display.font, .sans)
        XCTAssertEqual(s.display.nowPlayingLines, 2)
        XCTAssertEqual(s.controls.kind, .clickWheel)
        XCTAssertEqual(s.controls.wheelDiameter, 37.95)
        XCTAssertEqual(s.controls.buttonDiameter, 12.50)
        XCTAssertEqual(s.controls.centerFromBottom, 28.75)
        XCTAssertEqual(s.controls.sectorsPerStep, 6)
        XCTAssertEqual(s.firmware.menuStyle, .thirdGenLate)
        XCTAssertEqual(s.firmware.visibleRows, 5)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
    }

    func testOtherModelsKeepTheirLook() {
        XCTAssertEqual(IPodModel.fifthGen.spec.material, .chromeAcrylic)
        XCTAssertEqual(IPodModel.firstGen.spec.material, .whitePlastic)
        XCTAssertEqual(IPodModel.thirdGen.spec.material, .whitePlastic)
        XCTAssertTrue(IPodModel.firstGen.spec.display.pixelCrisp)
        XCTAssertEqual(IPodModel.firstGen.spec.display.font, .chicago)
        XCTAssertEqual(IPodModel.firstGen.spec.display.nowPlayingLines, 3)
        XCTAssertFalse(IPodModel.thirdGen.spec.hasColours)
    }

    func testMiniColours() {
        XCTAssertEqual(MiniColor.allCases.map(\.label), ["Silver", "Gold", "Pink", "Blue", "Green"])
        XCTAssertEqual(MiniColor.silver.body, 0xC8CACD)
        XCTAssertEqual(MiniColor.pink.wheel, 0xF2DBE2)
    }
}
