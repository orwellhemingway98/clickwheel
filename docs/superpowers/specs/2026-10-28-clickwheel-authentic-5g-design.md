# ClickWheel: Authentic 5G Design Pass (Design Spec)

**Date:** 2026-10-28
**Status:** Draft, awaiting review
**Research basis:** `reports/iPod 5G design study.md`, `docs/reference/ipod-5g-dimensions.md`,
`docs/reference/ipod-5g-screen-values.md`

## 1. Purpose

Make ClickWheel look and behave like a real white iPod 5th generation in three
areas: the colour screen UI, the physical rendering, and the wheel and button
behaviour. The life-size geometry from the previous pass stays as it is.

### Decisions the user made
- Main menu shows **only working items**: Music, Extras, Settings, Shuffle Songs, and Now Playing while something plays.
- Acceleration is **gentle and Apple-like**, not Rockbox's quartic curve. Quick Scroll is included.
- Screen values come from the Rockbox **iVideo** theme (CC-BY-SA 3.0, credited in the reference file).
- Scale stays **life size**. The LCD is drawn as vectors, so it stays sharp.

### Non-goals
- Bitmap Podium Sans. Source Sans 3 stays.
- Photos, Videos, Games, Contacts, Calendar, Notes, Voice Memos, ratings, lyrics, On-The-Go, Search.
- Hold switch, backlight and brightness settings.
- Spotify menus (stage 3).

## 2. Screen UI

All LCD values are in **design points** (240 × 180 = 0.75 × the 320 × 240 panel) and live in one
`ScreenTheme` (colours, sizes, durations), so measured values can replace them later.

| Element | Spec (design pt) |
|---|---|
| Background, text | `#FFFFFF`, `#000000`; secondary text `#888888` |
| Header | 18 pt tall; gradient `#F8F8FF` → `#EBEEF1` (0.3) → `#DDE1E4` (0.55) → `#D0D4D6`; 0.75 pt bottom rule `#6D747D` |
| Header title | centred in x 45–195, semibold 13.5 pt, black, drop shadow white 0.8 opacity, 0.75 pt below |
| Header icons | play ▶ or pause ❚❚ glyph at x 8, blue `#186DBD`, shown only when a track is loaded; battery 19 × 9 at x 214, outline `#3A3F45`, fill a green gradient |
| Menu rows | 18 pt each, 9 visible (162 pt); text 13.5 pt; 6 pt left and right inset |
| Selection bar | full width, gradient `#6BA6DE` → `#186DBD`, text white semibold |
| Row accessories | `›` on rows that open a submenu; right-aligned detail text (`#888888`; white when selected) |
| Truncation | tail "…"; the **selected** row marquees after a 1.0 s pause at 30 pt/s, waits 1.0 s at the end, then restarts |
| Now Playing | "x of y" at (11, 24), 12 pt; art 72 × 72 at (11, 46) with a 3 pt side shade and a 6 pt soft shadow underneath; title, artist and album at x 90, y 52 / 74 / 96, width 142, 13.5 / 12 / 12 pt |
| Progress bar | 210 × 11 at (15, 137); glossy blue fill (stops from the reference file); glossy grey track; shadow line under it; elapsed at left, `-remaining` at right, 10.5 pt, 4 pt below the bar |
| Volume overlay | the wheel on Now Playing swaps the progress bar for a volume bar (same frame, inset 22 pt for speaker glyphs at each end) for **2.0 s** after the last change |
| Scrubber | Center on Now Playing swaps the progress bar for a scrub bar with a **diamond** playhead. The wheel seeks 2 s per step, accelerated like the lists. It returns to normal after **3 s** idle or on MENU. The seek is sent on each step. |
| Transitions | entering a screen pushes it in from the right, leaving pushes back; **0.25 s ease-out**; the header title cross-fades |
| Quick Scroll | in Songs, Artists and Albums, when acceleration multiplier ≥ 2, show the current row's first letter (A–Z, otherwise `#`) centred in an 80 × 80 rounded dark translucent square, 48 pt white semibold; it fades out **1.0 s** after the last scroll |

## 3. Physical rendering

