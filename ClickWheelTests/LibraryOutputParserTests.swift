import XCTest
@testable import ClickWheel

final class LibraryOutputParserTests: XCTestCase {
    private func rec(_ fields: String...) -> String {
        fields.joined(separator: String(LibraryOutputParser.field))
    }

    private func out(_ records: String...) -> String {
        records.joined(separator: String(LibraryOutputParser.record))
    }

    func testParsesTracks() {
        let tracks = LibraryOutputParser.tracks(out(
            rec("A1", "Song", "Artist", "Album Artist", "Album", "2", "5"),
            rec("B2", "Other", "X", "", "Y", "1", "1")))
        XCTAssertEqual(tracks.count, 2)
        XCTAssertEqual(tracks[0], LibraryTrack(id: "A1", name: "Song", artist: "Artist", albumArtist: "Album Artist",
                                               album: "Album", discNumber: 2, trackNumber: 5))
        XCTAssertEqual(tracks[1].id, "B2")
    }

    func testMissingValueAndBlankNumbers() {
        let track = LibraryOutputParser.tracks(rec("A", "S", "missing value", "", "Al", "missing value", ""))[0]
        XCTAssertEqual(track.artist, "")
        XCTAssertEqual(track.discNumber, 0)
        XCTAssertEqual(track.trackNumber, 0)
    }

    func testOddNamesSurvive() {
        let name = "Hey | \"Jude\" 🎸, \\o/"
        let track = LibraryOutputParser.tracks(rec("A", name, "Ar", "", "Al", "1", "3"))[0]
        XCTAssertEqual(track.name, name)
        XCTAssertEqual(track.artist, "Ar")
        XCTAssertEqual(track.trackNumber, 3)
    }

    func testEmptyOutputIsEmptyList() {
        XCTAssertEqual(LibraryOutputParser.tracks(""), [])
        XCTAssertEqual(LibraryOutputParser.playlists(""), [])
    }

    func testMalformedRecordSkipped() {
        let tracks = LibraryOutputParser.tracks(out(
            rec("A", "S", "Ar", "", "Al", "1", "1"),
            rec("bad", "record", "here"),
            rec("B", "S2", "Ar", "", "Al", "1", "2")))
        XCTAssertEqual(tracks.map(\.id), ["A", "B"])
    }

    func testParsesPlaylists() {
        let playlists = LibraryOutputParser.playlists(out(rec("A1", "Road Trip"), rec("B2", "Road Trip")))
        XCTAssertEqual(playlists, [LibraryPlaylist(id: "A1", name: "Road Trip"), LibraryPlaylist(id: "B2", name: "Road Trip")])
    }
}
