# ClickWheel: iPod nano (1st generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-nano-dimensions.md` (Apple's drawing).

## Spec

**Model.** `IPodModel.nano`: "nano", "iPod nano", 2005, between the mini 2G and the 5th gen.

**Body.** 40.00 × 90.00, corner 3.0, polished rim 0.6, clear front over the colour (`.chromeAcrylic`, tinted by the colour, with the clear-front gloss).

**Colours.** `ColourChoice.nano` (key `nano`), estimates:

| Colour | Body | Wheel | Button | Labels |
|---|---|---|---|---|
| White | `#F4F4F2` | `#EEEEEC` | `#F6F6F4` | `#8E9399` |
| Black | `#161618` | `#2B2B2E` | `#2B2B2E` | `#9A9A9E` |

Black is a dark front, so it gets the subtle wheel edges.

**Display.** Window 29.57 × 22.18, top 90 − 73.64 − 11.09 = 5.27, corner 0.5. Colour LCD 176 × 132 at 0.16 mm, laid out on the 5G's 240 × 180 canvas (same 4:3), 9 rows.

**Controls.** Click wheel Ø 30.23, centre 31.79 above the bottom, Select Ø 13.0, 6 sectors per step.

**Firmware** (nano 1.x). `.fifthGen` menus (Music, Extras › Clock and Stopwatch, Settings, Shuffle Songs, plus Now Playing); no Quick Scroll; hold MENU toggles the backlight; backlight on, so the colour screen dims (as the photo).

## Plan (native, TDD)
1. **Model and colours.** Tests: spec values; geometry at 10 pt/mm (body 400 × 900, window top 52.7, wheel 302.3 at y 582.1, LCD 281.6 × 211.2); colours; Model list order; nano root (Music, Extras, Settings, Shuffle Songs) and Extras (Clock, Stopwatch); Settings rows with Colour and Backlight Timer; hold MENU keeps the menu. Then the model.
2. **Verify.** Suite; nano renders (white, black, Now Playing, dimmed) measured against the drawing; the other models pixel-identical to v0.11.0; README; final reviewer.