- **Display window:** deep glossy near-black (`#101214` → `#1A1C1F`), **no border stroke**. The LCD sits inside with the even 1.25 mm margin already in `IPodGeometry`.
- **Continuous gloss:** one specular sweep is drawn over the whole face *including* the window, because the clear layer covers both. The separate screen glare is removed.
- **Rim:** `IPodGeometry` rim width changes from 0.6 to **0.4 mm**.
- **Inner edge:** a faint 0.5 pt line inset 0.6 mm from the face edge (white layer under clear).
- **Colours:** face base `#F7F7F5` (highlight to `#FFFFFF`), wheel `#EEEEEC`, labels `#ADADB1`, center button `#F6F6F4`.

## 4. Wheel, buttons and navigation

### 4.1 Wheel input (`WheelGestureTracker` extended)
- Finger angle is quantised to **96 sectors** (3.75°); one step every **4 sectors**. The remainder is kept.
- Lifts shorter than **150 ms** continue the same gesture (the accumulator is kept).
- Dead zone stays at 12 pt (it re-anchors on exit, as before).

### 4.2 Acceleration (`ScrollAccelerator`, new, pure)
- Velocity in °/s, smoothed `v = (3·v + v_new) / 4` per step (gentler than Rockbox's 1/16 weight).
- Resets after **250 ms** without steps, or on a direction change.
- Multiplier: `1` below 300°/s; `max(1, round((v / 300)²·2 − 1))` above that, **capped at 8**. That gives ≈ ×2 at 350°/s, ×4 at 450°/s and ×8 at about 600°/s.
- Applies to menu scrolling and the scrubber, **not** to volume.

### 4.3 Buttons (`ButtonGestureRecognizer`, new, pure)
- Each ring button and the center report **press** and **release** separately. The view sends press and release; the recognizer emits tap or hold events.
- **Hold threshold: 0.8 s.** A tap fires on release only if no hold fired.

| Input | Tap | Hold |
|---|---|---|
| MENU | back | jump to main menu |
| ⏭ | next track | fast-forward (seek +5 s every 0.25 s while held) |
| ⏮ | restart the track if position > 3 s, otherwise previous track | rewind (seek −5 s every 0.25 s) |
| ▶❚❚ | play/pause | none |
| Center | select; on Now Playing, toggle the scrubber | none |

- Keyboard: ← and → tap ⏮ and ⏭ (holding them auto-repeats into fast-forward or rewind); Escape held for 0.8 s means MENU hold.
- New player commands: `seek(by seconds:)`, `setPosition(_:)` and `restartOrPrevious()`, on `PlayerControlling`, `MusicSource` and both AppleScript sources (`player position`).

### 4.4 Clicker
- **1 kHz, 4 ms** square-ish tick, synthesized as before.
- One tick per **row moved**, rate-limited to one tick per 25 ms. No tick when the selection can't move.

### 4.5 Menus
- Root: **Music**, **Extras**, **Settings**, **Shuffle Songs**, plus **Now Playing** appended while a track is loaded.
- Extras → **Clock** (a large time and date screen, updated every second) and **Stopwatch** (Center starts and stops, ▶❚❚ resets; shows mm:ss.t).
- Shuffle Songs: plays 100 random songs from the Apple Music library via the ClickWheel playlist, then shows Now Playing.
- Settings: Source, Clicker (unchanged).

## 5. Testing
- **Unit tests:**
  - 96-sector quantisation and the 150 ms lift continuation
  - `ScrollAccelerator` multipliers at 200, 350, 450 and 700°/s, plus the reset rules
  - `ButtonGestureRecognizer` tap vs hold and the release rule
  - restart-or-previous at 2 s and 5 s
  - Quick Scroll letter selection (including `#` for digits and symbols)
  - marquee timing as a pure function of elapsed time
  - scrubber seek mapping
  - volume overlay timeout
  - root menu with and without a loaded track
  - Clock and Stopwatch formatting
- **Visual:** snapshot renders of the menu, Now Playing, scrubber and volume screens, checked against the reference values.
- **Manual:** feel of acceleration and hold timings, sound of the click, the transitions.
