import XCTest
@testable import ClickWheel

@MainActor
final class PlayerHubTests: XCTestCase {
    private var music: MockMusicSource!
    private var spotify: MockMusicSource!
    private var settings: AppSettings!
    private var hub: PlayerHub!
    private var suiteName: String!

    override func setUp() async throws {
        suiteName = "PlayerHubTests-\(UUID().uuidString)"
        settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        music = MockMusicSource(.appleMusic)
        spotify = MockMusicSource(.spotify)
        hub = PlayerHub(sources: [music, spotify], settings: settings)
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    func testNotRunningSourceIsNeverQueried() async {
        spotify.running = false
        await hub.refresh()
        XCTAssertEqual(spotify.snapshotCallCount, 0)
    }

    func testAutoPicksPlayingSource() async {
        music.set(.paused); spotify.set(.playing)
        await hub.refresh()
        XCTAssertEqual(hub.activeSource, .spotify)
        XCTAssertEqual(hub.snapshot?.track?.source, .spotify)
    }

    func testAutoKeepsLastActiveWhenBothPaused() async {
        music.set(.paused); spotify.set(.playing)
        await hub.refresh()
        spotify.set(.paused)
        await hub.refresh()
        XCTAssertEqual(hub.activeSource, .spotify)
    }

    func testAutoBothPlayingKeepsLastActive() async {
        music.set(.paused); spotify.set(.playing)
        await hub.refresh()
        music.set(.playing)
        await hub.refresh()
        XCTAssertEqual(hub.activeSource, .spotify)
    }

    func testAutoBothPlayingFromFreshPicksAppleMusic() async {
        music.set(.playing); spotify.set(.playing)
        await hub.refresh()
        XCTAssertEqual(hub.activeSource, .appleMusic)
    }

    func testAutoNothingActiveYetPicksFirstRunning() async {
        music.running = false; spotify.set(.paused)
        await hub.refresh()
        XCTAssertEqual(hub.activeSource, .spotify)
    }

    func testAutoFreshPrefersSourceWithTrackOverStopped() async {
        music.set(.stopped); spotify.set(.paused)
        await hub.refresh()
        XCTAssertEqual(hub.activeSource, .spotify)
        XCTAssertEqual(hub.snapshot?.track?.title, "Song")
    }

    func testFixedModeIgnoresOtherSource() async {
        settings.sourceMode = .spotify
        music.set(.playing); spotify.set(.paused)
        await hub.refresh()
        XCTAssertEqual(hub.activeSource, .spotify)
    }

    func testAppQuitClearsSnapshot() async {
        music.running = false; spotify.set(.playing)
        await hub.refresh()
        spotify.running = false
        await hub.refresh()
        XCTAssertNil(hub.snapshot)
        XCTAssertNil(hub.activeSource)
    }

    func testPermissionDeniedSetsStatus() async {
        music.running = false
        spotify.snapshotError = .permissionDenied
        await hub.refresh()
        XCTAssertEqual(hub.status, .permissionDenied(.spotify))
        XCTAssertNil(hub.snapshot)
    }

    func testStatusRecoversAfterPermissionGranted() async {
        music.running = false
        spotify.snapshotError = .permissionDenied
        await hub.refresh()
        spotify.snapshotError = nil
        spotify.set(.playing)
        await hub.refresh()
        XCTAssertEqual(hub.status, .ok)
    }

    func testCommandsGoToActiveSource() async {
        music.set(.paused); spotify.set(.playing)
        await hub.refresh()
        hub.playPause()
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls, ["playPause"])
        XCTAssertEqual(music.calls, [])
    }

    func testVolumeClampedAndAdjusted() async {
        music.running = false
        spotify.set(.playing, volume: 98)
        await hub.refresh()
        hub.adjustVolume(by: 6)
        await hub.lastCommand?.value
        spotify.set(.playing, volume: 2)
        await hub.refresh()
        hub.adjustVolume(by: -6)
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls, ["setVolume(100)", "setVolume(0)"])
    }

    func testOverlappingRefreshIsSkipped() async {
        music.running = false
        spotify.set(.playing)
        spotify.snapshotDelay = 0.2
        async let first: Void = hub.refresh()
        async let second: Void = hub.refresh()
        _ = await (first, second)
        XCTAssertEqual(spotify.snapshotCallCount, 1)
    }

    func testRapidVolumeStepsAccumulate() async {
        music.running = false
        spotify.set(.playing, volume: 50)
        await hub.refresh()
        hub.adjustVolume(by: 3)
        hub.adjustVolume(by: 3)
        hub.adjustVolume(by: 3)
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls.filter { $0.hasPrefix("setVolume") }, ["setVolume(53)", "setVolume(56)", "setVolume(59)"])
    }

    func testCommandsWithNoActiveSourceAreNoOps() async {
        music.running = false; spotify.running = false
        await hub.refresh()
        hub.playPause()
        await hub.lastCommand?.value
        XCTAssertEqual(music.calls + spotify.calls, [])
    }

    func testSettingsPersist() {
        settings.sourceMode = .spotify
        settings.clickerEnabled = false
        let reloaded = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        XCTAssertEqual(reloaded.sourceMode, .spotify)
        XCTAssertFalse(reloaded.clickerEnabled)
        XCTAssertTrue(reloaded.keepOnTop)
    }

    // MARK: - Seeking

    private func playSpotify(at position: Double) async {
        music.running = false
        spotify.set(.playing)
        spotify.nextSnapshot.track?.position = position
        await hub.refresh()
    }

    func testSeekClampsToTrack() async {
        await playSpotify(at: 10)
        hub.seek(by: -30)
        await hub.lastCommand?.value
        hub.seek(by: 500)
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls, ["setPosition(0.0)", "setPosition(200.0)"])
    }

    func testRapidSeeksAccumulate() async {
        await playSpotify(at: 10)
        hub.seek(by: 5)
        hub.seek(by: 5)
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls, ["setPosition(15.0)", "setPosition(20.0)"])
    }

    func testRestartOrPreviousAfter3sRestarts() async {
        await playSpotify(at: 5)
        hub.restartOrPrevious()
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls, ["setPosition(0.0)"])
    }

    func testRestartOrPreviousEarlyGoesBack() async {
        await playSpotify(at: 2)
        hub.restartOrPrevious()
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls, ["previous"])
    }

    func testSeekWithoutTrackDoesNothing() async {
        music.running = false
        spotify.set(.stopped)
        await hub.refresh()
        hub.seek(by: 5)
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls, [])
    }

    func testPendingSeekDoesNotCarryIntoTheNextTrack() async {
        await playSpotify(at: 195)
        hub.seek(by: 5)                     // pending 200 on track 1
        spotify.nextSnapshot.track = NowPlayingInfo(trackID: "next", title: "Next", artist: "A", album: "B",
                                                    duration: 180, position: 3, index: nil, count: nil, source: .spotify)
        await hub.lastCommand?.value        // its refresh sees the new track
        hub.seek(by: 5)
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls, ["setPosition(200.0)", "setPosition(8.0)"])
    }

    func testRestartOrPreviousIgnoresAnOldTracksPendingPosition() async {
        await playSpotify(at: 195)
        hub.seek(by: 5)
        spotify.nextSnapshot.track = NowPlayingInfo(trackID: "next", title: "Next", artist: "A", album: "B",
                                                    duration: 180, position: 1, index: nil, count: nil, source: .spotify)
        await hub.lastCommand?.value
        hub.restartOrPrevious()
        await hub.lastCommand?.value
        XCTAssertEqual(spotify.calls.last, "previous")
    }
}
