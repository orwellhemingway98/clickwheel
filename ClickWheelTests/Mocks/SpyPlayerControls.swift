@testable import ClickWheel

@MainActor
final class SpyPlayerControls: PlayerControlling {
    private(set) var calls: [String] = []
    func playPause() { calls.append("playPause") }
    func next() { calls.append("next") }
    func previous() { calls.append("previous") }
    func adjustVolume(by delta: Int) { calls.append("adjustVolume(\(delta))") }
    func seek(by seconds: Double) { calls.append("seek(\(seconds))") }
    func setPosition(_ seconds: Double) { calls.append("setPosition(\(seconds))") }
    func restartOrPrevious() { calls.append("restartOrPrevious") }
}
