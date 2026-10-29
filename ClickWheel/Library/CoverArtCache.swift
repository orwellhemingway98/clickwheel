import AppKit

/// Album covers for Cover Flow, by the track they come from. Only the covers
/// near the middle are asked for, and the last `capacity` are remembered;
/// covers that couldn't be loaded aren't, so they're tried again.
@MainActor
final class CoverArtCache: ObservableObject {
    private let capacity: Int
    private let load: (String) async -> Data?
    private var images: [String: NSImage] = [:]
    private var recency: [String] = []

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
        guard let data = await load(trackID), let image = NSImage(data: data) else { return nil }
        images[trackID] = image
        touch(trackID)
        while recency.count > capacity {
            images[recency.removeFirst()] = nil
        }
        return image
    }

    private func touch(_ trackID: String) {
        recency.removeAll { $0 == trackID }
        recency.append(trackID)
    }
}
