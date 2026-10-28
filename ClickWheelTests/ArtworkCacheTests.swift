import AppKit
import XCTest
@testable import ClickWheel

@MainActor
final class ArtworkCacheTests: XCTestCase {
    private let url = URL(string: "https://example.com/a.jpg")!

    private func pngData() -> Data {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        return rep.representation(using: .png, properties: [:])!
    }

    func testCacheHitDoesNotRefetch() async {
        let source = MockMusicSource(.spotify)
        source.nextArtwork = .url(url)
        var fetches = 0
        let data = pngData()
        let cache = ArtworkCache(fetchURL: { _ in fetches += 1; return data })
        let first = await cache.image(trackID: "a", source: source)
        let second = await cache.image(trackID: "a", source: source)
        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertEqual(fetches, 1)
        XCTAssertEqual(source.calls.filter { $0 == "artwork" }.count, 1)
    }

    func testDataArtworkNeedsNoFetch() async {
        let source = MockMusicSource(.appleMusic)
        source.nextArtwork = .data(pngData())
        var fetches = 0
        let cache = ArtworkCache(fetchURL: { _ in fetches += 1; return Data() })
        let image = await cache.image(trackID: "a", source: source)
        XCTAssertNotNil(image)
        XCTAssertEqual(fetches, 0)
    }

    func testFailureNotCached() async {
        let source = MockMusicSource(.spotify)
        source.nextArtwork = .url(url)
        var fetches = 0
        let data = pngData()
        let cache = ArtworkCache(fetchURL: { _ in
            fetches += 1
            if fetches == 1 { throw URLError(.notConnectedToInternet) }
            return data
        })
        let first = await cache.image(trackID: "a", source: source)
        let second = await cache.image(trackID: "a", source: source)
        XCTAssertNil(first)
        XCTAssertNotNil(second)
        XCTAssertEqual(fetches, 2)
    }

    func testEvictsBeyondCapacity() async {
        let source = MockMusicSource(.spotify)
        source.nextArtwork = .url(url)
        var fetches = 0
        let data = pngData()
        let cache = ArtworkCache(capacity: 2, fetchURL: { _ in fetches += 1; return data })
        for id in ["a", "b", "c", "a"] { _ = await cache.image(trackID: id, source: source) }
        XCTAssertEqual(fetches, 4)
    }

    func testRecentlyUsedSurvivesEviction() async {
        let source = MockMusicSource(.spotify)
        source.nextArtwork = .url(url)
        var fetches = 0
        let data = pngData()
        let cache = ArtworkCache(capacity: 2, fetchURL: { _ in fetches += 1; return data })
        for id in ["a", "b", "a", "c", "a"] { _ = await cache.image(trackID: id, source: source) }
        XCTAssertEqual(fetches, 3)
    }
}
