import Foundation

/// Cover Flow's albums, songs and covers, from the music library.
final class LibraryCoverFlow: CoverFlowSource {
    private let library: MusicLibrary
    private let runner: BackgroundRunner
    /// Covers load on their own queue, so a pile of them never holds up play
    /// or a menu loading on the library's queue.
    private let artworkRunner: BackgroundRunner

    init(library: MusicLibrary, runner: BackgroundRunner,
         artworkRunner: BackgroundRunner = BackgroundRunner(label: "ClickWheel.CoverArt")) {
        self.library = library
        self.runner = runner
        self.artworkRunner = artworkRunner
    }

    func albums() async throws -> [CoverFlowAlbum] {
        let library = self.library
        return try await runner.run {
            try library.prepare()
            return LibraryIndex.albumsWithTracks(in: try library.allTracks()).map { album, tracks in
                CoverFlowAlbum(name: album.name, artist: album.artist,
                               trackIDs: tracks.map(\.id), trackNames: tracks.map(\.name))
            }
        }
    }

    func play(trackIDs: [String], startIndex: Int) async throws {
        let library = self.library
        try await runner.run { try library.play(LibraryMenus.queueRequest(ids: trackIDs, startIndex: startIndex)) }
    }

    /// A cover's image data, or nil (including when the lookup fails).
    func artwork(trackID: String) async -> Data? {
        let library = self.library
        return try? await artworkRunner.run { try library.artwork(trackID: trackID) }
    }
}
