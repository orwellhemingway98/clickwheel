import Foundation

enum MusicSourceError: Error, Equatable {
    case permissionDenied
    case notRunning
    case scriptFailed(String)
}

/// A music app ClickWheel can control. Methods are synchronous and may block,
/// so callers run them off the main thread.
protocol MusicSource: AnyObject {
    var id: SourceID { get }
    var displayName: String { get }
    func isRunning() -> Bool
    func snapshot() throws -> PlayerSnapshot
    func artwork() throws -> ArtworkRef
    func playPause() throws
    func next() throws
    func previous() throws
    func setVolume(_ value: Int) throws
}
