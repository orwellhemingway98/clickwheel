# ClickWheel Stage 2 (Apple Music Menus) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Browse the Apple Music library (Playlists / Artists / Albums / Songs) with the click wheel and play songs in the context they were picked from.

**Architecture:** A new `MusicLibrary` protocol (playlists, tracks, play requests) sits beside the stage 1 `MusicSource`. Pure, tested pieces (output parser, `LibraryIndex` grouping/sorting, `LibraryMenus` tree builder, `Navigator` loading screens) sit above one AppleScript implementation, `AppleMusicLibrary`. Albums, artists and Songs play through a reusable "ClickWheel" playlist; playlists play natively.

**Tech Stack:** Swift (language mode 5), SwiftUI/AppKit, `NSAppleScript`, XCTest, XcodeGen. Tests run with `./scripts/test.sh` (prints a summary; full log in `build/test.log`).

**Spec:** `docs/superpowers/specs/2026-10-28-clickwheel-stage2-apple-music-menus-design.md` (parent: `docs/superpowers/specs/2026-10-28-clickwheel-design.md`)

## Global Constraints

- Everything from stage 1 still holds: macOS 14+, no Apple assets or SF Symbols, polling never launches an app, commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Only `MusicLibrary.prepare()` may launch Music (when the user opens the Music menu).
- Field separator ASCII 31 (`\u{1F}`), record separator ASCII 30 (`\u{1E}`). `"missing value"` → `""` (strings) or `0` (numbers).
- Library scripts use `with timeout of 10 seconds`; everything else keeps the stage 1 3 s timeout.
- Copy (exact): `Music`, `Playlists`, `Artists`, `Albums`, `Songs`, `Loading…`, `No playlists`, `No artists`, `No albums`, `No songs`, `Couldn't load library`, `Unknown Artist`, `Unknown Album`, playlist name `ClickWheel`, UserDefaults key `clickWheelPlaylistID`.
- Sorting is case-insensitive using `localizedCaseInsensitiveCompare`.
- No caching; every list reads fresh from Music.

## Review Focus

