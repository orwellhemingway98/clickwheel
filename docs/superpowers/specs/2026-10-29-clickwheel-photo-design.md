# ClickWheel: iPod photo (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-photo-dimensions.md` (Apple's drawing).

## Decisions (user)
- The U2 Special Edition is offered as a colour (White, U2 Special Edition), like the 4G.

## Spec

**Model.** `IPodModel.photo`: "photo", "iPod photo", 2004, between the 4th and 5th gen.

**Body.** The 4G's front: 61.80 × 103.50, corner 6.0, rim 0.4, edge band 5.7, face inset 5.6 / 6.0, face corner 3.4, glossy plastic tinted by the colour. Colours: `ColourChoice.photo` (key `photo`) with the 4G's White and U2 values; remembered separately from the 4G.

**Display.** Window 41.00 × 33.08, top 7.05, corner 1.0. Colour LCD 220 × 176 at 0.18 mm (39.6 × 31.68). The 5G colour interface laid out on a **225 × 180** design canvas (the 5G's 180 height at the panel's 5:4) and scaled to the panel; 9 visible rows as on the 5G.

**Controls.** The 4G's click wheel: Ø 42.06, centre 32.45 above the bottom, Select Ø 13.9, 6 sectors per step.

**Firmware** (photo 1.x). `.thirdGenLate` menus (Music, Extras › Clock, Settings, Shuffle Songs, Backlight, plus Now Playing); no Photos (nothing to show), no Stopwatch, no Quick Scroll. Hold MENU toggles the backlight; backlight on.

**Colour backlight.** On a colour model with a backlight, the screen dims (black overlay 0.6) while the backlight is off, fading like the gray screens. The 5G (no backlight) is unchanged.

## Plan (native, TDD)
1. **Model data.** `IPodModel.photo`, `ColourChoice.photo`, the spec. Tests: spec values; geometry at 10 pt/mm (body 618 × 1035, window 410 × 330.8 at top 70.5, wheel centre y 710.5, LCD 396 × 316.8, scale 1.76); Model list order and names; photo Settings rows with Colour; the photo's colour is separate from the 4G's.
2. **Colour screen per model.** `ScreenView` takes its canvas from `g.designSize`; `ScreenTheme.dimming(lit:backlight:)` gives the overlay opacity. Tests: dimming values. Regression: the 5G pixel-identical.
3. **Verify.** Suite; photo renders (white menu, U2, Now Playing, dimmed) measured against the drawing; 1G–3G, mini, 4G, 5G pixel-identical to v0.9.0; README; final reviewer.
