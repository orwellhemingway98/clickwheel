import Foundation

/// Parses library script output: records joined by ASCII 30, fields by ASCII 31.
/// Records with the wrong number of fields are skipped.
enum LibraryOutputParser {
    static let field: Character = "\u{1F}"
    static let record: Character = "\u{1E}"
    /// Separates whole columns in the column-oriented track format.
    static let column: Character = "\u{1D}"

    static func tracks(_ output: String) -> [LibraryTrack] {
        records(output, fieldCount: 7).map { f in
            LibraryTrack(id: f[0], name: f[1], artist: f[2], albumArtist: f[3], album: f[4],
                         discNumber: Int(f[5]) ?? 0, trackNumber: Int(f[6]) ?? 0)
        }
    }

    /// Column-oriented tracks: seven columns (same order as `tracks`) joined by
    /// ASCII 29, each a list of values joined by ASCII 30. Music can produce this
    /// without a per-track loop, which matters for libraries of thousands of songs.
    /// Columns of different lengths mean the data can't be trusted, so nothing is returned.
    static func trackColumns(_ output: String) -> [LibraryTrack] {
        let columns = output.split(separator: column, omittingEmptySubsequences: false).map { col in
            col.split(separator: record, omittingEmptySubsequences: false)
                .map { $0 == "missing value" ? "" : String($0) }
        }
        // IDs are never empty, so an empty ID column means an empty library.
        guard columns.count == 7, columns[0] != [""] else { return [] }
        let count = columns[0].count
        guard columns.allSatisfy({ $0.count == count }) else { return [] }
        return (0..<count).map { i in
            LibraryTrack(id: columns[0][i], name: columns[1][i], artist: columns[2][i], albumArtist: columns[3][i],
                         album: columns[4][i], discNumber: Int(columns[5][i]) ?? 0, trackNumber: Int(columns[6][i]) ?? 0)
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
