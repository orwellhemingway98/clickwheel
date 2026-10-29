# ClickWheel: Cover Flow (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").

## Decisions (user)
- The centre button **flips the cover to its track list**; picking a song plays the album from it.
- Only the models that had it: the **classic and the nanos 3G–5G** (every `.classic` menu style model).

## Spec

**Entry.** On `.classic` models, Music gets a first row **Cover Flow** (when a Cover Flow source is available). It opens a full-screen screen `Screen.coverFlow(CoverFlowState)`: black, no header.

**State** (`Core/CoverFlow.swift`, pure and tested):
- `CoverFlowAlbum`: name, artist, `trackIDs`, `trackNames`; `artworkTrackID` = the first track.
- `CoverFlowState`: `albums`, `loading`, `index`, `flipped`, `trackIndex`, `trackWindowStart`; `static let backRows = 6`.
- `scroll(_ steps:)`: not flipped → `index` moves and clamps (and resets `trackIndex`/`trackWindowStart` to 0); flipped → `trackIndex` moves and clamps, `trackWindowStart` follows (`MenuWindow.start`, 6 rows).
- `center() -> CoverFlowAction?`: not flipped → flips (`trackIndex` 0), returns nil; flipped → `.play(trackIDs:, startIndex:)`. Nothing while loading or empty.
- `menu() -> Bool`: flipped → flips back, returns true (handled); else false (the Navigator leaves).

**Navigator.** Takes `coverFlow: CoverFlowSource?` (`albums() async throws -> [CoverFlowAlbum]`, `play(trackIDs:startIndex:) async throws`). Opening pushes a loading state, then fills it if it's still on top. Wheel steps are accelerated as in menus; each step clicks. Centre and MENU go to the state; a `.play` uses the existing play path (Now Playing follows). Every `switch` over `Screen` handles `.coverFlow`.

**Library.** `MusicLibrary.artwork(trackID:) throws -> Data?` (Apple Music: `raw data of artwork 1` of the track by persistent ID). Albums come from `LibraryIndex.albums` and `tracks(in:album:)`, in Music › Albums order. `CoverArtCache` (MainActor, capacity 60, failed lookups not cached) loads covers lazily.

**View** (`UI/CoverFlowView.swift`). `CoverFlowLayout(canvas:)`, tested:
- cover side = round(min(w × 0.42, h × 0.5)); centre at (w/2, h × 0.42).
- `transform(offset d)`: d = 0 → x 0, rotation 0°, z highest; |d| ≥ 1 → x = sign × (side × 0.62 + (|d| − 1) × side × 0.22), rotation −sign × 60° around Y, z lower with distance. Only |d| ≤ 4 drawn.
- Reflections: each cover mirrored below, fading out over 35 % of its height.
- Album name (semibold) and artist under the covers, white and grey.
- Flipped: the centre cover turns 180° to a card (side × 1.4 square, capped at the canvas) with the album title and up to 6 song rows, the classic selection on the chosen song.
- While loading: "Loading…"; empty: "No albums".
- Only covers within 3 of the centre load artwork; placeholder grey with ♪.

## Plan (native, TDD)
1. **State.** `CoverFlowState` tests (scroll clamp both ways, reset on album change, flip, play action, track window, menu unflip, loading/empty inert). Then the model.
2. **Library.** `CoverArtCache` tests with a fake loader (caches, evicts beyond capacity, retries failures); `AppleMusicScripts.artwork(trackID:)` script text test. Then the code and `MusicLibrary.artwork`.
3. **Navigator.** Tests with a fake source: Music has Cover Flow first on `.classic` only; opening loads albums; scroll/centre/MENU behave; picking plays and lands on Now Playing; MENU twice leaves. Then the Navigator and `AppModel` source.
4. **View.** `CoverFlowLayout` tests; then `CoverFlowView`, ScreenView hides the header on Cover Flow.
5. **Verify.** Suite; renders (closed, flipped) on the classic, nano 3G, 4G and 5G; every model's main screens pixel-identical to v0.17.0; README; final reviewer.
