import AppKit
import XCTest
@testable import ClickWheel

@MainActor
final class CoverArtCacheTests: XCTestCase {
    private let png: Data = {
        let image = NSImage(size: NSSize(width: 2, height: 2))
        image.lockFocus(); NSColor.red.setFill(); NSRect(x: 0, y: 0, width: 2, height: 2).fill(); image.unlockFocus()
        return NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
    }()

    func testLoadsOnceThenRemembers() async {
        var loads: [String] = []
        let cache = CoverArtCache(capacity: 5) { id in loads.append(id); return self.png }
        let first = await cache.image(trackID: "a")
        let again = await cache.image(trackID: "a")
        XCTAssertNotNil(first)
        XCTAssertNotNil(again)
        XCTAssertEqual(loads, ["a"])
        XCTAssertNotNil(cache.cached("a"))
    }

    func testForgetsTheOldestBeyondCapacity() async {
        let cache = CoverArtCache(capacity: 2) { _ in self.png }
        _ = await cache.image(trackID: "a")
        _ = await cache.image(trackID: "b")
        _ = await cache.image(trackID: "c")
        XCTAssertNil(cache.cached("a"))
        XCTAssertNotNil(cache.cached("c"))
    }

    func testAMissingCoverIsTriedAgainLater() async {
        var calls = 0
        let cache = CoverArtCache(capacity: 5) { _ in calls += 1; return calls == 1 ? nil : self.png }
        let missing = await cache.image(trackID: "a")
        let found = await cache.image(trackID: "a")
        XCTAssertNil(missing)
        XCTAssertNotNil(found)
    }

    func testArtworkScriptFindsTheTrackByPersistentID() {
        let script = AppleMusicScripts.artwork(trackID: "ABC123")
        XCTAssertTrue(script.contains("persistent ID is \"ABC123\""))
        XCTAssertTrue(script.contains("raw data of artwork 1"))
    }
}
