# ClickWheel: Multi-Model System and iPod 1st Generation (Design Spec)

**Date:** 2026-10-29
**Status:** Draft, awaiting review
**Research basis:** `reports/iPod 1G design study.md`, `docs/reference/ipod-1g-front-values.md`
(and, for the 5G, the existing references)

## 1. Purpose

Turn ClickWheel from one iPod into a timeline of iPods, built one model at a time
in release order. This spec covers the shared **model system** and its first new
model, the **original iPod (1st generation, 2001)**. Later models (2G, 3G, mini,
4G, photo, mini 2G, nano 1G, nano 2G, classic, nano 3G–5G) will each be a small
spec that adds a model definition to this system.

### Decisions the user made
- Lineup: the classic line plus mini and nano, in release order.
- Switching: **Settings › Model**.
- 1G firmware era: **late 1.3.1** (Playlists, Browse, Extras, Settings, Backlight; scrubbing works).
- Backlight: **authentic**. Unlit grey-green by default; any input lights it for the Backlight Timer; holding MENU toggles it.
- Font: **ChicagoFLF** (public domain per its author), bundled.
- Scale: **pixel-crisp**. The 1G is nudged so each LCD pixel is a whole multiple of 0.25 pt (1.25 pt on the user's display).
- App icon: the user's `iPod.icon` (Icon Composer). Done separately on this branch.

### Non-goals
- Models after the 1G (each gets its own spec).
- Firmware 1.0 "launch" mode; Genres, Composers, Calendar, Contacts, Games.
- Power off, Hold switch, contrast setting.

## 2. Model system

### 2.1 Model definitions (pure data)
```swift
enum IPodModel: String, CaseIterable { case firstGen, fifthGen }   // in release order
struct ModelSpec {
    let name: String               // "iPod (1st generation)", "iPod (5th generation)"
    let year: Int
    let body: BodySpec             // mm: width, height, cornerRadius, rimWidth
    let display: DisplaySpec       // mm: window size, window top, window corner, LCD size;
                                   // pixels: 160×128 or 320×240; kind: .gray(LCDPalette) or .color
    let controls: ControlSpec      // .scrollWheel(ring:wheel:button:centerFromBottom:) or .clickWheel(...)
    let firmware: FirmwareProfile
}
```
- `IPodModel.spec` returns the definition. The 5G values are exactly today's `IPodGeometry` constants (no visual change).
- `stepsPerRevolution`: 5G 24 (4 of 96 sectors); 1G **16** (6 of 96 sectors).

### 2.2 Geometry
- `IPodGeometry(model:pointsPerMM:)` computes every point value from the model's millimetres (body, window, LCD, controls). Existing 5G call sites keep the same results.
- **Pixel-crisp scale (gray LCD models):** with `d` = the display's density in pt/mm and `p` = the LCD pixel pitch (mm), pixel size in points = `max(0.75, round(p·d·4)/4)`. The model renders at `pointsPerMM = pixelPoints / p`. On the user's display (5.023 pt/mm) the 1G pitch 0.248 mm gives 1.25 pt, so 5.040 pt/mm (+0.34%). The 5G keeps exact life size.

### 2.3 Switching
- `AppSettings.model: IPodModel` (persisted, default `.fifthGen`).
- Settings gets a **Model** row on every model, as the first row (detail = short name, e.g. "1st gen"). Center cycles in release order.
- `DisplayGeometry` recomputes for the selected model. The window resizes keeping its top-left corner; the navigator resets to the new model's root menu.

### 2.4 Rendering by model
- `IPodView` draws body, window and controls from geometry and the model's materials.
- `ScreenView` picks a screen set by `display.kind`:
  - `.color` → the existing 5G views (unchanged)
  - `.gray` → the new `GrayScreen` views (§3.2)
- Controls by `controls` kind:
  - `.clickWheel` → the existing `ClickWheelView`
  - `.scrollWheel` → the new `ScrollWheelView` (§3.3)
- Both control views send the same `WheelInput` presses, releases and scrolls.

### 2.5 Firmware profiles
`FirmwareProfile` holds:
- `menuStyle`: `.fifthGen` or `.firstGenLate`, which selects the root menu builder
- `holdMenu`: `.home` (5G) or `.toggleBacklight` (1G)
- `quickScroll: Bool` (5G true, 1G false)
- `scrubbing: Bool` (both true)
- `backlight: Bool` (1G true)

`Navigator` takes the profile and builds menus from it. `LibraryMenus` exposes the individual list items (Playlists, Artists, Albums, Songs) so each profile can arrange them.

## 3. iPod 1st generation

### 3.1 Body and front (mm; source: Apple's music.apple.com recreation scaled by Apple's 61.8 mm width)
| Feature | Value |
|---|---|
| Body | 61.8 × 102.0, corner radius 5.7, chrome rim 0.4 |
| Face | "iBook white": gradient `#FBFBFA` → `#F2F2F0` → `#E8E8E6`, the same gloss treatment as the 5G (diagonal sheen, no corner highlight) |
| Display window | 43.0 × 35.6, centred, top 4.6, corner 1.5; deep glossy near-black |
| LCD active area | 39.68 × 31.74 (160 × 128 × 0.248 mm), centred in the window |
| Button ring | Ø 52.1, centred, centre 32.3 above the bottom edge; four segments separated by thin gaps (0.6 mm) at 45°, 135°, 225° and 315°; surface `#EDEDED` with soft inset shading |
| Ring labels | top "menu" (lowercase), left ⏮, right ⏭, bottom ▶❚❚; grey `#9A9A9E`, engraved |
| Scroll wheel | Ø 41.1, concentric, fine radial texture, 0.3 mm darker edge `#7E7E7E`; **the texture rotates with the finger** |
| Select button | Ø 20.7, glossy convex, 0.3 mm `#9F9F9F` edge |

### 3.2 Gray LCD screen (`GrayScreen`)
Laid out in **LCD pixels** (160 × 128) and drawn at the model's pixel size (1.25 pt). Font: **ChicagoFLF 12 px** for everything (estimate; Chicago 12 was the iPod size).

| Element | Spec (px) |
|---|---|
| Palette, unlit [estimate] | background `#A3AD9A` → `#B3BCA9` (faint vertical gradient), ink `#22261F` |
| Palette, lit [estimate] | background `#D5E0F2` → `#E6EDF8`, ink `#1E2230` |
| Title bar | 20 px tall: title centred; ▶ (playing) or ❚❚ (paused) glyph at x 4 when a track is loaded; a pixel battery 16 × 8 at the right, 4 px inset; 1 px ink rule at y 19 |
| Rows | 6 × 18 px (y 20–127); text inset 4 px; `>` right-aligned 4 px from the edge on submenu rows; detail values right-aligned |
| Selection | full-width ink bar, text in background colour |
| Scroll bar | when a list exceeds 6 rows: 5 px column at the right; 1 px outline track; ink thumb, height ∝ 6/count, min 6 px; rows shrink by 6 px |
| Truncation | tail "…", no marquee (estimate for 1.3.1) |
| Now Playing | "x of y" at the top left (x 4, y 24); title, artist and album **centred** at y 42 / 58 / 74; bar 144 × 6 at (8, 96), 1 px ink outline, ink fill; elapsed at the left and `-remaining` at the right, at y 106 |
| Volume | the bar's place shows a speaker glyph at each end and an outlined bar with ink fill (2.0 s, as on the 5G) |
| Scrubber | the same bar with a 7 px ink diamond at the position (3.0 s idle, as on the 5G) |
| Clock (Extras) | time centred, large (Chicago 12 at 2× size), date below |
| Transitions | horizontal push, 0.25 s, the same mechanism as the 5G |

### 3.3 Scroll wheel and buttons
- **Wheel:** 96 sectors, **6 sectors per step (16 steps per turn)**, the same lift tolerance and dead zone, gentle acceleration (same curve), **no Quick Scroll**.
- **Hit areas:** inside Ø 20.7 → Select; Ø 20.7–41.1 → the wheel (drag spins, a tap does nothing); Ø 41.1–52.1 → the ring button for that quadrant (press and release go through the recognizer).
- **Visual rotation:** the wheel texture's angle follows the accumulated finger angle while dragging.

### 3.4 Behaviour (firmware 1.3.1 profile)
- **Hold MENU** (0.8 s) toggles the backlight. **Tap MENU** goes back.
- ⏭ / ⏮ taps, holds and the smart ⏮ work as on the 5G. ▶❚❚ plays or pauses.
- **Backlight:** any input (wheel, button, key) lights it for the **Backlight Timer**: Off / 2 / 5 / **10** (default) / 20 s / Always. It turns off on the tick. Holding MENU or the **Backlight** main-menu row toggles it on (for the timer) or off immediately. "Off" means it never lights automatically, but the toggles still work.
- **Root menu:** Playlists, Browse, Extras, Settings, Backlight, plus Now Playing while a track is loaded.
  - Browse: Artists, Albums, Songs (Apple Music library, the same engine as the 5G Music menu).
  - Extras: Clock.
  - Settings: Model, Source, Backlight Timer, Clicker.
- Clicker: the same 1 kHz tick and rate limit.

## 4. Testing
- **Unit:**
  - `ModelSpec`: 1G values match §3.1; 5G values equal the current constants
  - `IPodGeometry` for both models: 5G results unchanged; 1G body 61.8 × 102 mm → points at 5.04; ring, wheel and button positions
  - pixel-crisp rounding (5.023 → 1.25 pt; a 3.6 pt/mm external display → 0.75 pt minimum; 7.0 → 1.75 pt)
  - tracker with 6 sectors per step (90° = 4 steps)
  - 1G root, Browse and Settings menus
  - Model row cycling and persistence
  - Backlight: wakes on input, expires after the timer, Off and Always settings, MENU-hold toggle, Backlight row
  - hold MENU on 5G still goes home
  - scroll-wheel hit-area mapping (point → select, wheel or ring button)
- **Visual:** 1G renders (unlit menu, lit menu, Now Playing, scrubber, volume, Clock), checked against §3; a 5G render that should be pixel-identical to v0.3.0.
- **Manual:** switching models, the wheel feel at 16 steps, the backlight timing, ring presses vs wheel spins.
