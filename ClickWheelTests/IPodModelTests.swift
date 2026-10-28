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
        XCTAssertEqual(IPodModel.allCases.map(\.shortName), ["1st gen", "5th gen"])
    }
}
