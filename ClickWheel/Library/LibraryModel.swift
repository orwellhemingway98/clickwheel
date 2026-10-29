import Foundation

struct LibraryPlaylist: Equatable {
    let id: String
    let name: String
}

struct LibraryTrack: Equatable {
    let id: String          // persistent ID
    let name: String
    let artist: String
    let albumArtist: String
    let album: String
    let discNumber: Int
    let trackNumber: Int
}

struct LibraryAlbum: Hashable {
    let name: String
    let artist: String
}

enum PlayRequest: Equatable {
    /// Play natively inside a playlist; `startIndex` is 0-based.
    case playlist(id: String, startIndex: Int)
    /// Play these tracks in order (via the "ClickWheel" playlist).
    case queue(trackIDs: [String], startIndex: Int)
}

/// A browsable music library. Methods block, so callers run them off the main thread.
protocol MusicLibrary: AnyObject {
    /// Makes the library reachable, launching its app if needed.
    func prepare() throws
    func playlists() throws -> [LibraryPlaylist]
    func tracks(inPlaylist id: String) throws -> [LibraryTrack]
    func allTracks() throws -> [LibraryTrack]
    func play(_ request: PlayRequest) throws
    /// A track's cover art, or nil when it has none (Cover Flow).
    func artwork(trackID: String) throws -> Data?
}
