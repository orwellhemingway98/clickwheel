import Foundation

enum SourceID: String, CaseIterable {
    case appleMusic
    case spotify

    var displayName: String {
        switch self {
        case .appleMusic: return "Apple Music"
        case .spotify: return "Spotify"
        }
    }
}

enum PlayerState: Equatable {
    case playing, paused, stopped
}

/// The current track as reported by a music app. Times are in seconds.
struct NowPlayingInfo: Equatable {
    var trackID: String
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var position: Double
    var index: Int?
    var count: Int?
    var source: SourceID
}

struct PlayerSnapshot: Equatable {
    var state: PlayerState
    var track: NowPlayingInfo?
    var volume: Int
}

enum ArtworkRef: Equatable {
    case data(Data)
    case url(URL)
    case none
}
