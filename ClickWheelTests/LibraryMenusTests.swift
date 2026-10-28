import XCTest
@testable import ClickWheel

private struct Boom: Error {}

@MainActor
final class LibraryMenusTests: XCTestCase {
    private var library: FakeMusicLibrary!
    private var music: MenuScreen!

    override func setUp() async throws {
        library = FakeMusicLibrary()
        music = LibraryMenus.musicMenu(library: library, runner: BackgroundRunner(label: "test"))
    }

    private func track(_ id: String, _ name: String, artist: String = "Artist", album: String = "Album",
                       disc: Int = 1, number: Int = 1) -> LibraryTrack {
        LibraryTrack(id: id, name: name, artist: artist, albumArtist: "", album: album, discNumber: disc, trackNumber: number)
    }

    private func load(_ item: MenuItem) async throws -> [MenuItem] {
        guard case .load(_, _, let loader) = item.action else { XCTFail("\(item.label) is not a load"); return [] }
        return try await loader()
    }

    private func play(_ item: MenuItem) async throws {
        guard case .play(let start) = item.action else { return XCTFail("\(item.label) is not a play") }
        try await start()
    }

    private func row(_ items: [MenuItem], _ label: String) -> MenuItem {
        items.first { $0.label == label }!
    }

    func testMusicMenuItems() {
        XCTAssertEqual(music.title, "Music")
        XCTAssertEqual(music.items.map(\.label), ["Playlists", "Artists", "Albums", "Songs"])
        XCTAssertTrue(music.items.allSatisfy(\.opensSubmenu))
    }

    func testPlaylistSongPlaysInPlaylist() async throws {
        library.playlistsResult = [LibraryPlaylist(id: "P1", name: "Road Trip")]
        library.tracksByPlaylist["P1"] = [track("a", "One"), track("b", "Two", artist: "Band"), track("c", "Three")]
        let playlists = try await load(row(music.items, "Playlists"))
        let songs = try await load(row(playlists, "Road Trip"))
        XCTAssertEqual(songs.map(\.label), ["One", "Two", "Three"])
        XCTAssertEqual(songs[1].detail(), "Band")
        try await play(songs[1])
        XCTAssertEqual(library.played, [.playlist(id: "P1", startIndex: 1)])
    }

    func testSamePlaylistNamesPlayOwnTracks() async throws {
        library.playlistsResult = [LibraryPlaylist(id: "A", name: "Mix"), LibraryPlaylist(id: "B", name: "Mix")]
        library.tracksByPlaylist["B"] = [track("x", "Only B")]
        let playlists = try await load(row(music.items, "Playlists"))
        let songs = try await load(playlists[1])
        try await play(songs[0])
        XCTAssertEqual(library.played, [.playlist(id: "B", startIndex: 0)])
    }

    func testAlbumSongQueuesWholeAlbum() async throws {
        let t2 = track("t2", "Second", number: 2), t1 = track("t1", "First", number: 1)
        library.allTracksResult = [t2, t1]
        let albums = try await load(row(music.items, "Albums"))
        XCTAssertEqual(albums.map(\.label), ["Album"])
        XCTAssertEqual(albums[0].detail(), "Artist")
        let songs = try await load(albums[0])
        try await play(songs[1])
        XCTAssertEqual(library.played, [.queue(trackIDs: ["t1", "t2"], startIndex: 1)])
    }

    func testArtistAlbumSongQueuesThatAlbumOnly() async throws {
        library.allTracksResult = [
            track("q1", "Bohemian", artist: "Queen", album: "Greatest Hits", number: 1),
            track("a1", "Waterloo", artist: "ABBA", album: "Greatest Hits", number: 1),
            track("q2", "Radio", artist: "Queen", album: "Greatest Hits", number: 2),
        ]
        let artists = try await load(row(music.items, "Artists"))
        XCTAssertEqual(artists.map(\.label), ["ABBA", "Queen"])
        let albums = try await load(row(artists, "Queen"))
        let songs = try await load(row(albums, "Greatest Hits"))
        try await play(songs[0])
        XCTAssertEqual(library.played, [.queue(trackIDs: ["q1", "q2"], startIndex: 0)])
    }

    func testSongsQueueAllSorted() async throws {
        library.allTracksResult = [track("c", "charlie"), track("a", "Alpha"), track("b", "bravo")]
        let songs = try await load(row(music.items, "Songs"))
        XCTAssertEqual(songs.map(\.label), ["Alpha", "bravo", "charlie"])
        try await play(songs[2])
        XCTAssertEqual(library.played, [.queue(trackIDs: ["a", "b", "c"], startIndex: 2)])
    }

    func testSongsQueueIsBoundedFromPickedSong() async throws {
        library.allTracksResult = (0..<250).map { track(String(format: "id%03d", $0), String(format: "Song %03d", $0)) }
        let songs = try await load(row(music.items, "Songs"))
        try await play(songs[200])
        try await play(songs[10])
        XCTAssertEqual(library.played, [
            .queue(trackIDs: (200..<250).map { String(format: "id%03d", $0) }, startIndex: 0),
            .queue(trackIDs: (10..<110).map { String(format: "id%03d", $0) }, startIndex: 0),
        ])
    }

    func testLoadersPrepareLibrary() async throws {
        _ = try await load(row(music.items, "Playlists"))
        XCTAssertEqual(library.prepareCount, 1)
    }

    func testLoaderErrorPropagates() async {
        library.error = Boom()
        do {
            _ = try await load(row(music.items, "Albums"))
            XCTFail("expected an error")
        } catch {}
    }
}
