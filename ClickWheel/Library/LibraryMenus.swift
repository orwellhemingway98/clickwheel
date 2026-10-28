import Foundation

/// Builds the Music menu tree (Playlists / Artists / Albums / Songs) for a library.
/// Each list loads fresh when opened; each song plays in the list it was picked from.
enum LibraryMenus {
    static func musicMenu(library: MusicLibrary, runner: BackgroundRunner) -> MenuScreen {
        let menus = Builder(library: library, runner: runner)
        return MenuScreen(title: "Music", items: [
            MenuItem("Playlists", action: .load(title: "Playlists", empty: "No playlists", loader: menus.playlists)),
            MenuItem("Artists", action: .load(title: "Artists", empty: "No artists", loader: menus.artists)),
            MenuItem("Albums", action: .load(title: "Albums", empty: "No albums", loader: menus.albums)),
            MenuItem("Songs", action: .load(title: "Songs", empty: "No songs", loader: menus.songs)),
        ])
    }

    private struct Builder {
        let library: MusicLibrary
        let runner: BackgroundRunner

        func playlists() async throws -> [MenuItem] {
            let playlists = try await fetch { try $0.playlists() }
            return playlists.map { playlist in
                MenuItem(playlist.name, action: .load(title: playlist.name, empty: "No songs") {
                    let tracks = try await fetch { try $0.tracks(inPlaylist: playlist.id) }
                    return songRows(tracks) { .playlist(id: playlist.id, startIndex: $0) }
                })
            }
        }

        func artists() async throws -> [MenuItem] {
            let tracks = try await fetch { try $0.allTracks() }
            return LibraryIndex.artists(in: tracks).map { artist in
                MenuItem(artist, action: .load(title: artist, empty: "No albums") {
                    LibraryIndex.albums(in: tracks, byArtist: artist).map { albumRow($0, tracks: tracks, showArtist: false) }
                })
            }
        }

        func albums() async throws -> [MenuItem] {
            let tracks = try await fetch { try $0.allTracks() }
            return LibraryIndex.albums(in: tracks).map { albumRow($0, tracks: tracks, showArtist: true) }
        }

        func songs() async throws -> [MenuItem] {
            let sorted = LibraryIndex.sortedSongs(try await fetch { try $0.allTracks() })
            let ids = sorted.map(\.id)
            return songRows(sorted) { .queue(trackIDs: ids, startIndex: $0) }
        }

        private func albumRow(_ album: LibraryAlbum, tracks: [LibraryTrack], showArtist: Bool) -> MenuItem {
            MenuItem(album.name, detail: { showArtist ? album.artist : nil },
                     action: .load(title: album.name, empty: "No songs") {
                         let albumTracks = LibraryIndex.tracks(in: tracks, album: album)
                         let ids = albumTracks.map(\.id)
                         return songRows(albumTracks, artistDetail: false) { .queue(trackIDs: ids, startIndex: $0) }
                     })
        }

        private func songRows(_ tracks: [LibraryTrack], artistDetail: Bool = true,
                              request: @escaping (Int) -> PlayRequest) -> [MenuItem] {
            tracks.enumerated().map { index, track in
                MenuItem(track.name, detail: { artistDetail && !track.artist.isEmpty ? track.artist : nil },
                         action: .play { try await run { try $0.play(request(index)) } })
            }
        }

        /// Prepares the library (launching Music if needed), then fetches off the main thread.
        private func fetch<T>(_ work: @escaping (MusicLibrary) throws -> T) async throws -> T {
            try await run { library in
                try library.prepare()
                return try work(library)
            }
        }

        private func run<T>(_ work: @escaping (MusicLibrary) throws -> T) async throws -> T {
            let library = self.library
            return try await runner.run { try work(library) }
        }
    }
}
