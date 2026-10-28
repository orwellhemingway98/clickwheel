import Foundation

/// Parses library script output: records joined by ASCII 30, fields by ASCII 31.
/// Records with the wrong number of fields are skipped.
enum LibraryOutputParser {
    static let field: Character = "\u{1F}"
    static let record: Character = "\u{1E}"

    static func tracks(_ output: String) -> [LibraryTrack] {
        records(output, fieldCount: 7).map { f in
            LibraryTrack(id: f[0], name: f[1], artist: f[2], albumArtist: f[3], album: f[4],
                         discNumber: Int(f[5]) ?? 0, trackNumber: Int(f[6]) ?? 0)
        }
    }

    static func playlists(_ output: String) -> [LibraryPlaylist] {
        records(output, fieldCount: 2).map { LibraryPlaylist(id: $0[0], name: $0[1]) }
    }

    private static func records(_ output: String, fieldCount: Int) -> [[String]] {
        guard !output.isEmpty else { return [] }
        return output.split(separator: record, omittingEmptySubsequences: true).compactMap { line in
            let fields = line.split(separator: field, omittingEmptySubsequences: false)
                .map { $0 == "missing value" ? "" : String($0) }
            return fields.count == fieldCount ? fields : nil
        }
    }
}
