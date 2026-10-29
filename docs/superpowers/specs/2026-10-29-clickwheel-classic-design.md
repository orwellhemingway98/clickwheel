# ClickWheel: iPod classic (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-classic-dimensions.md` (Apple's drawing).

## Decisions (user)
- The classic's own **split-screen** interface (menu left, panning album art right). Cover Flow is left for later.

## Spec

**Model.** `IPodModel.classic`: "classic", "iPod classic", 2007, after the nano 2G.

**Body.** 61.8 × 103.5, corner 6.8, steel rim 1.0, no edge bands; an anodized aluminium plate (`.aluminium`: brushed, no gloss) tinted by the colour.

**Colours.** `ColourChoice.classic` (key `classic`), estimates:

| Colour | Body | Wheel | Button | Labels |
|---|---|---|---|---|
| Silver | `#C9CBCE` | `#E9EAEB` | `#D2D4D7` | `#8E9399` |
| Black | `#1F2022` | `#18181A` | `#18181A` | `#8E9399` |

**Display.** Window 52.0 × 39.5, top 24.7 − 19.75 = 4.95, corner 1.0; the 5G's 320 × 240 panel at 0.156 mm on the 240 × 180 canvas.

**Controls.** Click wheel Ø 38.0, centre 30.4 above the bottom, Select Ø 13.7, 6 sectors per step.

**Firmware.** `MenuStyle.classic`: the 5G's root (Music, Extras › Clock and Stopwatch, Settings, Shuffle Songs, plus Now Playing), title "iPod"; hold MENU toggles the backlight; backlight on (the colour screen dims); 9 rows; no Quick Scroll.

**Split screen.** On a `.classic` model, the root menu (depth 1) and the Music menu show the list on the left half (120 of 240 points) and an art panel on the right half; deeper menus use the full width. `ClassicLayout.isSplit(depth:title:)` decides.
- The art panel shows the current track's artwork, filling the panel, with a slow Ken Burns move: scale 1.0 → 1.15 and a drift, 14 s each way, repeating. A thin dark rule separates it from the list. With no artwork, a soft grey gradient.

**Look.** On `.classic` the selection is a glossier, brighter blue (`#5FAEF5` → `#2577D9` with a white sheen on the top half) and the header is lighter (`#FBFBFB` → `#DADDE1`). Other models are unchanged.

## Plan (native, TDD)
1. **Model, colours, menus.** Tests: spec values; geometry at 10 pt/mm (window 520 × 395 at top 49.5, wheel 380 at y 731, button 137); colours; Model list; the classic root and title; Settings rows; hold MENU. Then `MenuStyle.classic`, the spec, the Navigator root.
2. **Split screen.** Tests: `ClassicLayout.isSplit` (root yes, Music yes, Settings no, a Music submenu no) and the Ken Burns values (`ClassicLayout.kenBurns(phase:)` at 0, 0.5 and 1). Then `ClassicMenuView` and `ClassicArtPanel`.
3. **Look.** Tests: `ScreenTheme.selection(for:)` and `headerGradient(for:)` give the classic set only for `.classic`. Then wire them.
4. **Verify.** Suite; classic renders (silver root, black root, Settings full width, Now Playing) measured against the drawing; other models pixel-identical to v0.13.0; README; final reviewer.
