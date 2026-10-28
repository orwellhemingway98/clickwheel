# ClickWheel Stage 2: Apple Music Menus (Design Spec)

**Date:** 2026-10-28
**Status:** Draft, awaiting review
**Parent spec:** `docs/superpowers/specs/2026-10-28-clickwheel-design.md` (stage 2 of 4)

## 1. Purpose

Let the user browse their Apple Music **library** with the click wheel and play
songs the way an iPod did: a song keeps playing through the list it was picked
from.

### What the user said
- Build the Apple Music menus now; Spotify menus come later (stage 3).
- The library is small: a few playlists and some saved albums.
- Songs continue in the context they were picked from: an album continues with
  the album, a playlist with the playlist.
- Albums, artists and the Songs list use a "ClickWheel" playlist in the user's
  library (option A). The user accepted that it appears in the Music sidebar
  and syncs via iCloud.

### Success criteria
- Music → Playlists / Artists / Albums / Songs lists the user's real library.
- Picking a song plays it in context and shows Now Playing. ⏮/⏭ move within that context.
- No menu blocks the wheel while it loads. Empty or failed loads say so on screen.

### Non-goals
- Browsing or searching the Apple Music **catalog** (needs MusicKit plus a paid developer account).
- Shuffle items, "All Songs" under an artist, ratings, podcasts, audiobooks.
- Caching. The library is small, so every menu reads fresh from Music.
- Spotify library (stage 3).

## 2. Menu tree

```
ClickWheel
├─ Music
│   ├─ Playlists › <playlist> › <songs>
│   ├─ Artists   › <artist>   › <albums> › <songs>
│   ├─ Albums    › <album>    › <songs>
│   └─ Songs     › <all songs>
├─ Now Playing
└─ Settings
```

| List | Contents | Sort | Row detail |
|------|----------|------|-----------|
| Playlists | User playlists, excluding folders and the ClickWheel playlist | Name, case-insensitive | none |
| Playlist songs | Tracks of that playlist | Playlist order | artist |
| Artists | Distinct album artist (fall back to artist when empty; "Unknown Artist" when both are empty) | Name, case-insensitive | none |
| Artist's albums | Albums whose album artist matches | Album name | none |
| Albums | Distinct (album, album artist) pairs; empty album name → "Unknown Album" | Album name, then artist | artist |
| Album songs | Tracks of that album | Disc number, then track number, then name | none |
| Songs | Every track in the library | Name, case-insensitive | artist |

Submenu rows show `›`. Song rows don't.

## 3. Behavior

- **Selecting a song** issues a play request (§4.2), then pushes Now Playing.
  MENU from Now Playing returns to the list, with the selection where it was.
- **Opening Music while the Music app is closed** launches Music. This is the one
  place ClickWheel launches an app, because the user explicitly asked to browse it.
  Polling still never launches anything.
- **Loading:** a list screen appears immediately with one non-selectable
  "Loading…" row and fills in when the data arrives. If the user has left that
  screen by then, the result is discarded.
- **Empty list:** a single non-selectable row: "No playlists", "No artists",
  "No albums" or "No songs".
- **Load failure:** a single non-selectable row "Couldn't load library". If the
  failure is permission denied, the existing hub status shows the
  permission message on Now Playing.
- **Play failure:** the screen stays on the list (no push to Now Playing) and
  the error is logged.

## 4. Architecture

### 4.1 `MusicLibrary` protocol (new)

Separate from `MusicSource`, so playback control and browsing stay independent.
Spotify will implement it in stage 3.

```swift
struct LibraryPlaylist: Equatable { let id: String; let name: String }
struct LibraryTrack: Equatable {
    let id: String          // persistent ID
    let name: String
    let artist: String
    let albumArtist: String
    let album: String
    let discNumber: Int
    let trackNumber: Int
}
struct LibraryAlbum: Hashable { let name: String; let artist: String }

enum PlayRequest: Equatable {
    case playlist(id: String, startIndex: Int)          // native, 0-based
    case queue(trackIDs: [String], startIndex: Int)     // via the ClickWheel playlist
}

protocol MusicLibrary: AnyObject {
    func prepare() throws                               // launches the app if needed
    func playlists() throws -> [LibraryPlaylist]
    func tracks(inPlaylist id: String) throws -> [LibraryTrack]
    func allTracks() throws -> [LibraryTrack]
    func play(_ request: PlayRequest) throws
}
```

