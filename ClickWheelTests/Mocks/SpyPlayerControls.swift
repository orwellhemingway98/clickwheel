@testable import ClickWheel

final class SpyPlayerControls: PlayerControlling {
    private(set) var calls: [String] = []
    func playPause() { calls.append("playPause") }
    func next() { calls.append("next") }
    func previous() { calls.append("previous") }
    func adjustVolume(by delta: Int) { calls.append("adjustVolume(\(delta))") }
}
