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
}
