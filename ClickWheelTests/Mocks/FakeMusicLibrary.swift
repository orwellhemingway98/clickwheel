import Foundation
@testable import ClickWheel

final class FakeMusicLibrary: MusicLibrary {
    var playlistsResult: [LibraryPlaylist] = []
    var tracksByPlaylist: [String: [LibraryTrack]] = [:]
    var allTracksResult: [LibraryTrack] = []
    var error: Error?
    private(set) var prepareCount = 0
    private(set) var played: [PlayRequest] = []

    func prepare() throws {
        prepareCount += 1
        if let error { throw error }
    }

    func playlists() throws -> [LibraryPlaylist] {
        if let error { throw error }
        return playlistsResult
    }

    func tracks(inPlaylist id: String) throws -> [LibraryTrack] {
        if let error { throw error }
        return tracksByPlaylist[id] ?? []
    }

    func allTracks() throws -> [LibraryTrack] {
        if let error { throw error }
        return allTracksResult
    }

    func play(_ request: PlayRequest) throws {
        if let error { throw error }
        played.append(request)
    }

    var artworkByTrack: [String: Data] = [:]

    func artwork(trackID: String) throws -> Data? {
        if let error { throw error }
        return artworkByTrack[trackID]
    }
}
