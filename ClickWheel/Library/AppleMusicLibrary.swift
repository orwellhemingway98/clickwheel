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
        try fetchTracks(source: AppleMusicScripts.playlistSource(id))
    }

    func allTracks() throws -> [LibraryTrack] {
        let start = Date()
        let tracks = try fetchTracks(source: AppleMusicScripts.librarySource)
        log.info("allTracks: \(tracks.count) tracks in \(Date().timeIntervalSince(start), format: .fixed(precision: 2))s")
        return tracks
    }

    func artwork(trackID: String) throws -> Data? {
        let result = try tell(AppleMusicScripts.artwork(trackID: trackID))
        let data = result.data
        return data.isEmpty || result.descriptorType == typeUnicodeText ? nil : data
    }

    /// Fast column format first; if a tag contains a separator character the
    /// columns won't line up, so fall back to the slower per-track record format.
    private func fetchTracks(source: String) throws -> [LibraryTrack] {
        let columns = try tell(AppleMusicScripts.trackColumns(source: source)).stringValue ?? ""
        if let tracks = LibraryOutputParser.trackColumns(columns) { return tracks }
        log.error("Track columns misaligned; using record format")
        return LibraryOutputParser.tracks(try tell(AppleMusicScripts.trackRecords(source: source)).stringValue ?? "")
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

    static let librarySource = "library playlist 1"

    /// A library track's first artwork, by persistent ID; "" when it has none.
    static func artwork(trackID: String) -> String {
        """
        with timeout of 10 seconds
            try
                return raw data of artwork 1 of (first track of \(librarySource) whose persistent ID is \(quoted(trackID)))
            on error
                return ""
            end try
        end timeout
        """
    }

    static func playlistSource(_ id: String) -> String {
        "(first user playlist whose persistent ID is \(quoted(id)))"
    }

    static func playPlaylist(id: String, startIndex: Int) -> String {
        "play track \(startIndex + 1) of (first user playlist whose persistent ID is \(quoted(id)))"
    }

    static func queue(trackIDs: [String], startIndex: Int, knownPlaylistID: String?) -> String {
        let findKnown = knownPlaylistID.map {
            "try\nset q to first user playlist whose persistent ID is \(quoted($0))\nend try"
        } ?? ""
        let ids = "{" + trackIDs.map(quoted).joined(separator: ", ") + "}"
        // Tracks that can't be copied (deleted, unavailable) are skipped rather than
        // failing the whole queue, so playback starts from the picked track's ID.
        let fill = [
            "repeat with tid in \(ids)",
            "try",
            "duplicate (first track of src whose persistent ID is (contents of tid)) to q",
            "end try",
            "end repeat",
        ].joined(separator: "\n")
        let startID = trackIDs.indices.contains(startIndex) ? trackIDs[startIndex] : (trackIDs.first ?? "")
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
            if (count of tracks of q) > 0 then delete every track of q
            set src to library playlist 1
            \(fill)
            try
                play (first track of q whose persistent ID is \(quoted(startID)))
            on error
                play track 1 of q
            end try
            return persistent ID of q
            end timeout
            """
    }

    /// Slow but separator-proof: one record per track, built in a loop.
    static func trackRecords(source: String) -> String {
        """
        with timeout of 30 seconds
        set fs to character id 31
        set src to \(source)
        set {theIDs, theNames, theArtists, theAlbumArtists, theAlbums, theDiscs, theNumbers} to {persistent ID, name, artist, album artist, album, disc number, track number} of every track of src
        set out to {}
        repeat with i from 1 to count of theIDs
            set end of out to (item i of theIDs) & fs & (item i of theNames) & fs & (item i of theArtists) & fs & (item i of theAlbumArtists) & fs & (item i of theAlbums) & fs & ((item i of theDiscs) as string) & fs & ((item i of theNumbers) as string)
        end repeat
        set AppleScript's text item delimiters to character id 30
        set res to out as string
        set AppleScript's text item delimiters to ""
        return res
        end timeout
        """
    }

    /// Fetches each property for every track in one call, then joins each column
    /// with text item delimiters (no per-track loop), for `LibraryOutputParser.trackColumns`.
    static func trackColumns(source: String) -> String {
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
