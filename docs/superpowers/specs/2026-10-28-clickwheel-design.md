# ClickWheel — Design Spec

**Date:** 2026-10-28
**Status:** Draft, awaiting review
**Working name:** ClickWheel (rename anytime)

## 1. Purpose

A personal macOS companion app that looks and behaves like a classic iPod and acts
as a remote for the music apps already on the Mac. It's built for one user (the
author), with the code archived publicly on GitHub so anyone can find it.

### Success criteria
- A floating iPod-shaped window controls whichever of Apple Music or Spotify is playing.
- The click wheel feels like the real thing: circular drag scrolls, the buttons do what they did on an iPod.
- Real iPod menus (Playlists / Artists / Albums / Songs) let you browse and play music.
- Built in stages; each stage is usable on its own.

### Non-goals
- No App Store distribution (for now).
- No audio playback of its own; Music and Spotify do the playing.
- No use of Apple firmware, fonts, icons, sounds or logos. All assets are original.
  The project is a fan homage and the name avoids Apple trademarks.
- No support for audio from other apps (browsers, podcasts). That would need private
  macOS APIs and was rejected as fragile.

## 2. Stages

| Stage | Scope |
|-------|-------|
| **1. Now Playing** | iPod window, click wheel, Now Playing screen, play/pause/next/prev/volume for Apple Music **and** Spotify, auto-detects the active app. Menu has only *Now Playing* and *Settings*. |
| **2. Apple Music menus** | Music → Playlists / Artists / Albums / Songs, browsable and playable. No login. |
| **3. Spotify menus** | Same menus filled from the Spotify Web API. One-time OAuth (PKCE) login; the user creates a free Spotify developer app. |
| **4. Extras (optional)** | Alternate skins (e.g. black, colored mini-style), click sound options, more settings. |

Each stage gets its own implementation plan.

## 3. Tech choices

- Swift + SwiftUI, Xcode project, macOS 14+ deployment target.
- Talks to Music and Spotify through their AppleScript interfaces (via `NSAppleScript`
  or ScriptingBridge). Requires the Apple Events entitlement and an
  `NSAppleEventsUsageDescription`; the user approves the Automation prompt once per app.
- App Sandbox off (personal use; simplifies Apple Events). Hardened runtime on.
- Stage 3: Spotify Web API over `URLSession`, OAuth PKCE via `ASWebAuthenticationSession`;
  tokens stored in the Keychain.
- Git, public GitHub repo, MIT license, README with screenshots.

## 4. Architecture

```
iPod Window ── Screen (menus / Now Playing)
           └── Click Wheel ──► WheelEvent
                                   │
                              Navigator (menu stack, selection)
                                   │
                              PlayerHub (active source, polling)
                               ┌───┴────┐
                   AppleMusicSource   SpotifySource
```

### Units

**`ClickWheelView`**: SwiftUI view. Converts pointer input into `WheelEvent`s:
`.scroll(steps: Int)` (positive = clockwise), `.center`, `.menu`, `.previous`,
`.next`, `.playPause`. One step per ~15° of rotation; leftover angle carries over.
Knows nothing about music. Angle→step math lives in a pure `WheelGestureTracker`
struct so it can be unit-tested.

**`Navigator`**: `ObservableObject` holding a stack of `MenuScreen`s. Each screen
has a title, a list of `MenuItem`s (label, has-submenu flag, action) and a selected
index. Handles `WheelEvent`s: scroll moves the selection (clamped), center opens
or triggers, menu pops (no-op at root). On the Now Playing screen, scroll is
routed to volume instead.

**`PlayerHub`**: `ObservableObject`. Polls the sources about once per second, publishes
`nowPlaying: NowPlayingInfo?` and `activeSource`. Mode `auto | appleMusic | spotify`
(persisted). In auto mode: the source currently *playing* wins; if neither is
playing, the last active one is kept. Forwards transport commands to the active source.

**`MusicSource` protocol**: the common shape both sources implement:
- `isRunning`, `playerState`, `currentTrack() -> NowPlayingInfo?`
- `play()`, `pause()`, `playPause()`, `next()`, `previous()`, `setVolume(_:)`, `volume`
- Stage 2+: `playlists()`, `artists()`, `albums(artist:)`, `songs(in:)`, `play(item:)`

**`AppleMusicSource`** and **`SpotifySource`**: AppleScript-backed implementations.
`SpotifySource` gains a `SpotifyWebAPI` helper for library browsing in stage 3.
A `MockMusicSource` is used in tests.

**`NowPlayingInfo`**: title, artist, album, duration, position, artwork
(`NSImage` or URL), track index / count when known.

**`ArtworkCache`**: in-memory cache keyed by track ID so artwork doesn't flicker.

## 5. Look & interaction

### Window
- About 280 × 460 pt, borderless, transparent background, rounded body with a soft shadow.
- Draggable by the body (outside the screen and wheel).
- Right-click menu: *Keep on Top* (toggle, persisted), *Quit*.
- Window position persisted between launches.

### Screen
- Classic grey-blue LCD look: header bar with title, play-state icon, decorative battery.
- Lists: blue highlight bar on the selected row, `›` on items with submenus. Only visible rows are rendered.
- Now Playing: artwork, title / artist / album, progress bar with elapsed and remaining time, "n of m".
- Font: an open-licensed font similar to the iPod's (chosen during implementation; bundled with its license).

### Controls
| Input | Action |
|-------|--------|
| Circular drag on wheel | Scroll list / volume on Now Playing (with tick sound) |
| Center button / Return | Open or play the selected item |
| MENU / Esc | Back one level |
| ⏮ / ⏭ | Previous / next track |
| ▶❚❚ / Space | Play/pause |
| Arrow keys ↑↓ | Scroll |

### Menu tree
```
ClickWheel
├─ Music                (stage 2+)
│   ├─ Playlists › playlist › songs
│   ├─ Artists   › artist › albums › songs
│   ├─ Albums    › album › songs
│   └─ Songs
├─ Now Playing
└─ Settings
    ├─ Source: Auto / Apple Music / Spotify
    └─ Clicker: On / Off
```
In stage 3 the Music branch shows the library of the selected source (in Auto,
the active one).

## 6. Data flow

- PlayerHub polls about once per second off the main thread and publishes on the main thread.
- Artwork: Apple Music supplies raw image data, Spotify supplies a URL. Both are cached.
- Library lists load asynchronously when a menu opens; a "Loading…" row shows meanwhile.
  Results are cached for the session. Large libraries (thousands of songs) stay smooth
  thanks to lazy rendering.

## 7. Error handling (shown on the iPod screen)

| Situation | Behavior |
|-----------|----------|
| Neither app running | Now Playing shows "Nothing playing"; choosing a song launches the right app |
| Automation permission denied | Message plus a button that opens System Settings → Privacy & Security → Automation |
| App quits mid-song | Falls back to "Nothing playing" without crashing |
| Spotify not connected (stage 3) | Spotify menus show "Connect Spotify…", which starts OAuth in the browser |
| Script or API call fails | Logged; screen shows a short error row; app keeps working |

## 8. Testing

- **Unit tests (XCTest):** `WheelGestureTracker` angle→steps (including wraparound at
  0°/360° and direction changes), `Navigator` (push, pop, clamped selection, volume
  routing on Now Playing), `PlayerHub` auto-selection rules using `MockMusicSource`.
- **Manual checklist per stage:** transport controls in each app, switching between
  apps while playing, permission denial, quitting an app mid-song, keyboard shortcuts.

## 9. Open decisions (resolved during implementation, not blocking)
- Final app name (default: ClickWheel).
- Which open font to bundle.
