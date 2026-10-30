# ClickWheel

A tiny floating click-wheel music player for your Mac. It doesn't play music
itself: it's a remote for **Apple Music** and **Spotify**, and it follows
whichever one is playing.

<img src="docs/screenshot.png" width="100%" alt="ClickWheel: the iPod 1st generation, mini, 4th generation U2, 5th generation, classic in Cover Flow and nano 5th generation, side by side at true relative size">

> A fan homage to classic click-wheel music players. Not affiliated with or
> endorsed by Apple. All artwork is drawn in code; no Apple software, fonts,
> icons or sounds are included.

## Features

- **Life size**: drawn to Apple's dimensional drawing of the iPod (5th generation),
  scaled to your display's real density, so it measures 61.8 × 103.5 mm on screen.
- **The 5G colour screen**: gradient title bar, white 9-row menus with the blue
  selection bar, marquee for long names, and slide transitions.
- **Now Playing**: "x of y", album art, title / artist / album and the glossy
  progress bar. Turn the wheel for the volume bar. Press Center for the
  scrubber (◆), then turn to seek.
- **Click wheel**:
  - Drag in a circle to scroll, with gentle acceleration when you spin fast and
    Quick Scroll letters in long lists.
  - Tap the buttons: MENU (back), ⏮ (restart, or previous track), ⏭ (next),
    ▶❚❚ (play/pause), center (select).
  - Hold them: hold MENU to jump to the main menu; hold ⏭ or ⏮ to fast-forward
    or rewind.
  - A 1 kHz clicker ticks as you scroll.
- **Trackpad**: turn two fingers to turn the wheel; swipe with two fingers (or use a
  mouse wheel) to scroll. **Click a menu row** to open it.
- **Keyboard**: ↑ ↓ scroll; ← ⏮, → ⏭, Return center, Esc MENU, Space ▶❚❚
  (holds work too).
- **Main menu**: Music, Extras (Clock, Stopwatch), Settings, Shuffle Songs, and
  Now Playing while something plays.
- **Music** (Apple Music library): Playlists, Artists, Albums and Songs. Picking a
  song plays it in context: the rest of the playlist, album or song list follows.
- **Cover Flow** (iPod classic and nanos 3G–5G): Music › Cover Flow shows your albums
  as covers with reflections. Turn the wheel to flip through them; press the centre
  to turn a cover over to its songs, and again to play one. MENU turns it back.
- **Settings**: source (Auto / Apple Music / Spotify), clicker on/off.
- Borderless floating window: drag it anywhere; right-click for **Keep on Top** or **Quit**.

Albums, artists, Songs and Shuffle Songs play through a playlist named
**ClickWheel**, which ClickWheel creates in your Music library and refills each
time. It syncs to your other devices with the rest of your library. Opening a
Music list launches Music if it isn't running.

## Models

Choose the iPod from the list in **Settings › Model** (the current one is ticked). The window reshapes to that model at life size.

