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

    func testAMissingCoverIsNotLookedUpAgain() async {
        var calls = 0
        let cache = CoverArtCache(capacity: 5) { _ in calls += 1; return nil }
        let first = await cache.image(trackID: "a")
        let second = await cache.image(trackID: "a")
        XCTAssertNil(first)
        XCTAssertNil(second)
        XCTAssertEqual(calls, 1, "a big library makes every lookup expensive")
    }

    func testTwoRequestsForTheSameCoverShareOneLookup() async {
        var calls = 0
        let cache = CoverArtCache(capacity: 5) { _ in
            calls += 1
            try? await Task.sleep(for: .milliseconds(50))
            return self.png
        }
        async let one = cache.image(trackID: "a")
        async let two = cache.image(trackID: "a")
        let (a, b) = await (one, two)
        XCTAssertNotNil(a)
        XCTAssertNotNil(b)
        XCTAssertEqual(calls, 1)
    }

    func testBigCoversAreShrunkBeforeTheyAreKept() async {
        let big = NSImage(size: NSSize(width: 1200, height: 1200))
        big.lockFocus(); NSColor.blue.setFill(); NSRect(x: 0, y: 0, width: 1200, height: 1200).fill(); big.unlockFocus()
        let rep = NSBitmapImageRep(data: big.tiffRepresentation!)!
        let data = rep.representation(using: .png, properties: [:])!
        let cache = CoverArtCache(capacity: 5) { _ in data }
        let image = await cache.image(trackID: "a")
        let pixels = image?.representations.first.map { max($0.pixelsWide, $0.pixelsHigh) } ?? 0
        XCTAssertGreaterThan(pixels, 0)
        XCTAssertLessThanOrEqual(pixels, CoverArtCache.maxPixels)
    }

    func testArtworkScriptFindsTheTrackByPersistentID() {
        let script = AppleMusicScripts.artwork(trackID: "ABC123")
        XCTAssertTrue(script.contains("persistent ID is \"ABC123\""))
        XCTAssertTrue(script.contains("raw data of artwork 1"))
    }
}
