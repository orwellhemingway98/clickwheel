import Foundation

/// One album in Cover Flow: its songs in album order; the cover comes from the first.
struct CoverFlowAlbum: Equatable {
    let name: String
    let artist: String
    let trackIDs: [String]
    let trackNames: [String]

    var artworkTrackID: String? { trackIDs.first }
}

enum CoverFlowAction: Equatable {
    /// Play the album from this song.
    case play(trackIDs: [String], startIndex: Int)
}

/// Where Cover Flow is: which album is in the middle, and whether it's flipped
/// over to its song list. The wheel moves the albums, or the songs when flipped.
struct CoverFlowState: Equatable {
    /// Songs that fit on the back of a cover.
    static let backRows = 6

    let id = UUID()
    var albums: [CoverFlowAlbum]
    var loading: Bool
    private(set) var index = 0
    private(set) var flipped = false
    private(set) var trackIndex = 0
    private(set) var trackWindowStart = 0

    init(albums: [CoverFlowAlbum], loading: Bool) {
        self.albums = albums
        self.loading = loading
    }

    var current: CoverFlowAlbum? { albums.indices.contains(index) ? albums[index] : nil }

    mutating func scroll(_ steps: Int) {
        guard !loading, let album = current else { return }
        if flipped {
            trackIndex = min(max(trackIndex + steps, 0), max(album.trackIDs.count - 1, 0))
            trackWindowStart = MenuWindow.start(previous: trackWindowStart, selected: trackIndex,
                                                visible: Self.backRows, count: album.trackIDs.count)
        } else {
            index = min(max(index + steps, 0), albums.count - 1)
        }
    }

    /// Flips the cover over, or plays the song picked on its back.
    mutating func center() -> CoverFlowAction? {
        guard !loading, let album = current, !album.trackIDs.isEmpty else { return nil }
        if flipped { return .play(trackIDs: album.trackIDs, startIndex: trackIndex) }
        flipped = true
        trackIndex = 0
        trackWindowStart = 0
        return nil
    }

    /// Flips a flipped cover back and reports it handled; otherwise MENU leaves.
    mutating func menu() -> Bool {
        guard flipped else { return false }
        flipped = false
        return true
    }

    /// Fills a loading screen in place, keeping its identity.
    mutating func loaded(_ albums: [CoverFlowAlbum]) {
        self.albums = albums
        loading = false
        index = 0
        flipped = false
    }

    static func == (a: CoverFlowState, b: CoverFlowState) -> Bool {
        a.id == b.id && a.albums == b.albums && a.loading == b.loading && a.index == b.index
            && a.flipped == b.flipped && a.trackIndex == b.trackIndex && a.trackWindowStart == b.trackWindowStart
    }
}

/// Where Cover Flow gets its albums and plays them.
protocol CoverFlowSource: AnyObject {
    func albums() async throws -> [CoverFlowAlbum]
    func play(trackIDs: [String], startIndex: Int) async throws
}
