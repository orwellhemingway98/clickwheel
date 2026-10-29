import XCTest
@testable import ClickWheel

final class IPodGeometryTests: XCTestCase {
    func testLifeSizeOnBuiltInRetinaDisplay() {
        // MacBook Pro 14": 1512 pt across 301 mm.
        let g = IPodGeometry.lifeSize(screenWidthPoints: 1512, physicalWidthMM: 301)
        XCTAssertEqual(g.pointsPerMM, 1512 / 301, accuracy: 0.0001)
        XCTAssertEqual(g.bodySize.width, 310.4, accuracy: 0.5)
        XCTAssertEqual(g.bodySize.height, 519.9, accuracy: 0.5)
    }

    func testDimensionsFollowApplesDrawing() {
        let g = IPodGeometry(pointsPerMM: 10)
        XCTAssertEqual(g.bodySize, CGSize(width: 618, height: 1035))
        XCTAssertEqual(g.cornerRadius, 68, accuracy: 0.01)
        XCTAssertEqual(g.windowSize.width, 524.2, accuracy: 0.01)
        XCTAssertEqual(g.windowSize.height, 399.4, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 46.9, accuracy: 0.01)
        XCTAssertEqual(g.windowCornerRadius, 10, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 381, accuracy: 0.01)
        XCTAssertEqual(g.wheelCenterY, 730.6, accuracy: 0.01)
        XCTAssertEqual(g.buttonDiameter, 137, accuracy: 0.01)
    }

    func testWindowIsCenteredWithEvenBorder() {
        let g = IPodGeometry(pointsPerMM: 10)
        XCTAssertEqual((g.bodySize.width - g.windowSize.width) / 2, g.windowTop, accuracy: 0.01)
    }

    func testLCDScalesTheClassicDesignSize() {
        let g = IPodGeometry(pointsPerMM: 10)
        XCTAssertEqual(g.lcdSize.width, 499.2, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.height, 374.4, accuracy: 0.01)
        XCTAssertEqual(g.lcdScale, 499.2 / IPodGeometry.lcdDesignSize.width, accuracy: 0.0001)
        XCTAssertEqual(g.lcdSize.width / g.lcdSize.height, 4.0 / 3.0, accuracy: 0.001)
    }

    func testUnknownPhysicalSizeFallsBackToDefault() {
        XCTAssertEqual(IPodGeometry.lifeSize(screenWidthPoints: 1512, physicalWidthMM: 0), .default)
        XCTAssertEqual(IPodGeometry.lifeSize(screenWidthPoints: 1512, physicalWidthMM: 5000), .default)
        XCTAssertEqual(IPodGeometry.lifeSize(screenWidthPoints: 0, physicalWidthMM: 300), .default)
    }

    func testExternalMonitorIsLifeSizeToo() {
        // 27" 4K at "looks like 2560 × 1440", 597 mm wide.
        let g = IPodGeometry.lifeSize(screenWidthPoints: 2560, physicalWidthMM: 597)
        XCTAssertEqual(g.bodySize.width / g.pointsPerMM, 61.8, accuracy: 0.001)
        XCTAssertEqual(g.pointsPerMM, 4.288, accuracy: 0.001)
    }

    // MARK: - Models

    func testFirstGenGeometryAtTen() {
        let g = IPodGeometry(model: .firstGen, pointsPerMM: 10)
        XCTAssertEqual(g.bodySize, CGSize(width: 618, height: 1020))
        XCTAssertEqual(g.cornerRadius, 57, accuracy: 0.01)
        XCTAssertEqual(g.ringDiameter, 521, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 411, accuracy: 0.01)
        XCTAssertEqual(g.buttonDiameter, 207, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 697, accuracy: 0.01)
        XCTAssertEqual(g.windowSize.width, 430, accuracy: 0.01)
        XCTAssertEqual(g.windowSize.height, 356, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 46, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.width, 396.8, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.height, 317.44, accuracy: 0.01)
        XCTAssertEqual(g.designSize, CGSize(width: 160, height: 128))
    }

    func testFifthGenControlCenterIsWheelCenter() {
        let g = IPodGeometry(model: .fifthGen, pointsPerMM: 10)
        XCTAssertEqual(g.controlCenterY, g.wheelCenterY)
        XCTAssertEqual(g.ringDiameter, g.wheelDiameter)
        XCTAssertEqual(g.designSize, IPodGeometry.lcdDesignSize)
    }

    func testPixelCrispOnUsersDisplay() {
        let g = IPodGeometry.lifeSize(model: .firstGen, screenWidthPoints: 1512, physicalWidthMM: 301)
        XCTAssertEqual(g.lcdPixel, 1.25, accuracy: 0.0001)
        XCTAssertEqual(g.pointsPerMM, 1.25 / 0.248, accuracy: 0.0001)
        XCTAssertEqual(g.lcdScale, 1.25, accuracy: 0.0001)
    }

    func testPixelCrispRounding() {
        func pixel(_ density: CGFloat) -> CGFloat {
            IPodGeometry.lifeSize(model: .firstGen, screenWidthPoints: density * 300, physicalWidthMM: 300).lcdPixel
        }
        XCTAssertEqual(pixel(3.6), 1.0, accuracy: 0.0001)
        XCTAssertEqual(pixel(3.2), 0.75, accuracy: 0.0001)
        XCTAssertEqual(pixel(2.0), 0.75, accuracy: 0.0001)
        XCTAssertEqual(pixel(7.0), 1.75, accuracy: 0.0001)
    }