| Model | Year | What's different |
|---|---|---|
| **iPod (1st generation)** | 2001 | A wheel that really turns (its texture follows your finger), inside a ring of four buttons. Black-and-white Chicago screen: grey-green, lighting up pale blue when you touch anything (hold MENU toggles the light; Settings › Backlight Timer). Firmware 1.3.1 menus: Playlists, Browse, Extras, Settings, Backlight. |
| **iPod (2nd generation)** | 2002 | The same front as the 1st gen, with a touch-sensitive wheel that stays still (smooth, no grooves). |
| **iPod (3rd generation)** | 2003 | Thinner, with rounded edges. Four round touch buttons in a row (⏮ · MENU · ▶❚❚ · ⏭) whose labels glow red with the backlight, above a smooth touch wheel. Green LCD that lights up pale blue. Firmware 2.3 menus: Music, Extras, Settings, Shuffle Songs, Backlight. |
| **iPod mini** | 2004 | Anodized aluminium in silver, gold, pink, blue or green (Settings › Colour). The first click wheel, with grey labels. A smaller 138 × 110 gray LCD that lights up blue-white, five rows, in a clean sans. Exact life size. |
| **iPod (4th generation)** | 2004 | The click wheel comes to the full-size iPod: white, or the U2 Special Edition in black with a red wheel (Settings › Colour). The last Chicago screen, grey with a white backlight. |
| **iPod photo** | 2004 | The 4G's front (white or U2) with the first colour screen, 220 × 176: the 5G-style interface with album art. Its screen dims when the backlight goes off. |
| **iPod mini (2nd generation)** | 2005 | The mini in brighter pink, blue and green (silver unchanged, no gold), with wheel lettering that matches the body. |
| **iPod nano** | 2005 | Pencil-thin, in white or black (Settings › Colour), with a 176 × 132 colour screen running the 5G-style menus, Stopwatch included. The screen dims with the backlight. |
| **iPod (5th generation)** | 2005 | Click wheel and colour screen (see Features). |
| **iPod nano (2nd generation)** | 2006 | The nano in an anodized aluminium tube: silver, pink, green, blue, black or (PRODUCT) RED (Settings › Colour). |
| **iPod classic** | 2007 | A silver or black aluminium face in a steel shell. Its own split-screen interface: the menu on the left, your current album art slowly panning on the right, with a glossier blue selection. |
| **iPod nano (3rd generation)** | 2007 | The short, wide nano: an aluminium face in silver, black, blue, green, pink or (PRODUCT) RED, running the classic's split-screen interface. |
| **iPod nano (4th generation)** | 2008 | Tall, curved aluminium in nine colours (Settings › Colour), with a portrait screen: full-width lists of 12 rows and a Now Playing with the album art on top. |
| **iPod nano (5th generation)** | 2009 | The 4G's outline in polished, glossy aluminium and nine deeper colours, with a taller 240 × 376 screen (14 rows, bigger album art). |

That completes the click-wheel timeline, from the 2001 original to the 2009 nano.

## Download

Get **ClickWheel.zip** from the [latest release](https://github.com/orwellhemingway98/clickwheel/releases/latest),
unzip it and move **ClickWheel.app** to Applications. It runs on macOS 14 or later,
on Apple Silicon and Intel Macs.

ClickWheel isn't notarized by Apple (that needs a paid developer account), so the
first time you open it macOS says it can't check it for malicious software.
Right-click the app and choose **Open**, then **Open** again; or open it once, then
go to System Settings → Privacy & Security and click **Open Anyway**. After that it
opens normally.

## Build

Requires macOS 14+, Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open ClickWheel.xcodeproj   # then Run
```

Run the tests with `./scripts/test.sh`. `./scripts/release.sh` builds the
downloadable zip into `releases/`.

The first time ClickWheel talks to Music or Spotify, macOS asks for permission
to control it. Click **Allow**. You can change this later in
System Settings → Privacy & Security → Automation.

## Roadmap

1. ✅ Now Playing and transport controls
2. ✅ Apple Music library menus (Playlists, Artists, Albums, Songs)
   - ✅ Every click-wheel iPod, 2001–2009, life size (Settings › Model)
   - ✅ Cover Flow
   - ✅ Downloadable app (GitHub Releases)
3. Spotify library menus (via the Spotify Web API)
4. Extras: alternate skins, more settings

## Credits

- [Source Sans 3](https://github.com/adobe-fonts/source-sans) by Adobe, under the
  SIL Open Font License (see `ClickWheel/Resources/Fonts/OFL.txt`).
- Screen layout and colour values are modified/derived from the **iVideo** theme
  for iPod Video (CC-BY-SA 3.0) by Humberto Santana; see
  `docs/reference/ipod-5g-screen-values.md`.
- [ChicagoFLF](https://fontlibrary.org/en/font/chicagoflf) by Robin Casady, which he
  placed in the public domain (see `ClickWheel/Resources/Fonts/ChicagoFLF-README.txt`).
- The 1st-generation front layout was measured from Apple's own interactive
  recreation on the Apple Music "Page Not Found" page (see
  `docs/reference/ipod-1g-front-values.md`). No Apple artwork or code is included.
- MIT licensed. See [LICENSE](LICENSE).