1. **Stale loads:** the user presses MENU (or opens another list) before a slow load finishes. The late result must not appear on the wrong screen (test in Task 3).
2. **Placeholder-only lists:** a list holding only "Loading…" / "No songs" / "Couldn't load library". Scroll and center must do nothing, with no crash and no click sound (test in Task 3).
3. **Tracks missing metadata:** local files or uploads with no artist, album artist or album must group under "Unknown Artist" / "Unknown Album", never as a blank row (test in Task 2).
4. **Same names:** two albums called "Greatest Hits" by different artists must stay separate rows, each playing its own songs. Two playlists with the same name each play their own tracks (tests in Tasks 2 and 4).
5. **Script injection or breakage from IDs:** values interpolated into AppleScript (persistent IDs) must be quoted and escaped, so a `"` or `\` can't break the script (test in Task 5).

---

## File Structure

```
ClickWheel/Library/LibraryModel.swift        LibraryPlaylist, LibraryTrack, LibraryAlbum, PlayRequest, MusicLibrary
ClickWheel/Library/LibraryOutputParser.swift  parses script output into tracks / playlists
ClickWheel/Library/LibraryIndex.swift         artists / albums / album tracks / sorted songs (pure)
ClickWheel/Library/BackgroundRunner.swift     runs blocking work on a serial queue, async
ClickWheel/Library/LibraryMenus.swift         builds the Music menu tree from a MusicLibrary
ClickWheel/Library/AppleMusicLibrary.swift    AppleScript implementation + AppleMusicScripts builders
ClickWheel/Core/MenuModel.swift               (modify) MenuAction .load/.play, MenuItem.isSelectable, MenuScreen.id
ClickWheel/Core/Navigator.swift               (modify) loading screens, play, selectable rows, Music root item
ClickWheel/UI/MenuListView.swift              (modify) `›` for .load items; dim non-selectable rows
ClickWheel/App/AppModel.swift                 (modify) wire AppleMusicLibrary into Navigator
ClickWheelTests/LibraryOutputParserTests.swift, LibraryIndexTests.swift, NavigatorLoadingTests.swift,
LibraryMenusTests.swift, AppleMusicScriptsTests.swift, Mocks/FakeMusicLibrary.swift
```

---

### Task 1: Library model and output parser

**Files:**
- Create: `ClickWheel/Library/LibraryModel.swift`, `ClickWheel/Library/LibraryOutputParser.swift`
- Test: `ClickWheelTests/LibraryOutputParserTests.swift`

**Interfaces:**
- Produces: the types and protocol exactly as spec §4.1 (`LibraryPlaylist`, `LibraryTrack`, `LibraryAlbum`, `PlayRequest`, `MusicLibrary` with `prepare()`, `playlists()`, `tracks(inPlaylist:)`, `allTracks()`, `play(_:)`), and
  `enum LibraryOutputParser { static let field: Character = "\u{1F}"; static let record: Character = "\u{1E}"; static func tracks(_ output: String) -> [LibraryTrack]; static func playlists(_ output: String) -> [LibraryPlaylist] }`
- Track record fields, in order: `id, name, artist, albumArtist, album, discNumber, trackNumber` (7). Playlist record: `id, name` (2). Records with the wrong field count are skipped.

- [ ] **Step 1: Write failing tests** (`rec(...)` joins with `field`; `out(...)` joins records with `record`):
  - `testParsesTracks`: two records → two tracks with all fields; `"2"`/`"5"` → disc 2, track 5.
  - `testMissingValueAndBlankNumbers`: artist `"missing value"` → `""`; disc `"missing value"` → 0; track `""` → 0.
  - `testOddNamesSurvive`: name `"Hey | \"Jude\" 🎸, \\o/"` kept exactly; following fields not shifted.
  - `testEmptyOutputIsEmptyList`: `tracks("") == []`, `playlists("") == []`.
  - `testMalformedRecordSkipped`: a 3-field record between two good ones → 2 tracks.
  - `testParsesPlaylists`: `out(rec("A1","Road Trip"), rec("B2","Road Trip"))` → two playlists, same name, different ids.
- [ ] **Step 2: Run `./scripts/test.sh`.** Expected: compile errors (types undefined).
- [ ] **Step 3: Implement** the model file and the parser.
- [ ] **Step 4: Run `./scripts/test.sh`.** Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5: Commit:** `feat: library model and output parser`.

### Task 2: LibraryIndex (grouping and sorting)

**Files:**
- Create: `ClickWheel/Library/LibraryIndex.swift`
- Test: `ClickWheelTests/LibraryIndexTests.swift`

**Interfaces:**
- Consumes: `LibraryTrack`, `LibraryAlbum` (Task 1).
- Produces: `enum LibraryIndex { static func artistName(of track: LibraryTrack) -> String; static func albumName(of track: LibraryTrack) -> String; static func artists(in tracks: [LibraryTrack]) -> [String]; static func albums(in tracks: [LibraryTrack], byArtist artist: String? = nil) -> [LibraryAlbum]; static func tracks(in tracks: [LibraryTrack], album: LibraryAlbum) -> [LibraryTrack]; static func sortedSongs(_ tracks: [LibraryTrack]) -> [LibraryTrack] }`
- Rules: `artistName` = albumArtist if non-empty, else artist, else `"Unknown Artist"`. `albumName` = album or `"Unknown Album"`. Artist and album matching is case-insensitive; the first spelling seen is kept for display.

- [ ] **Step 1: Write failing tests** (helper `t(name:artist:albumArtist:album:disc:track:)`):
  - `testArtistFallbacks`: albumArtist "Various" wins over artist; empty albumArtist → artist; both empty → "Unknown Artist".
  - `testArtistsDedupedCaseInsensitiveAndSorted`: "the Beatles", "ABBA", "The Beatles" → `["ABBA", "the Beatles"]`.
  - `testAlbumsSameNameDifferentArtistsStaySeparate`: "Greatest Hits" by Queen and by ABBA → two albums, sorted by artist (ABBA first).
  - `testUnknownAlbum`: album "" → `LibraryAlbum(name: "Unknown Album", artist: …)`.
  - `testAlbumsByArtist`: filter "queen" (lowercase) matches album artist "Queen".
  - `testAlbumTracksMultiDiscOrder`: (disc 2, track 1), (disc 1, track 2), (disc 1, track 1) → order d1t1, d1t2, d2t1; ties broken by name.
  - `testAlbumTracksOnlyThatAlbumAndArtist`: tracks of "Greatest Hits"/Queen exclude ABBA's.
  - `testSortedSongsCaseInsensitive`: "beta", "Alpha", "gamma" → Alpha, beta, gamma.
- [ ] **Step 2: Run `./scripts/test.sh`.** Expected: compile errors.
- [ ] **Step 3: Implement** `LibraryIndex`.
- [ ] **Step 4: Run `./scripts/test.sh`.** Expected: all pass.
- [ ] **Step 5: Commit:** `feat: library index grouping and sorting`.

### Task 3: Navigator loading screens, play actions and placeholder rows

**Files:**
- Modify: `ClickWheel/Core/MenuModel.swift`, `ClickWheel/Core/Navigator.swift`, `ClickWheel/UI/MenuListView.swift`
- Test: `ClickWheelTests/NavigatorLoadingTests.swift`

**Interfaces:**
- Consumes: existing `Navigator`, `MenuItem`, `MenuScreen`, `MenuAction`, `PlayerControlling`, `AppSettings`.
- Produces:
  - `MenuAction` gains `case load(title: String, empty: String, loader: () async throws -> [MenuItem])` and `case play(() async throws -> Void)`.
  - `MenuItem` gains `let isSelectable: Bool` (init parameter `isSelectable: Bool = true`) and `static func placeholder(_ label: String) -> MenuItem` (non-selectable, `.run {}`). `opensSubmenu` is true for `.push` and `.load`.
  - `MenuScreen` gains `let id = UUID()` and `init(title:items:)`, which sets `selectedIndex` to the first selectable row (0 if none).
  - `Navigator.init(player:settings:musicMenu: (() -> MenuScreen)? = nil, onPlayed: @escaping () -> Void = {}, onScrollStep:)`. When `musicMenu` is non-nil the root is `Music` (`.push(musicMenu)`), `Now Playing`, `Settings`; otherwise it's unchanged from stage 1.
  - `Navigator.lastTask: Task<Void, Never>?`, the most recent load or play, so tests can await it.
- Behavior: `.load` pushes `MenuScreen(title:, items: [.placeholder("Loading…")])`, then on success replaces that screen's items (located in the stack by `id`; dropped if it's gone) with the result, or `[.placeholder(empty)]` when the result is empty, or `[.placeholder("Couldn't load library")]` on throw. A replaced screen's selection goes to its first selectable row. `.play` runs the closure; on success it pushes `.nowPlaying` and calls `onPlayed()`; on throw it stays put. Scroll moves through selectable rows only (clamped; `onScrollStep` only fires when the selection moves). Center on a non-selectable row does nothing.

- [ ] **Step 1: Write failing tests** (loaders are closures over a test-controlled `CheckedContinuation` or simple `async` returns):
  - `testLoadShowsLoadingThenItems`: center on a `.load` item whose loader awaits a gate → current screen has title "Playlists" and the single label "Loading…"; open the gate returning 2 items, `await nav.lastTask?.value` → labels are those 2, selection 0.
  - `testLoadEmptyShowsEmptyRow`: loader returns `[]` → labels `["No playlists"]`, row not selectable.
  - `testLoadFailureShowsError`: loader throws → labels `["Couldn't load library"]`.
  - `testStaleLoadDiscardedAfterMenu`: start a gated load, press `.menu`, then open the gate → the stack is back at the parent and no screen shows the loaded items.
  - `testPlaceholderRowsIgnoreInput`: on a `["Loading…"]` screen, `.scroll(steps: 1)`, `.scroll(steps: -1)` and `.center` → selection unchanged, `onScrollStep` count 0, stack count unchanged.
  - `testScrollSkipsNonSelectableRows`: items [A, placeholder, B] → scroll(1) selects B (index 2).
  - `testPlaySuccessPushesNowPlayingAndNotifies`: center on `.play` → after `lastTask`, current is `.nowPlaying`, `onPlayed` count 1.
  - `testPlayFailureStaysOnList`: play throws → current is still the list, `onPlayed` count 0.
  - `testMusicRootWhenProvided`: with `musicMenu` → root labels `["Music", "Now Playing", "Settings"]`.
- [ ] **Step 2: Run `./scripts/test.sh`.** Expected: compile errors (new cases undefined).
- [ ] **Step 3: Implement** the model and Navigator changes. `MenuListView` shows `›` via `opensSubmenu` and renders non-selectable rows at 60% opacity.
- [ ] **Step 4: Run `./scripts/test.sh`.** Expected: all pass, including the unchanged stage 1 `NavigatorTests` (root without `musicMenu` is still `Now Playing`, `Settings`).
- [ ] **Step 5: Commit:** `feat: navigator loading screens and play actions`.

### Task 4: LibraryMenus and BackgroundRunner

**Files:**
- Create: `ClickWheel/Library/BackgroundRunner.swift`, `ClickWheel/Library/LibraryMenus.swift`
- Test: `ClickWheelTests/LibraryMenusTests.swift`, `ClickWheelTests/Mocks/FakeMusicLibrary.swift`

**Interfaces:**
- Consumes: `MusicLibrary`, `PlayRequest`, `LibraryIndex` (Tasks 1–2); `MenuScreen`, `MenuItem`, `MenuAction.load/.play` (Task 3).
- Produces:
  - `final class BackgroundRunner { init(label: String); func run<T>(_ work: @escaping () throws -> T) async throws -> T }`, on a serial `DispatchQueue`.
  - `enum LibraryMenus { static func musicMenu(library: MusicLibrary, runner: BackgroundRunner) -> MenuScreen }`
- Tree (each list loader first calls `library.prepare()` on the runner):
  - `Music` screen: `Playlists` (`.load`, empty "No playlists"), `Artists` ("No artists"), `Albums` ("No albums"), `Songs` ("No songs").
  - Playlist row (label = name) → `.load(title: name, empty: "No songs")` → song rows (detail = artist) → `.play` `.playlist(id:, startIndex: row)`.
  - Artist row → `.load(title: artist, empty: "No albums")` → album rows → `.load(title: album.name, empty: "No songs")` → song rows → `.play` `.queue(trackIDs: album tracks' ids, startIndex: row)`.
  - Album row (detail = artist) → same album-songs screen as above.
  - Songs → sorted all songs (detail = artist) → `.play` `.queue(trackIDs: all sorted ids, startIndex: row)`.
- `FakeMusicLibrary`: settable `playlistsResult`, `tracksByPlaylist: [String: [LibraryTrack]]`, `allTracksResult`, `error: Error?`; records `prepareCount` and `played: [PlayRequest]`.

- [ ] **Step 1: Write failing tests** (helpers `load(_ item: MenuItem) async throws -> [MenuItem]` and `play(_ item: MenuItem) async throws`, which unwrap the action):
  - `testMusicMenuItems`: labels `["Playlists", "Artists", "Albums", "Songs"]`, all `opensSubmenu`.
  - `testPlaylistSongPlaysInPlaylist`: playlists [P1 "Road Trip"] with 3 tracks; load Playlists → load "Road Trip" → play row 1 → `played == [.playlist(id: "P1", startIndex: 1)]`; song row detail is the artist.
  - `testSamePlaylistNamesPlayOwnTracks`: two playlists both named "Mix" (ids A, B) → playing row 0 under the second plays `.playlist(id: "B", startIndex: 0)`.
  - `testAlbumSongQueuesWholeAlbum`: album with tracks d1t2, d1t1 → Albums → album → play row 1 → `.queue(trackIDs: [t1.id, t2.id], startIndex: 1)`.
  - `testArtistAlbumSongQueuesThatAlbumOnly`: Artists → "Queen" → "Greatest Hits" → play row 0 → queue contains only Queen's tracks.
  - `testSongsQueueAllSorted`: Songs → play row 2 → `.queue(trackIDs: ids sorted by name, startIndex: 2)`.
  - `testLoadersPrepareLibrary`: loading Playlists → `prepareCount == 1`.
  - `testLoaderErrorPropagates`: `error` set → loading Albums throws.
- [ ] **Step 2: Run `./scripts/test.sh`.** Expected: compile errors.
- [ ] **Step 3: Implement** `BackgroundRunner` and `LibraryMenus`.
- [ ] **Step 4: Run `./scripts/test.sh`.** Expected: all pass.
- [ ] **Step 5: Commit:** `feat: Apple Music library menu tree`.

### Task 5: AppleMusicLibrary and app wiring

**Files:**
- Create: `ClickWheel/Library/AppleMusicLibrary.swift`
- Modify: `ClickWheel/App/AppModel.swift`
- Test: `ClickWheelTests/AppleMusicScriptsTests.swift`

**Interfaces:**
- Consumes: `MusicLibrary`, `LibraryOutputParser` (Task 1); `AppleScriptRunner`, `AppleScriptMusicSource` (stage 1); `LibraryMenus`, `BackgroundRunner` (Task 4); `Navigator.init(…musicMenu:onPlayed:…)` (Task 3).
- Produces:
  - `enum AppleMusicScripts { static func quoted(_ s: String) -> String; static let playlists: String; static let allTracks: String; static func tracks(inPlaylist id: String) -> String; static func playPlaylist(id: String, startIndex: Int) -> String; static func queue(trackIDs: [String], startIndex: Int, knownPlaylistID: String?) -> String }`. The script bodies go inside the stage 1 `tell()` wrapper; the playlist / track scripts wrap their body in `with timeout of 10 seconds`.
  - `final class AppleMusicLibrary: AppleScriptMusicSource, MusicLibrary { init(defaults: UserDefaults = .standard) }`
- Script contracts:
  - `playlists`: every `user playlist whose special kind is none` → records `persistent ID, name`. Swift then drops the stored `clickWheelPlaylistID` and any playlist named `ClickWheel`.
  - `allTracks`: bulk `{persistent ID, name, artist, album artist, album, disc number, track number} of every track of library playlist 1` → records in parser order. `tracks(inPlaylist:)` does the same for `(first user playlist whose persistent ID is <id>)`.
  - `playPlaylist`: `play track (startIndex + 1) of (first user playlist whose persistent ID is <id>)`.
  - `queue`: resolve the playlist by `knownPlaylistID` (try), else `first user playlist whose name is "ClickWheel"` (try), else `make new user playlist with properties {name:"ClickWheel"}`; `delete every track of` it; for each id, `duplicate (first track of library playlist 1 whose persistent ID is <id>) to` it; `play track (startIndex + 1) of` it; return its persistent ID, which Swift stores under `clickWheelPlaylistID`.
  - `prepare()`: if not running, `NSWorkspace.shared.openApplication(at: urlForApplication(withBundleIdentifier: "com.apple.Music"), configuration: activates = false)`, wait (polling every 0.2 s, max 10 s) for `isRunning()`, then 1 s more for scripting readiness; throw `.notRunning` on timeout.
- `AppModel`: `let library = AppleMusicLibrary()`, `let libraryRunner = BackgroundRunner(label: "ClickWheel.Library")`; `Navigator(..., musicMenu: { LibraryMenus.musicMenu(library: library, runner: libraryRunner) }, onPlayed: { Task { await hub.refresh() } }, ...)`.

- [ ] **Step 1: Write failing tests:**
  - `testQuotedEscapes`: `quoted("a\"b\\c") == "\"a\\\"b\\\\c\""`.
  - `testQueueScriptQuotesIDsAndUsesOneBasedIndex`: `queue(trackIDs: ["AB\"C"], startIndex: 0, knownPlaylistID: "P1")` contains `quoted("AB\"C")`, contains `"P1"` quoted, and contains `play track 1 of`.
  - `testQueueScriptWithoutKnownID`: `knownPlaylistID: nil` → no `"(missing)"`-style placeholder; contains `name is "ClickWheel"`.
  - `testPlayPlaylistScript`: `playPlaylist(id: "X", startIndex: 4)` contains `play track 5 of` and `quoted("X")`.
- [ ] **Step 2: Run `./scripts/test.sh`.** Expected: compile errors.
- [ ] **Step 3: Implement** `AppleMusicScripts`, `AppleMusicLibrary` and the `AppModel` wiring.
- [ ] **Step 4: Run `./scripts/test.sh`.** Expected: all pass.
- [ ] **Step 5: Compile-check every generated script** with `osacompile` (each wrapped in `tell application id "com.apple.Music"`). Expected: all compile.
- [ ] **Step 6: Live check** using the `--snapshot` flag after temporarily selecting Music → Albums at launch, or by running the app. Expected: the user's albums are listed.
- [ ] **Step 7: Commit:** `feat: Apple Music library via AppleScript`.

### Task 6: Manual checklist and README

**Files:**
- Modify: `README.md` (Features: Music menus; Roadmap: stage 2 ✅; note about the "ClickWheel" playlist)

- [ ] **Step 1: The user runs the spec §5 manual checklist** (6 items) on a fresh build. Record pass or fail in the commit body.
- [ ] **Step 2: Update the README** and commit: `docs: stage 2 README`.
