# ClickWheel: iPod mini (1st generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-mini-dimensions.md` (Apple's drawing),
`research_notes/iPod mini design study/notes.md`.

## Decisions (user)
- Colour is picked from **Settings › Colour** (mini only): Silver, Gold, Pink, Blue, Green, with a ✓; remembered. Default Silver.
- Screen font: **Source Sans 3** (Espy Sans stand-in).
- **Exact life size**: no pixel snapping for the mini.

## Spec

**Model.** `IPodModel.mini`: short name "mini", list label "iPod mini", 2004. Placed between the 3rd and 5th gen.

**Body** (mm). 51.45 × 91.66, corner radius 0.6 (square-cornered tube), no chrome rim. Material: anodized aluminium in the selected colour, with soft shading on the 8.3 mm rounded side bands and a very fine brushed texture. No glossy sheen.

| Colour | Body (est.) | Wheel (est.) |
|---|---|---|
| Silver | `#C8CACD` | `#E4E5E7` |
| Gold | `#D8C79F` | `#ECE3CC` |
| Pink | `#E4B7C6` | `#F2DBE2` |
| Blue | `#9DB6D3` | `#CFDCEA` |
| Green | `#B3C99A` | `#DBE5CF` |

Wheel labels are grey `#8E9399` on every colour (1st-gen mini).

**Display.** Window 33.85 × 26.19, centred, top 6.28, corner 0.5, recessed near-black. LCD 138 × 110 px at 0.22 mm (30.36 × 24.20 mm). Four greys:
- unlit `#9AA592` → `#AAB4A2`, ink `#1C2219`
- lit (blue-white) `#D3DEF0` → `#E6EDF8`, ink `#1A2030`

No pixel snapping. Font Source Sans 3 (semibold for the title).

**Gray screen layout (per model).** The design size is the LCD's pixels; 20 px title bar; rows 18 px; visible rows from the firmware profile (mini: 5).
- Now Playing shows `nowPlayingLines` (mini: 2, title and artist) from y 42, 16 px apart.
- Bar at (8, height − 32), width − 16; times at height − 22.
- The 1G–3G (160 × 128, 6 rows, 3 lines) keep exactly their current positions.

**Controls.** Click wheel Ø 37.95, centre 28.75 above the bottom, Select Ø 12.50, MENU / ⏮ / ⏭ / ▶❚❚ on the wheel, 6 sectors per step (16 per turn). The tracker's sectors per step come from the model, which also fixes the hard-coded value in `ScrollWheelView`.

**Firmware.** The 2.3-style menu (`.thirdGenLate`): Music, Extras (Clock), Settings, Shuffle Songs, Backlight, plus Now Playing. Hold MENU toggles the backlight; backlight on; 5 visible rows; no Quick Scroll.
- Settings: Model, **Colour** (models that have colours), Source, Backlight Timer, Clicker.

## Plan (native, TDD)
1. **Data.**
   - `MiniColor` enum (label, body hex, wheel hex) and `AppSettings.miniColor` (persisted).
   - `ModelSpec`: `material` (`.chromeAcrylic`, `.whitePlastic`, `.aluminium`) and `hasColours`.
   - `DisplaySpec`: `pixelCrisp`, `font` (`.chicago` / `.sans`), `nowPlayingLines`.
   - `ModelSpec.mini`; `lifeSize` honours `pixelCrisp`.
   - Tests: spec values; geometry at 10 pt/mm (body 514.5 × 916.6, window top 62.8, wheel centre y 629.1, LCD 303.6 × 242.0); exact life size on the user's display (pointsPerMM = 1512/301); model list order.
2. **Navigator.**
   - The Colour row and list (like Model: opens at the top, ✓ on the current colour, choosing sets it and goes back).
   - Tests: mini Settings rows; selecting Pink persists; non-colour models have no Colour row; mini shows 5 rows (`windowStart` math).
3. **Gray screen per model.** `GrayLayout` derived from the design size and profile. `GrayScreenView`, `GrayMenuList` and `GrayNowPlaying` use it. The font comes from the spec. Regression: 1G, 2G and 3G renders pixel-identical.
4. **Body and wheel.**
   - `IPodView` chooses face, rim, gloss and edges by material; the aluminium face is tinted by `settings.miniColor`.
   - `ClickWheelView` takes colours from the model and colour (the 5G keeps its current colours) and builds its tracker from the model.
5. **Verify.** Suite; mini renders (silver dark, pink lit, Now Playing, Colour list) measured against the drawing; 1G, 2G, 3G and 5G pixel-identical; README; final reviewer.
