# ClickWheel: iPod nano (3rd generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-nano-3g-dimensions.md` (Apple's drawing).

## Spec

**Model.** `IPodModel.nanoThirdGen`: "nano 3G", "iPod nano (3rd gen)", 2007, after the classic.

**Body.** 52.3 × 69.8, corner 4.5, steel rim 0.8, no edge bands; an aluminium plate (`.aluminium`) tinted by the colour.

**Colours.** `ColourChoice.nanoThirdGen` (key `nanoThirdGen`), estimates; white wheel and button on all but black:

| Colour | Body | Wheel | Button | Labels |
|---|---|---|---|---|
| Silver | `#C9CBCE` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |
| Black | `#1F2022` | `#18181A` | `#18181A` | `#8E9399` |
| Blue | `#8FC3D8` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |
| Green | `#A9D3A0` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |
| Pink | `#EDB3C8` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |
| (PRODUCT) RED | `#C8202F` | `#F2F2F0` | `#F2F2F0` | `#8E9399` |

**Display.** Window 39.8 × 29.9, top 20.2 − 14.95 = 5.25, corner 0.8; 320 × 240 at 0.12 mm on the 240 × 180 canvas.

**Controls.** Click wheel Ø 27.0, centre 17.6 above the bottom, Select Ø 13.2, 6 sectors per step.

**Firmware.** As the classic: `.classic` menus (split screen, panning art, classic look, title "iPod"), hold MENU toggles the backlight, backlight on, 9 rows, no Quick Scroll.

## Plan (native, TDD)
1. **Model and colours.** Tests: spec values; geometry at 10 pt/mm (body 523 × 698, window top 52.5, wheel 270 at y 522, button 132, LCD 384 × 288); colours; Model list; the classic menus and split screen on this model. Then the model.
2. **Verify.** Suite; renders (silver root, blue, black, Now Playing) measured against the drawing; other models pixel-identical to v0.14.0; README; final reviewer.
