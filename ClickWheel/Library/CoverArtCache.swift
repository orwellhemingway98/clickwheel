import AppKit
import ImageIO

/// Album covers for Cover Flow, by the track they come from. Lookups are
/// expensive on a big library, so each cover is asked for once: two requests
/// share one lookup, a cover that has no art isn't asked for again, and covers
/// are shrunk to `maxPixels` before the last `capacity` are kept.
@MainActor
final class CoverArtCache: ObservableObject {
    /// Plenty for a cover drawn at most ~130 points wide at 2×.
    nonisolated static let maxPixels = 400

    private let capacity: Int
    private let load: (String) async -> Data?
    private var images: [String: NSImage] = [:]
    private var recency: [String] = []
    private var misses: Set<String> = []
    private var inFlight: [String: Task<NSImage?, Never>] = [:]

    init(capacity: Int = 60, load: @escaping (String) async -> Data?) {
        self.capacity = capacity
        self.load = load
    }

    /// Already loaded, without waiting.
    func cached(_ trackID: String) -> NSImage? { images[trackID] }

    func image(trackID: String) async -> NSImage? {
        if let image = images[trackID] {
            touch(trackID)
            return image
        }
        if misses.contains(trackID) { return nil }
        if let running = inFlight[trackID] { return await running.value }
        let load = self.load
        let task = Task { () -> NSImage? in
            guard let data = await load(trackID) else { return nil }
            return await Task.detached { Self.thumbnail(data) }.value
        }
        inFlight[trackID] = task
        let image = await task.value
        inFlight[trackID] = nil
        guard let image else {
            misses.insert(trackID)
            return nil
        }
        images[trackID] = image
        touch(trackID)
        while recency.count > capacity {
            images[recency.removeFirst()] = nil
        }
        return image
    }

    /// Decodes straight to a small image, never holding the full-size artwork.
    nonisolated private static func thumbnail(_ data: Data) -> NSImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: maxPixels,
              ] as CFDictionary) else { return nil }
        // A bitmap rep keeps the thumbnail's own pixels (a CGImage-backed
        // NSImage reports the screen's scale instead).
        let rep = NSBitmapImageRep(cgImage: cg)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }

    private func touch(_ trackID: String) {
        recency.removeAll { $0 == trackID }
        recency.append(trackID)
    }
}
