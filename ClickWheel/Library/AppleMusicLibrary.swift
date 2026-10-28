import AppKit
import os

/// The Apple Music library over AppleScript. Playlists play natively; albums,
/// artists and Songs play through a reusable "ClickWheel" playlist.
final class AppleMusicLibrary: AppleScriptMusicSource, MusicLibrary {
    static let playlistName = "ClickWheel"
    private static let playlistIDKey = "clickWheelPlaylistID"

    private let defaults: UserDefaults
    private let log = Logger(subsystem: "com.mfelouro.ClickWheel", category: "Library")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init(bundleIdentifier: "com.apple.Music", appName: "Music")
    }

    /// The one place ClickWheel launches Music: the user opened the Music menu.
    func prepare() throws {
        guard !isRunning() else { return }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            throw MusicSourceError.notRunning
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        let deadline = Date().addingTimeInterval(10)
        while !isRunning() {
            guard Date() < deadline else { throw MusicSourceError.notRunning }
            Thread.sleep(forTimeInterval: 0.2)
        }
        // Give Music a moment to start answering Apple Events.
        Thread.sleep(forTimeInterval: 1)
    }

    func playlists() throws -> [LibraryPlaylist] {
        let ownID = defaults.string(forKey: Self.playlistIDKey)
        return LibraryOutputParser.playlists(try tell(AppleMusicScripts.playlists).stringValue ?? "")
            .filter { $0.id != ownID && $0.name != Self.playlistName }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func tracks(inPlaylist id: String) throws -> [LibraryTrack] {
        LibraryOutputParser.trackColumns(try tell(AppleMusicScripts.tracks(inPlaylist: id)).stringValue ?? "")
    }

    func allTracks() throws -> [LibraryTrack] {
        let start = Date()
        let tracks = LibraryOutputParser.trackColumns(try tell(AppleMusicScripts.allTracks).stringValue ?? "")
        log.info("allTracks: \(tracks.count) tracks in \(Date().timeIntervalSince(start), format: .fixed(precision: 2))s")
        return tracks
    }

    func play(_ request: PlayRequest) throws {
        switch request {
        case .playlist(let id, let startIndex):
            try tell(AppleMusicScripts.playPlaylist(id: id, startIndex: startIndex))
        case .queue(let trackIDs, let startIndex):
            let script = AppleMusicScripts.queue(trackIDs: trackIDs, startIndex: startIndex,
                                                 knownPlaylistID: defaults.string(forKey: Self.playlistIDKey))
            if let id = try tell(script).stringValue, !id.isEmpty {
                defaults.set(id, forKey: Self.playlistIDKey)
            }
        }
    }
}

/// AppleScript bodies for `AppleMusicLibrary`, run inside `tell application "Music"`.
/// Every interpolated value goes through `quoted(_:)`.
enum AppleMusicScripts {
    static func quoted(_ s: String) -> String {
        "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    static let playlists = """
        with timeout of 10 seconds
        set fs to character id 31
        set out to {}
        repeat with p in (every user playlist whose special kind is none)
            set end of out to (persistent ID of p) & fs & (name of p)
        end repeat
        set AppleScript's text item delimiters to character id 30
        set res to out as string
        set AppleScript's text item delimiters to ""
        return res
        end timeout
        """

    static let allTracks = trackList(source: "library playlist 1")

    static func tracks(inPlaylist id: String) -> String {
        trackList(source: "(first user playlist whose persistent ID is \(quoted(id)))")
    }

    static func playPlaylist(id: String, startIndex: Int) -> String {
        "play track \(startIndex + 1) of (first user playlist whose persistent ID is \(quoted(id)))"
    }

    static func queue(trackIDs: [String], startIndex: Int, knownPlaylistID: String?) -> String {
        let findKnown = knownPlaylistID.map {
            "try\nset q to first user playlist whose persistent ID is \(quoted($0))\nend try"
        } ?? ""
        let ids = "{" + trackIDs.map(quoted).joined(separator: ", ") + "}"
        return """
            with timeout of 10 seconds
            set q to missing value
            \(findKnown)
            if q is missing value then
                try
                    set q to first user playlist whose name is \(quoted(AppleMusicLibrary.playlistName))
                end try
            end if
            if q is missing value then set q to make new user playlist with properties {name:\(quoted(AppleMusicLibrary.playlistName))}
            delete every track of q
            set src to library playlist 1
            repeat with tid in \(ids)
                duplicate (first track of src whose persistent ID is (contents of tid)) to q
            end repeat
            play track \(startIndex + 1) of q
            return persistent ID of q
            end timeout
            """
    }

    /// Fetches each property for every track in one call, then joins each column
    /// with text item delimiters (no per-track loop), for `LibraryOutputParser.trackColumns`.
    private static func trackList(source: String) -> String {
        """
        with timeout of 30 seconds
        set src to \(source)
        set {theIDs, theNames, theArtists, theAlbumArtists, theAlbums, theDiscs, theNumbers} to {persistent ID, name, artist, album artist, album, disc number, track number} of every track of src
        set cs to character id 29
        set AppleScript's text item delimiters to character id 30
        set res to (theIDs as string) & cs & (theNames as string) & cs & (theArtists as string) & cs & (theAlbumArtists as string) & cs & (theAlbums as string) & cs & (theDiscs as string) & cs & (theNumbers as string)
        set AppleScript's text item delimiters to ""
        return res
        end timeout
        """
    }
}
