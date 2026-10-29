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
        XCTAssertEqual(IPodModel.allCases.map(\.shortName), ["1st gen", "2nd gen", "3rd gen", "mini", "4th gen", "photo", "mini 2G", "nano", "5th gen", "nano 2G", "classic", "nano 3G"])
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
        let choice = IPodModel.mini.spec.firmware.colours!
        XCTAssertEqual(choice.key, "mini")
        XCTAssertEqual(choice.options.map(\.label), ["Silver", "Gold", "Pink", "Blue", "Green"])
        XCTAssertEqual(choice.options.map(\.id), ["silver", "gold", "pink", "blue", "green"])
        XCTAssertEqual(choice.option("silver")?.body, 0xC8CACD)
        let pink = choice.option("pink")!
        XCTAssertEqual(pink.wheel, 0xF2DBE2)
        XCTAssertEqual(pink.button, pink.wheel)
        XCTAssertEqual(pink.labels, 0x8E9399)
    }

    func testFourthGenColours() {
        let choice = IPodModel.fourthGen.spec.firmware.colours!
        XCTAssertEqual(choice.key, "fourthGen")
        XCTAssertEqual(choice.options.map(\.label), ["White", "U2 Special Edition"])
        let white = choice.options[0], u2 = choice.options[1]
        XCTAssertEqual([white.body, white.wheel, white.button, white.labels], [0xF4F4F2, 0xEEEEEC, 0xF6F6F4, 0x8E9399])
        XCTAssertEqual([u2.body, u2.wheel, u2.button, u2.labels], [0x1B1B1D, 0xC41E2A, 0xC41E2A, 0x1A1A1A])
        XCTAssertNil(choice.option("nope"))
    }

    func testFourthGenSpecFollowsApplesDrawing() {
        let s = IPodModel.fourthGen.spec
        XCTAssertEqual(IPodModel.fourthGen.generationName, "4th generation")
        XCTAssertEqual(s.year, 2004)
        XCTAssertEqual(s.material, .whitePlastic)
        XCTAssertTrue(s.hasColours)
        XCTAssertEqual(s.body.width, 61.80); XCTAssertEqual(s.body.height, 103.50)
        XCTAssertEqual(s.body.cornerRadius, 6.0); XCTAssertEqual(s.body.rimWidth, 0.4)
        XCTAssertEqual(s.body.edgeBand, 5.7)
        XCTAssertEqual(s.body.faceInsetTop, 5.6); XCTAssertEqual(s.body.faceInsetBottom, 6.0)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 41.5, height: 34.0))
        XCTAssertEqual(s.display.windowTop, 23.59 - 34.0 / 2, accuracy: 0.0001)
        XCTAssertEqual(s.display.pixels, CGSize(width: 160, height: 128))
        XCTAssertEqual(s.display.pixelPitch, 0.24)
        XCTAssertTrue(s.display.pixelCrisp)
        XCTAssertEqual(s.display.font, .chicago)
        XCTAssertEqual(s.display.nowPlayingLines, 3)
        XCTAssertEqual(s.controls.kind, .clickWheel)
        XCTAssertEqual(s.controls.wheelDiameter, 42.06)
        XCTAssertEqual(s.controls.buttonDiameter, 13.9)
        XCTAssertEqual(s.controls.centerFromBottom, 103.50 - 71.04, accuracy: 0.0001)
        XCTAssertEqual(s.controls.sectorsPerStep, 6)
        XCTAssertEqual(s.firmware.menuStyle, .thirdGenLate)
        XCTAssertEqual(s.firmware.visibleRows, 6)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
        XCTAssertFalse(s.firmware.quickScroll)
        XCTAssertTrue(s.firmware.backlight)
    }

    func testHasColoursFollowsTheFirmwareProfile() {
        let base = IPodModel.mini.spec
        let spec = ModelSpec(name: "x", year: 2004, body: base.body, display: base.display,
                             controls: base.controls, firmware: base.firmware)
        XCTAssertTrue(spec.hasColours)
        for model in IPodModel.allCases {
            XCTAssertEqual(model.spec.hasColours, model.spec.firmware.colours != nil)
        }
    }

    func testOnlyTheU2FrontIsDark() {
        XCTAssertTrue(ColourChoice.fourthGen.option("u2")!.isDark)
        XCTAssertFalse(ColourChoice.fourthGen.option("white")!.isDark)
        XCTAssertFalse(ColourChoice.mini.options.contains { $0.isDark })
    }

    func testPhotoSpecFollowsApplesDrawing() {
        let s = IPodModel.photo.spec
        XCTAssertEqual(IPodModel.photo.generationName, "iPod photo")
        XCTAssertEqual(s.year, 2004)
        XCTAssertEqual(s.body, IPodModel.fourthGen.spec.body)
        XCTAssertEqual(s.material, .whitePlastic)
        XCTAssertEqual(s.display.kind, .color)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 41.00, height: 33.08))
        XCTAssertEqual(s.display.windowTop, 23.59 - 33.08 / 2, accuracy: 0.0001)
        XCTAssertEqual(s.display.pixels, CGSize(width: 220, height: 176))
        XCTAssertEqual(s.display.pixelPitch, 0.18)
        XCTAssertEqual(s.display.designSize, CGSize(width: 225, height: 180))
        XCTAssertEqual(s.controls.kind, .clickWheel)
        XCTAssertEqual(s.controls.wheelDiameter, 42.06)
        XCTAssertEqual(s.controls.buttonDiameter, 13.9)
        XCTAssertEqual(s.controls.centerFromBottom, 103.50 - 71.05, accuracy: 0.0001)
        XCTAssertEqual(s.firmware.menuStyle, .thirdGenLate)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
        XCTAssertTrue(s.firmware.backlight)
        XCTAssertFalse(s.firmware.quickScroll)
        XCTAssertEqual(s.firmware.visibleRows, 9)
        XCTAssertEqual(s.firmware.colours?.key, "photo")
        XCTAssertEqual(s.firmware.colours?.options, ColourChoice.fourthGen.options)
    }

    func testMiniSecondGenIsTheMiniInBrighterColours() {
        let s = IPodModel.miniSecondGen.spec, mini = IPodModel.mini.spec
        XCTAssertEqual(IPodModel.miniSecondGen.generationName, "iPod mini (2nd gen)")
        XCTAssertEqual(s.year, 2005)
        XCTAssertEqual(s.material, .aluminium)
        XCTAssertEqual(s.body, mini.body)
        XCTAssertEqual(s.display, mini.display)
        XCTAssertEqual(s.controls, mini.controls)
        XCTAssertEqual(s.firmware.menuStyle, mini.firmware.menuStyle)
        XCTAssertEqual(s.firmware.visibleRows, mini.firmware.visibleRows)
        XCTAssertEqual(s.firmware.colours, .miniSecondGen)
    }

    func testMiniSecondGenColours() {
        let choice = ColourChoice.miniSecondGen
        XCTAssertEqual(choice.key, "miniSecondGen")
        XCTAssertEqual(choice.options.map(\.label), ["Silver", "Pink", "Blue", "Green"])
        let rows = choice.options.map { [$0.body, $0.wheel, $0.button, $0.labels] }
        XCTAssertEqual(rows, [[0xC8CACD, 0xE4E5E7, 0xE4E5E7, 0xA6A9AE],
                              [0xEFA6C2, 0xF8DDE8, 0xF8DDE8, 0xE48AAE],
                              [0x86B6E6, 0xD6E6F6, 0xD6E6F6, 0x6A9FD6],
                              [0xA2D27E, 0xDDEFCF, 0xDDEFCF, 0x86BF5E]])
    }

    func testNanoSpecFollowsApplesDrawing() {
        let s = IPodModel.nano.spec
        XCTAssertEqual(IPodModel.nano.generationName, "iPod nano")
        XCTAssertEqual(s.year, 2005)
        XCTAssertEqual(s.material, .chromeAcrylic)
        XCTAssertEqual(s.body.width, 40.00); XCTAssertEqual(s.body.height, 90.00)
        XCTAssertEqual(s.body.cornerRadius, 3.0); XCTAssertEqual(s.body.rimWidth, 0.6)
        XCTAssertEqual(s.display.kind, .color)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 29.57, height: 22.18))
        XCTAssertEqual(s.display.windowTop, 90 - 73.64 - 22.18 / 2, accuracy: 0.0001)
        XCTAssertEqual(s.display.pixels, CGSize(width: 176, height: 132))
        XCTAssertEqual(s.display.pixelPitch, 0.16)
        XCTAssertEqual(s.display.designSize, CGSize(width: 240, height: 180))
        XCTAssertEqual(s.controls.kind, .clickWheel)
        XCTAssertEqual(s.controls.wheelDiameter, 30.23)
        XCTAssertEqual(s.controls.buttonDiameter, 13.0)
        XCTAssertEqual(s.controls.centerFromBottom, 31.79)
        XCTAssertEqual(s.controls.sectorsPerStep, 6)
        XCTAssertEqual(s.firmware.menuStyle, .fifthGen)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
        XCTAssertFalse(s.firmware.quickScroll)
        XCTAssertTrue(s.firmware.backlight)
        XCTAssertEqual(s.firmware.visibleRows, 9)
        XCTAssertEqual(s.firmware.colours, .nano)
    }

    func testNanoColours() {
        let choice = ColourChoice.nano
        XCTAssertEqual(choice.key, "nano")
        XCTAssertEqual(choice.options.map(\.label), ["White", "Black"])
        XCTAssertEqual(choice.options.map { [$0.body, $0.wheel, $0.button, $0.labels] },
                       [[0xF4F4F2, 0xEEEEEC, 0xF6F6F4, 0x8E9399], [0x161618, 0x2B2B2E, 0x2B2B2E, 0x9A9A9E]])
        XCTAssertTrue(choice.options[1].isDark)
    }

    func testNanoSecondGenSpecFollowsApplesDrawing() {
        let s = IPodModel.nanoSecondGen.spec
        XCTAssertEqual(IPodModel.nanoSecondGen.generationName, "iPod nano (2nd gen)")
        XCTAssertEqual(s.year, 2006)
        XCTAssertEqual(s.material, .aluminium)
        XCTAssertEqual(s.body.width, 40.00); XCTAssertEqual(s.body.height, 90.00)
        XCTAssertEqual(s.body.cornerRadius, 0.6); XCTAssertEqual(s.body.rimWidth, 0)
        XCTAssertEqual(s.body.edgeBand, 4.3)
        XCTAssertEqual(s.display.kind, .color)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 31.62, height: 24.04))
        XCTAssertEqual(s.display.windowTop, 4.25)
        XCTAssertEqual(s.display.pixels, IPodModel.nano.spec.display.pixels)
        XCTAssertEqual(s.display.designSize, CGSize(width: 240, height: 180))
        XCTAssertEqual(s.controls.wheelDiameter, 30.16)
        XCTAssertEqual(s.controls.buttonDiameter, 13.11)
        XCTAssertEqual(s.controls.centerFromBottom, 31.75)
        XCTAssertEqual(s.controls.sectorsPerStep, 6)
        XCTAssertEqual(s.firmware.menuStyle, .fifthGen)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
        XCTAssertTrue(s.firmware.backlight)
        XCTAssertFalse(s.firmware.quickScroll)
        XCTAssertEqual(s.firmware.colours, .nanoSecondGen)
    }

    func testNanoSecondGenColours() {
        let choice = ColourChoice.nanoSecondGen
        XCTAssertEqual(choice.key, "nanoSecondGen")
        XCTAssertEqual(choice.options.map(\.label), ["Silver", "Pink", "Green", "Blue", "Black", "(PRODUCT) RED"])
        XCTAssertEqual(choice.options.map(\.body), [0xC8CACD, 0xF0A9C4, 0xA6D274, 0x79B4E3, 0x2A2A2C, 0xC8202F])
        let black = choice.option("black")!
        XCTAssertEqual([black.wheel, black.button, black.labels], [0x1E1E20, 0x1E1E20, 0x9A9A9E])
        XCTAssertTrue(black.isDark)
        for colour in choice.options where colour.id != "black" {
            XCTAssertEqual([colour.wheel, colour.button, colour.labels], [0xF2F2F0, 0xF2F2F0, 0x8E9399], colour.label)
        }
    }

    func testWheelEdgesFollowTheWheelNotTheFront() {
        XCTAssertFalse(ColourChoice.nanoSecondGen.option("red")!.hasDarkWheel, "RED's wheel is white")
        XCTAssertTrue(ColourChoice.nanoSecondGen.option("black")!.hasDarkWheel)
        XCTAssertTrue(ColourChoice.nano.option("black")!.hasDarkWheel)
        XCTAssertTrue(ColourChoice.fourthGen.option("u2")!.hasDarkWheel, "the U2's red wheel keeps its look")
        XCTAssertFalse(ColourChoice.mini.options.contains { $0.hasDarkWheel })
    }

    func testClassicSpecFollowsApplesDrawing() {
        let s = IPodModel.classic.spec
        XCTAssertEqual(IPodModel.classic.generationName, "iPod classic")
        XCTAssertEqual(s.year, 2007)
        XCTAssertEqual(s.material, .aluminium)
        XCTAssertEqual(s.body.width, 61.8); XCTAssertEqual(s.body.height, 103.5)
        XCTAssertEqual(s.body.cornerRadius, 6.8); XCTAssertEqual(s.body.rimWidth, 1.0)
        XCTAssertEqual(s.body.edgeBand, 0)
        XCTAssertEqual(s.display.kind, .color)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 52.0, height: 39.5))
        XCTAssertEqual(s.display.windowTop, 24.7 - 39.5 / 2, accuracy: 0.0001)
        XCTAssertEqual(s.display.pixels, IPodModel.fifthGen.spec.display.pixels)
        XCTAssertEqual(s.display.pixelPitch, IPodModel.fifthGen.spec.display.pixelPitch)
        XCTAssertEqual(s.display.designSize, CGSize(width: 240, height: 180))
        XCTAssertEqual(s.controls.wheelDiameter, 38.0)
        XCTAssertEqual(s.controls.buttonDiameter, 13.7)
        XCTAssertEqual(s.controls.centerFromBottom, 30.4)
        XCTAssertEqual(s.controls.sectorsPerStep, 6)
        XCTAssertEqual(s.firmware.menuStyle, .classic)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
        XCTAssertTrue(s.firmware.backlight)
        XCTAssertFalse(s.firmware.quickScroll)
        XCTAssertEqual(s.firmware.visibleRows, 9)
        XCTAssertEqual(s.firmware.colours, .classic)
    }

    func testClassicColours() {
        let choice = ColourChoice.classic
        XCTAssertEqual(choice.key, "classic")
        XCTAssertEqual(choice.options.map(\.label), ["Silver", "Black"])
        XCTAssertEqual(choice.options.map { [$0.body, $0.wheel, $0.button, $0.labels] },
                       [[0xC9CBCE, 0xE9EAEB, 0xD2D4D7, 0x8E9399], [0x1F2022, 0x18181A, 0x18181A, 0x8E9399]])
        XCTAssertFalse(choice.options[0].hasDarkWheel)
        XCTAssertTrue(choice.options[1].hasDarkWheel)
    }

    func testNanoThirdGenSpecFollowsApplesDrawing() {
        let s = IPodModel.nanoThirdGen.spec
        XCTAssertEqual(IPodModel.nanoThirdGen.generationName, "iPod nano (3rd gen)")
        XCTAssertEqual(s.year, 2007)
        XCTAssertEqual(s.material, .aluminium)
        XCTAssertEqual(s.body.width, 52.3); XCTAssertEqual(s.body.height, 69.8)
        XCTAssertEqual(s.body.cornerRadius, 4.5); XCTAssertEqual(s.body.rimWidth, 0.8)
        XCTAssertEqual(s.body.edgeBand, 0)
        XCTAssertEqual(s.display.kind, .color)
        XCTAssertEqual(s.display.windowSize, CGSize(width: 39.8, height: 29.9))
        XCTAssertEqual(s.display.windowTop, 20.2 - 29.9 / 2, accuracy: 0.0001)
        XCTAssertEqual(s.display.pixels, CGSize(width: 320, height: 240))
        XCTAssertEqual(s.display.pixelPitch, 0.12)
        XCTAssertEqual(s.display.designSize, CGSize(width: 240, height: 180))
        XCTAssertEqual(s.controls.wheelDiameter, 27.0)
        XCTAssertEqual(s.controls.buttonDiameter, 13.2)
        XCTAssertEqual(s.controls.centerFromBottom, 17.6)
        XCTAssertEqual(s.controls.sectorsPerStep, 6)
        XCTAssertEqual(s.firmware.menuStyle, .classic)
        XCTAssertEqual(s.firmware.holdMenu, .toggleBacklight)
        XCTAssertTrue(s.firmware.backlight)
        XCTAssertFalse(s.firmware.quickScroll)
        XCTAssertEqual(s.firmware.colours, .nanoThirdGen)
    }

    func testNanoThirdGenColours() {
        let choice = ColourChoice.nanoThirdGen
        XCTAssertEqual(choice.key, "nanoThirdGen")
        XCTAssertEqual(choice.options.map(\.label), ["Silver", "Black", "Blue", "Green", "Pink", "(PRODUCT) RED"])
        XCTAssertEqual(choice.options.map(\.body), [0xC9CBCE, 0x1F2022, 0x8FC3D8, 0xA9D3A0, 0xEDB3C8, 0xC8202F])
        XCTAssertEqual(choice.options.map(\.hasDarkWheel), [false, true, false, false, false, false])
        XCTAssertTrue(choice.options.allSatisfy { $0.labels == 0x8E9399 })
    }
}
