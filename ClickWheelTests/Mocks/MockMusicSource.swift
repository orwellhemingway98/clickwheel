import Foundation
@testable import ClickWheel

final class MockMusicSource: MusicSource {
    let id: SourceID
    var displayName: String { id.rawValue }

    var running = true
    var nextSnapshot = PlayerSnapshot(state: .paused, track: nil, volume: 50)
    var snapshotError: MusicSourceError?
    var nextArtwork: ArtworkRef = .none
    private(set) var calls: [String] = []
    private(set) var snapshotCallCount = 0

    init(_ id: SourceID) { self.id = id }

    func isRunning() -> Bool { running }

    var snapshotDelay: TimeInterval = 0

    func snapshot() throws -> PlayerSnapshot {
        snapshotCallCount += 1
        if snapshotDelay > 0 { Thread.sleep(forTimeInterval: snapshotDelay) }
        if let snapshotError { throw snapshotError }
        return nextSnapshot
    }

    func artwork() throws -> ArtworkRef { calls.append("artwork"); return nextArtwork }
    func playPause() throws { calls.append("playPause") }
    func next() throws { calls.append("next") }
    func previous() throws { calls.append("previous") }
    func setVolume(_ value: Int) throws { calls.append("setVolume(\(value))") }

    func set(_ state: PlayerState, volume: Int = 50) {
        let track = state == .stopped ? nil : NowPlayingInfo(
            trackID: "\(id.rawValue)-1", title: "Song", artist: "Artist", album: "Album",
            duration: 200, position: 10, index: nil, count: nil, source: id)
        nextSnapshot = PlayerSnapshot(state: state, track: track, volume: volume)
    }
}
