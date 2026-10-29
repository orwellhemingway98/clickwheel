import XCTest
@testable import ClickWheel

final class LibraryCoverFlowTests: XCTestCase {
    private func track(_ id: String, _ name: String, artist: String, album: String,
                       albumArtist: String = "", disc: Int = 1, number: Int) -> LibraryTrack {
        LibraryTrack(id: id, name: name, artist: artist, albumArtist: albumArtist, album: album,
                     discNumber: disc, trackNumber: number)
    }

    private lazy var tracks: [LibraryTrack] = [
        track("b2", "Second", artist: "Beta", album: "Bravo", number: 2),
        track("a1", "Only", artist: "Alpha", album: "alpha album", number: 1),
        track("b1", "First", artist: "beta", album: "BRAVO", number: 1),
        track("c2", "Disc two", artist: "Gamma", album: "Charlie", disc: 2, number: 1),
        track("c1", "Disc one", artist: "Gamma", album: "Charlie", disc: 1, number: 5),
        track("u1", "Loose", artist: "", album: "", number: 0),
    ]

    func testGroupingInOnePassMatchesTheAlbumsList() {
        let grouped = LibraryIndex.albumsWithTracks(in: tracks)
        XCTAssertEqual(grouped.map(\.album), LibraryIndex.albums(in: tracks))
        for (album, albumTracks) in grouped {
            XCTAssertEqual(albumTracks, LibraryIndex.tracks(in: tracks, album: album), album.name)
        }
    }

    func testCoverFlowAlbumsComeFromTheLibrary() async throws {
        let library = FakeMusicLibrary()
        library.allTracksResult = tracks
        let source = LibraryCoverFlow(library: library, runner: BackgroundRunner(label: "test"))
        let albums = try await source.albums()
        XCTAssertEqual(albums.map(\.name), LibraryIndex.albums(in: tracks).map(\.name))
        let charlie = try XCTUnwrap(albums.first { $0.name == "Charlie" })
        XCTAssertEqual(charlie.trackIDs, ["c1", "c2"])
        XCTAssertEqual(charlie.trackNames, ["Disc one", "Disc two"])
        XCTAssertEqual(library.prepareCount, 1)
    }

    func testPlayingQueuesTheAlbumFromTheChosenSong() async throws {
        let library = FakeMusicLibrary()
        let source = LibraryCoverFlow(library: library, runner: BackgroundRunner(label: "test"))
        try await source.play(trackIDs: ["x", "y", "z"], startIndex: 1)
        XCTAssertEqual(library.played, [LibraryMenus.queueRequest(ids: ["x", "y", "z"], startIndex: 1)])
    }

    func testArtworkComesFromTheLibrary() async {
        let library = FakeMusicLibrary()
        library.artworkByTrack = ["t": Data([1, 2, 3])]
        let source = LibraryCoverFlow(library: library, runner: BackgroundRunner(label: "test"))
        let found = await source.artwork(trackID: "t")
        let missing = await source.artwork(trackID: "nope")
        XCTAssertEqual(found, Data([1, 2, 3]))
        XCTAssertNil(missing)
    }
}
