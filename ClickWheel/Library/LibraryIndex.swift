import Foundation

/// Groups and sorts library tracks into the iPod's Artists / Albums / Songs lists.
/// Names compare case-insensitively; the first spelling seen is the one shown.
enum LibraryIndex {
    static func artistName(of track: LibraryTrack) -> String {
        if !track.albumArtist.isEmpty { return track.albumArtist }
        if !track.artist.isEmpty { return track.artist }
        return "Unknown Artist"
    }

    static func albumName(of track: LibraryTrack) -> String {
        track.album.isEmpty ? "Unknown Album" : track.album
    }

    static func artists(in tracks: [LibraryTrack]) -> [String] {
        unique(tracks.map(artistName(of:)), key: { $0.lowercased() })
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func albums(in tracks: [LibraryTrack], byArtist artist: String? = nil) -> [LibraryAlbum] {
        let matching = artist.map { name in tracks.filter { same(artistName(of: $0), name) } } ?? tracks
        let albums = matching.map { LibraryAlbum(name: albumName(of: $0), artist: artistName(of: $0)) }
        return unique(albums, key: { "\($0.name.lowercased())\u{1F}\($0.artist.lowercased())" })
            .sorted {
                let byName = $0.name.localizedCaseInsensitiveCompare($1.name)
                if byName != .orderedSame { return byName == .orderedAscending }
                return $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending
            }
    }

    static func tracks(in tracks: [LibraryTrack], album: LibraryAlbum) -> [LibraryTrack] {
        tracks
            .filter { same(albumName(of: $0), album.name) && same(artistName(of: $0), album.artist) }
            .sorted {
                if $0.discNumber != $1.discNumber { return $0.discNumber < $1.discNumber }
                if $0.trackNumber != $1.trackNumber { return $0.trackNumber < $1.trackNumber }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    /// Every album with its songs, as `albums(in:)` and `tracks(in:album:)` give
    /// them, but grouped in one pass (Cover Flow lists the whole library).
    static func albumsWithTracks(in tracks: [LibraryTrack]) -> [(album: LibraryAlbum, tracks: [LibraryTrack])] {
        func key(_ name: String, _ artist: String) -> String { "\(name.lowercased())\u{1F}\(artist.lowercased())" }
        var byKey: [String: [LibraryTrack]] = [:]
        for track in tracks {
            byKey[key(albumName(of: track), artistName(of: track)), default: []].append(track)
        }
        return albums(in: tracks).map { album in
            let albumTracks = (byKey[key(album.name, album.artist)] ?? []).sorted {
                if $0.discNumber != $1.discNumber { return $0.discNumber < $1.discNumber }
                if $0.trackNumber != $1.trackNumber { return $0.trackNumber < $1.trackNumber }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return (album, albumTracks)
        }
    }

    static func sortedSongs(_ tracks: [LibraryTrack]) -> [LibraryTrack] {
        tracks.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func same(_ a: String, _ b: String) -> Bool {
        a.caseInsensitiveCompare(b) == .orderedSame
    }

    private static func unique<T>(_ items: [T], key: (T) -> String) -> [T] {
        var seen = Set<String>()
        return items.filter { seen.insert(key($0)).inserted }
    }
}
