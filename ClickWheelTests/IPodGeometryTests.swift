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
}