    func testFifthGenLifeSizeUnchangedThroughModelAPI() {
        let g = IPodGeometry.lifeSize(model: .fifthGen, screenWidthPoints: 1512, physicalWidthMM: 301)
        XCTAssertEqual(g.pointsPerMM, 1512 / 301, accuracy: 0.0001)
    }

    func testThirdGenGeometryAtTen() {
        let g = IPodGeometry(model: .thirdGen, pointsPerMM: 10)
        XCTAssertEqual(g.bodySize.height, 1034.9, accuracy: 0.01)
        XCTAssertEqual(g.windowSize.width, 402.9, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 72.35, accuracy: 0.01)
        XCTAssertEqual(g.rowCenterY, 499.1, accuracy: 0.01)
        XCTAssertEqual(g.rowSpacing, 133, accuracy: 0.01)
        XCTAssertEqual(g.rowButtonDiameter, 109, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 387, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 770.8, accuracy: 0.01)
        XCTAssertEqual(g.edgeBand, 59, accuracy: 0.01)
    }

    func testMiniGeometryAtTen() {
        let g = IPodGeometry(model: .mini, pointsPerMM: 10)
        XCTAssertEqual(g.bodySize.width, 514.5, accuracy: 0.01)
        XCTAssertEqual(g.bodySize.height, 916.6, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 62.75, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 629.1, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.width, 303.6, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.height, 242.0, accuracy: 0.01)
        XCTAssertEqual(g.designSize, CGSize(width: 138, height: 110))
    }

    func testMiniIsExactLifeSize() {
        let g = IPodGeometry.lifeSize(model: .mini, screenWidthPoints: 1512, physicalWidthMM: 301)
        XCTAssertEqual(g.pointsPerMM, 1512 / 301, accuracy: 0.0001, "no pixel snapping for the mini")
    }

    func testFourthGenGeometryAtTen() {
        let g = IPodGeometry(model: .fourthGen, pointsPerMM: 10)
        XCTAssertEqual(g.bodySize.width, 618, accuracy: 0.01)
        XCTAssertEqual(g.bodySize.height, 1035, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 65.9, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 710.4, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 420.6, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.width, 384, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.height, 307.2, accuracy: 0.01)
    }

    func testPhotoGeometryAtTen() {
        let g = IPodGeometry(model: .photo, pointsPerMM: 10)
        XCTAssertEqual(g.windowSize.width, 410, accuracy: 0.01)
        XCTAssertEqual(g.windowSize.height, 330.8, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 70.5, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 710.5, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.width, 396, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.height, 316.8, accuracy: 0.01)
        XCTAssertEqual(g.lcdScale, 1.76, accuracy: 0.0001)
    }

    func testNanoGeometryAtTen() {
        let g = IPodGeometry(model: .nano, pointsPerMM: 10)
        XCTAssertEqual(g.bodySize.width, 400, accuracy: 0.01)
        XCTAssertEqual(g.bodySize.height, 900, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 52.7, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 302.3, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 582.1, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.width, 281.6, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.height, 211.2, accuracy: 0.01)
    }

    func testNanoSecondGenGeometryAtTen() {
        let g = IPodGeometry(model: .nanoSecondGen, pointsPerMM: 10)
        XCTAssertEqual(g.windowTop, 42.5, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 301.6, accuracy: 0.01)
        XCTAssertEqual(g.buttonDiameter, 131.1, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 582.5, accuracy: 0.01)
        XCTAssertEqual(g.edgeBand, 43, accuracy: 0.01)
    }

    func testClassicGeometryAtTen() {
        let g = IPodGeometry(model: .classic, pointsPerMM: 10)
        XCTAssertEqual(g.windowSize.width, 520, accuracy: 0.01)
        XCTAssertEqual(g.windowSize.height, 395, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 49.5, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 380, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 731, accuracy: 0.01)
        XCTAssertEqual(g.buttonDiameter, 137, accuracy: 0.01)
    }

    func testNanoThirdGenGeometryAtTen() {
        let g = IPodGeometry(model: .nanoThirdGen, pointsPerMM: 10)
        XCTAssertEqual(g.bodySize.width, 523, accuracy: 0.01)
        XCTAssertEqual(g.bodySize.height, 698, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 52.5, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 270, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 522, accuracy: 0.01)
        XCTAssertEqual(g.buttonDiameter, 132, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.width, 384, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.height, 288, accuracy: 0.01)
    }

    func testNanoFourthGenGeometryAtTen() {
        let g = IPodGeometry(model: .nanoFourthGen, pointsPerMM: 10)
        XCTAssertEqual(g.bodySize.width, 387, accuracy: 0.01)
        XCTAssertEqual(g.bodySize.height, 907, accuracy: 0.01)
        XCTAssertEqual(g.windowTop, 44, accuracy: 0.01)
        XCTAssertEqual(g.wheelDiameter, 285, accuracy: 0.01)
        XCTAssertEqual(g.controlCenterY, 674, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.width, 297.6, accuracy: 0.01)
        XCTAssertEqual(g.lcdSize.height, 396.8, accuracy: 0.01)
    }
}
