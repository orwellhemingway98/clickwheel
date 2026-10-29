import XCTest
@testable import ClickWheel

final class CoverFlowLayoutTests: XCTestCase {
    func testLandscapeSizesAndPlaces() {
        let l = CoverFlowLayout(canvas: CGSize(width: 240, height: 180))
        XCTAssertEqual(l.side, 90)
        XCTAssertEqual(l.centre, CGPoint(x: 120, y: 76))
        XCTAssertEqual(l.card, 126)
        XCTAssertEqual(l.titleY, 152)
        XCTAssertEqual(l.artistY, 167)
    }

    func testPortraitFitsTheNarrowScreen() {
        let l = CoverFlowLayout(canvas: CGSize(width: 180, height: 240))
        XCTAssertEqual(l.side, 76)
        XCTAssertLessThanOrEqual(l.card, 180 - 16)
    }

    func testTheMiddleCoverFacesYouAndTheRestStandAside() {
        let l = CoverFlowLayout(canvas: CGSize(width: 240, height: 180))
        let middle = l.transform(offset: 0)
        XCTAssertEqual(middle.x, 0)
        XCTAssertEqual(middle.rotation, 0)
        let right = l.transform(offset: 1)
        XCTAssertEqual(right.x, 55.8, accuracy: 0.001)
        XCTAssertEqual(right.rotation, -60)
        let left = l.transform(offset: -2)
        XCTAssertEqual(left.x, -(55.8 + 19.8), accuracy: 0.001)
        XCTAssertEqual(left.rotation, 60)
        XCTAssertGreaterThan(middle.z, right.z)
        XCTAssertGreaterThan(right.z, l.transform(offset: 2).z)
        for d in -CoverFlowLayout.drawn...CoverFlowLayout.drawn {
            XCTAssertGreaterThan(l.transform(offset: d).z, 0, "drawn in front of the black background")
        }
    }

    func testTheAlbumTextIsDrawnAboveTheCovers() {
        let l = CoverFlowLayout(canvas: CGSize(width: 240, height: 180))
        XCTAssertGreaterThan(CoverFlowLayout.textZ, l.transform(offset: 0).z)
    }

    func testCoversWaitForTheWheelToSettleBeforeLoading() {
        XCTAssertEqual(CoverFlowLayout.loadDelay, .milliseconds(150))
    }

    func testOnlyNearbyCoversAreDrawnAndLoaded() {
        XCTAssertEqual(CoverFlowLayout.drawn, 4)
        XCTAssertEqual(CoverFlowLayout.loaded, 3)
    }
}
