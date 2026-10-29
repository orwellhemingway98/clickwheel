# ClickWheel: iPod nano (5th generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-nano-5g-dimensions.md` (Apple's drawing).

## Spec

**Model.** `IPodModel.nanoFifthGen`: "nano 5G", "iPod nano (5th gen)", 2009, last.

**Body.** The nano 4G's: 38.7 × 90.7, corner 1.0, no rim, edge band 5.0. New material `.polishedAluminium`: the aluminium face and curved sides, **no brushed grain, with the clear-front gloss**. `Material` gains `isMetal` (aluminium face), `isBrushed` and `showsGloss`.

**Colours.** `ColourChoice.nanoFifthGen` (key `nanoFifthGen`), estimates; wheel and button `#F2F2F0`, labels `#8E9399`, except Black (`#18181A`):
Silver `#C9CBCE`, Black `#1F2022`, Purple `#8E62B8`, Blue `#4F93D6`, Green `#7FC24A`, Yellow `#F5D33C`, Orange `#F28A2E`, Pink `#EC6FA6`, (PRODUCT) RED `#C8202F`.

**Display.** Window 29.9 × 46.8, top 27.8 − 23.4 = 4.4, corner 0.6. LCD 240 × 376 at 0.124 mm on a **180 × 282** portrait canvas.

**Controls.** Click wheel Ø 27.1, centre 20.0 above the bottom, Select Ø 13.2, 6 sectors per step.

**Firmware.** `.classic`, **14 rows**, hold MENU toggles the backlight, backlight on, no Quick Scroll.

**Portrait Now Playing grows with the screen.** Art side = canvas height − 160, centred, at y 42; info at y art.maxY + 18; bar at y height − 34. On 180 × 240 this is the nano 4G's layout exactly (art 80, info 140, bar 206); on 180 × 282: art 122 at x 29, info 182, bar 248.

Out of scope: camera, FM radio, pedometer.

## Plan (native, TDD)
1. **Model, colours, finish.** Tests: spec values; geometry at 10 pt/mm (window top 44, wheel 271 at y 707, LCD 297.6 × 466.24); colours; `Material` flags for all four materials; Model list. Then the model, `Material` flags and `IPodView` using them.
2. **Now Playing.** Tests: the 180 × 240 portrait layout unchanged; the 180 × 282 values and clearances. Then `NowPlayingLayout`.
3. **Verify.** Suite; renders (silver, purple, black, Now Playing) measured; other models pixel-identical to v0.16.0; README; final reviewer.