Artists, albums and album tracks are derived from `allTracks()` by pure functions
in `LibraryIndex` (testable, no AppleScript): `artists(in:)`, `albums(in:byArtist:)`,
`tracks(in:album:)`, `sortedSongs(_:)`.

### 4.2 `AppleMusicLibrary` (new, AppleScript)

- Uses the stage 1 `AppleScriptMusicSource` plumbing (in-script `is running`
  guard, 3 s timeout). `prepare()` alone uses `launch` when Music isn't running.
  Library scripts get a 10 s timeout, since they return more data.
- Each list is one script call that gets the properties of every item at once
  (e.g. `{persistent ID, name, …} of every track of library playlist 1`),
  joins fields with ASCII 31 and records with ASCII 30, and is parsed by
  `LibraryOutputParser` (tested). "missing value" maps to empty or 0.
- Playlists: `every user playlist whose special kind is none`, minus folders
  and the ClickWheel playlist.
- `play(.playlist)`: `play track (startIndex + 1) of playlist id <id>`.
- `play(.queue)`: find the ClickWheel playlist by the persistent ID stored in
  UserDefaults (`clickWheelPlaylistID`); fall back to a user playlist named
  "ClickWheel"; create it if neither exists and store its ID. Then
  `delete every track of` it, `duplicate` the requested tracks (looked up by
  persistent ID in library playlist 1) into it in order, and
  `play track (startIndex + 1) of` it.

### 4.3 `LibraryMenus` (new, pure)

Builds the Music submenu tree from a `MusicLibrary` plus `LibraryIndex`. Each
song row's action creates the correct `PlayRequest`:

| Picked from | Request |
|-------------|---------|
| Playlist songs | `.playlist(id: playlist.id, startIndex: row)` |
| Album songs (from Albums or Artists) | `.queue(trackIDs: album tracks in order, startIndex: row)` |
| Songs | `.queue(trackIDs: all songs in order, startIndex: row)` |

### 4.4 `Navigator` changes

- New `MenuAction.load(title: String, empty: String, loader: () async throws -> [MenuItem])`
  pushes a screen titled `title` with a "Loading…" row, then replaces that
  screen's items with the result (or the `empty` / error row). The result is
  applied only if that same screen (tracked by a per-push token) is still on
  the stack.
- New `MenuAction.play(() async throws -> Void)` runs the request and pushes
  Now Playing on success.
- `MenuItem` gains `isSelectable` (default true). Scroll skips non-selectable
  rows, and center on them does nothing. The selection starts on the first
  selectable row.
- Root menu becomes: Music, Now Playing, Settings.
- Loader and play work runs off the main thread, like `PlayerHub` commands.
  After a successful play, `PlayerHub.refresh()` is triggered so Now Playing
  shows the new track at once.

## 5. Testing

**Unit (XCTest):**
- `LibraryOutputParser`: tracks and playlists, emoji / quotes / separators in
  names, "missing value", empty output (an empty list), malformed records skipped.
- `LibraryIndex`: album-artist fallback, "Unknown Artist" / "Unknown Album",
  case-insensitive sort and dedupe, multi-disc ordering, albums filtered by artist.
- `LibraryMenus` with a fake `MusicLibrary`: each song row produces the request
  in §4.3; playlist rows push the right playlist.
- `Navigator`: Loading… then loaded; result discarded after MENU; empty and
  error rows; non-selectable rows are skipped by scroll; play pushes Now Playing
  only on success.

**Manual checklist:**
1. Music → Playlists lists the user's playlists; playing a song continues the playlist (⏭).
2. Music → Albums → album → song plays and ⏭ continues the album; "ClickWheel" playlist appears in Music.
3. Artists → artist → album → song behaves the same.
4. Songs → song plays and ⏭ goes to the next song alphabetically.
5. Quit Music, open Music menu → Music launches and lists load.
6. Rename the ClickWheel playlist in Music → playing an album still reuses it (found by ID).
