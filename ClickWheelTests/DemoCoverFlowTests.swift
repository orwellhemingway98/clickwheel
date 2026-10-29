import XCTest
@testable import ClickWheel

final class DemoCoverFlowTests: XCTestCase {
    func testDemoAlbumsAreMadeUpAndHaveNoArt() async throws {
        let demo = DemoCoverFlow()
        let albums = try await demo.albums()
        XCTAssertEqual(albums.count, 12)
        XCTAssertTrue(albums.allSatisfy { $0.name.hasPrefix("Sample Album") && $0.artist == "ClickWheel" })
        let art = await demo.artwork(trackID: albums[0].trackIDs[0])
        XCTAssertNil(art)
    }
}
