# ClickWheel

A tiny floating click-wheel music player for your Mac. It doesn't play music
itself: it's a remote for **Apple Music** and **Spotify**, and it follows
whichever one is playing.

<img src="docs/screenshot.png" width="320" alt="ClickWheel">

> A fan homage to classic click-wheel music players. Not affiliated with or
> endorsed by Apple. All artwork is drawn in code; no Apple software, fonts,
> icons or sounds are included.

## Features

- Borderless floating window: drag it anywhere, right-click for **Keep on Top** / **Quit**.
- **Now Playing**: artwork, title, artist, album, progress, elapsed / remaining time.
- **Click wheel**: drag in a circle to scroll (or change volume on Now Playing),
  center to select, MENU to go back, ⏮ / ⏭ to skip, ▶❚❚ to play/pause.
- **Keyboard**: ↑ ↓ scroll, Return selects, Esc goes back, Space plays/pauses.
- **Settings**: source (Auto / Apple Music / Spotify), clicker sound on/off.
- **Music** (Apple Music library): Playlists, Artists, Albums and Songs. Picking a
  song plays it in context: the rest of the playlist, album or song list follows.

Albums, artists and Songs play through a playlist named **ClickWheel**, which
ClickWheel creates in your Music library and refills each time. It syncs to your
other devices with the rest of your library. Opening the Music menu launches
Music if it isn't running.

## Build

Requires macOS 14+, Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open ClickWheel.xcodeproj   # then Run
```

Run the tests with `./scripts/test.sh`.

The first time ClickWheel talks to Music or Spotify, macOS asks for permission
to control it. Click **Allow**. You can change this later in
System Settings → Privacy & Security → Automation.

## Roadmap

1. ✅ Now Playing and transport controls
2. ✅ Apple Music library menus (Playlists, Artists, Albums, Songs)
3. Spotify library menus (via the Spotify Web API)
4. Extras: alternate skins, more settings

## Credits

- [Source Sans 3](https://github.com/adobe-fonts/source-sans) by Adobe, under the
  SIL Open Font License (see `ClickWheel/Resources/Fonts/OFL.txt`).
- MIT licensed. See [LICENSE](LICENSE).
