import XCTest
@testable import ClickWheel

final class LibraryIndexTests: XCTestCase {
    private var counter = 0

    private func t(_ name: String = "Song", artist: String = "", albumArtist: String = "", album: String = "Album",
                   disc: Int = 1, track: Int = 1) -> LibraryTrack {
        counter += 1
        return LibraryTrack(id: "T\(counter)", name: name, artist: artist, albumArtist: albumArtist,
                            album: album, discNumber: disc, trackNumber: track)
    }

    func testArtistFallbacks() {
        XCTAssertEqual(LibraryIndex.artistName(of: t(artist: "Solo", albumArtist: "Various")), "Various")
        XCTAssertEqual(LibraryIndex.artistName(of: t(artist: "Solo")), "Solo")
        XCTAssertEqual(LibraryIndex.artistName(of: t()), "Unknown Artist")
    }

    func testArtistsDedupedCaseInsensitiveAndSorted() {
        let tracks = [t(artist: "the Beatles"), t(artist: "ABBA"), t(artist: "The Beatles")]
        XCTAssertEqual(LibraryIndex.artists(in: tracks), ["ABBA", "the Beatles"])
    }

    func testAlbumsSameNameDifferentArtistsStaySeparate() {
        let tracks = [t(artist: "Queen", album: "Greatest Hits"), t(artist: "ABBA", album: "Greatest Hits")]
        XCTAssertEqual(LibraryIndex.albums(in: tracks), [
            LibraryAlbum(name: "Greatest Hits", artist: "ABBA"),
            LibraryAlbum(name: "Greatest Hits", artist: "Queen"),
        ])
    }

    func testUnknownAlbum() {
        XCTAssertEqual(LibraryIndex.albums(in: [t(artist: "X", album: "")]), [LibraryAlbum(name: "Unknown Album", artist: "X")])
    }

    func testAlbumsByArtist() {
        let tracks = [t(artist: "Queen", album: "A Night"), t(artist: "ABBA", album: "Arrival")]
        XCTAssertEqual(LibraryIndex.albums(in: tracks, byArtist: "queen"), [LibraryAlbum(name: "A Night", artist: "Queen")])
    }

    func testAlbumTracksMultiDiscOrder() {
        let d2t1 = t("C", artist: "Q", album: "Live", disc: 2, track: 1)
        let d1t2 = t("B", artist: "Q", album: "Live", disc: 1, track: 2)
        let d1t1 = t("A", artist: "Q", album: "Live", disc: 1, track: 1)
        let tieB = t("Z", artist: "Q", album: "Live", disc: 3, track: 1)
        let tieA = t("Y", artist: "Q", album: "Live", disc: 3, track: 1)
        let ordered = LibraryIndex.tracks(in: [d2t1, d1t2, d1t1, tieB, tieA], album: LibraryAlbum(name: "Live", artist: "Q"))
        XCTAssertEqual(ordered.map(\.name), ["A", "B", "C", "Y", "Z"])
    }

    func testAlbumTracksOnlyThatAlbumAndArtist() {
        let queen = t(artist: "Queen", album: "Greatest Hits")
        let abba = t(artist: "ABBA", album: "Greatest Hits")
        XCTAssertEqual(LibraryIndex.tracks(in: [queen, abba], album: LibraryAlbum(name: "Greatest Hits", artist: "Queen")), [queen])
    }

    func testUnknownAlbumTracksMatch() {
        let loose = t(artist: "X", album: "")
        XCTAssertEqual(LibraryIndex.tracks(in: [loose], album: LibraryAlbum(name: "Unknown Album", artist: "X")), [loose])
    }

    func testSortedSongsCaseInsensitive() {
        let songs = LibraryIndex.sortedSongs([t("beta"), t("Alpha"), t("gamma")])
        XCTAssertEqual(songs.map(\.name), ["Alpha", "beta", "gamma"])
    }
}
