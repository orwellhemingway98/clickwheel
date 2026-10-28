import XCTest
@testable import ClickWheel

final class AppleMusicScriptsTests: XCTestCase {
    func testQuotedEscapes() {
        XCTAssertEqual(AppleMusicScripts.quoted("a\"b\\c"), "\"a\\\"b\\\\c\"")
    }

    func testQueueScriptQuotesIDsAndUsesOneBasedIndex() {
        let script = AppleMusicScripts.queue(trackIDs: ["AB\"C"], startIndex: 0, knownPlaylistID: "P1")
        XCTAssertTrue(script.contains(AppleMusicScripts.quoted("AB\"C")))
        XCTAssertTrue(script.contains(AppleMusicScripts.quoted("P1")))
        XCTAssertTrue(script.contains("play track 1 of"))
    }

    func testQueueScriptWithoutKnownID() {
        let script = AppleMusicScripts.queue(trackIDs: ["A", "B"], startIndex: 1, knownPlaylistID: nil)
        XCTAssertTrue(script.contains("name is \"ClickWheel\""))
        XCTAssertFalse(script.contains("persistent ID is \"\""))
        XCTAssertTrue(script.contains("play track 2 of"))
    }

    func testPlayPlaylistScript() {
        let script = AppleMusicScripts.playPlaylist(id: "X", startIndex: 4)
        XCTAssertTrue(script.contains("play track 5 of"))
        XCTAssertTrue(script.contains(AppleMusicScripts.quoted("X")))
    }

    func testTracksInPlaylistQuotesID() {
        XCTAssertTrue(AppleMusicScripts.tracks(inPlaylist: "Q\"").contains(AppleMusicScripts.quoted("Q\"")))
    }
}
