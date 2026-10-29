# ClickWheel: iPod nano (2nd generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-nano-2g-dimensions.md` (Apple's drawing); Apple
Wiki (silver, pink, green, blue, black; (PRODUCT) RED from November 2006); white
replacement click wheels sold for the coloured models.

## Decisions (user)
- All six colours, (PRODUCT) RED included.

## Spec

**Model.** `IPodModel.nanoSecondGen`: "nano 2G", "iPod nano (2nd gen)", 2006, after the 5th gen.

**Body.** 40.00 × 90.00, corner 0.6, no rim, edge band 4.3, anodized aluminium (`.aluminium`: the mini's tube drawing).

**Colours.** `ColourChoice.nanoSecondGen` (key `nanoSecondGen`), estimates:

| Colour | Body | Wheel | Button | Labels |
|---|---|---|---|---|
| Silver | `#C8CACD` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |
| Pink | `#F0A9C4` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |
| Green | `#A6D274` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |
| Blue | `#79B4E3` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |
| Black | `#2A2A2C` | `#1E1E20` | `#1E1E20` | `#9A9A9E` |
| (PRODUCT) RED | `#C8202F` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |

**Display.** Window 31.62 × 24.04, top 4.25, corner 0.5; the nano's 176 × 132 panel at 0.16 mm on the 240 × 180 canvas.

**Controls.** Click wheel Ø 30.16, centre 31.75 above the bottom, Select Ø 13.11, 6 sectors per step.

**Firmware.** As the nano: `.fifthGen` menus, hold MENU toggles the backlight, backlight on, 9 rows, no Quick Scroll.

## Plan (native, TDD)
1. **Model and colours.** Tests: spec values; geometry at 10 pt/mm (window top 42.5, wheel 301.6 at y 582.5, button 131.1); colour table; Model list order; Colour list of six, separate from the nano's. Then the model.
2. **Verify.** Suite; renders (silver, black, RED, Now Playing) measured against the drawing; other models pixel-identical to v0.12.0; README; final reviewer.
