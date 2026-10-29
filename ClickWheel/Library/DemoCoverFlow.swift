import Foundation

/// Made-up albums with no art, for screenshots (`--snapshot … --demo`), so no
/// real library, artwork or listening history ends up in a published image.
final class DemoCoverFlow: CoverFlowSource {
    func albums() async throws -> [CoverFlowAlbum] {
        (1...12).map { n in
            CoverFlowAlbum(name: "Sample Album \(n)", artist: "ClickWheel",
                           trackIDs: (1...8).map { "demo-\(n)-\($0)" }, trackNames: (1...8).map { "Track \($0)" })
        }
    }

    func play(trackIDs: [String], startIndex: Int) async throws {}

    func artwork(trackID: String) async -> Data? { nil }
}
