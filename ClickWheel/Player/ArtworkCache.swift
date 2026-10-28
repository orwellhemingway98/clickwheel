import AppKit

/// Remembers album art per track so the screen doesn't refetch (or flicker)
/// on every poll. Failed lookups aren't cached, so they're retried later.
@MainActor
final class ArtworkCache: ObservableObject {
    private let capacity: Int
    private let fetchURL: (URL) async throws -> Data
    private var images: [String: NSImage] = [:]
    private var recency: [String] = []

    init(capacity: Int = 20,
         fetchURL: @escaping (URL) async throws -> Data = { try await URLSession.shared.data(from: $0).0 }) {
        self.capacity = capacity
        self.fetchURL = fetchURL
    }

    func image(trackID: String, source: MusicSource) async -> NSImage? {
        if let cached = images[trackID] {
            touch(trackID)
            return cached
        }
        let ref = await Task.detached { try? source.artwork() }.value ?? .none
        let data: Data?
        switch ref {
        case .data(let raw): data = raw
        case .url(let url): data = try? await fetchURL(url)
        case .none: data = nil
        }
        guard let data, let image = NSImage(data: data) else { return nil }
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
