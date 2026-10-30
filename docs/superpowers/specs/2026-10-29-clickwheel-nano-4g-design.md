# ClickWheel: iPod nano (4th generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-nano-4g-dimensions.md` (Apple's drawing).

## Spec

**Model.** `IPodModel.nanoFourthGen`: "nano 4G", "iPod nano (4th gen)", 2008, after the nano 3G.

**Body.** 38.7 × 90.7, corner 1.0, no rim, edge band 5.0, anodized aluminium (`.aluminium`).

**Colours.** `ColourChoice.nanoFourthGen` (key `nanoFourthGen`), estimates; wheel and button `#F2F2F0` with labels `#8E9399`, except Black (wheel and button `#18181A`):
Silver `#C9CBCE`, Black `#1F2022`, Purple `#9A7FC0`, Blue `#6FA8DC`, Green `#9CCB6B`, Yellow `#F1D46A`, Orange `#F3A25A`, Pink `#EE9FC0`, (PRODUCT) RED `#C8202F`.

**Display.** Window 29.9 × 39.8, top 24.3 − 19.9 = 4.4, corner 0.6. Colour LCD 240 × 320 at 0.124 mm, on a **180 × 240 portrait canvas**.

**Controls.** Click wheel Ø 28.5, centre 23.3 above the bottom, Select Ø 13.2, 6 sectors per step.

**Firmware.** `.classic` (its look and menus, title "iPod"), **12 rows**, hold MENU toggles the backlight, backlight on, no Quick Scroll.

**Portrait.**
- Colour menu lists show the model's `visibleRows` (was a fixed 9; every existing colour model has 9).
- The classic split screen only on landscape canvases (`ClassicLayout.splits(canvas:)`).
- `NowPlayingLayout(canvas:)`: landscape returns today's positions (art 11, 46, 72 × 72; info at 90, 52, leading, width w − 98; bar 15, 137, w − 30 × 11). Portrait (as built): the counter centred on its own row at y 22; art a square of side min(h − 160, w − 16), centred, at y 42 (80 on the nano 4G, 122 on the 5G); info centred, x 8, width w − 16, first line at art bottom + 18; bar 15, h − 34, w − 30 × 11.

Cover Flow on rotation is out of scope (no tilt sensor).

## Plan (native, TDD)
1. **Model and colours.** Tests: spec values; geometry at 10 pt/mm (body 387 × 907, window top 44, wheel 285 at y 674, LCD 297.6 × 396.8); colours; Model list. Then the model.
2. **Rows and split.** Tests: every colour model's rows fit its canvas (header 18 + rows × 18 ≤ height); `splits` true for 240 × 180, false for 180 × 240. Then `MenuListView` and `ScreenView`.
3. **Portrait Now Playing.** Tests: `NowPlayingLayout` landscape equals today's constants; portrait values above. Then `NowPlayingView` uses it.
4. **Verify.** Suite; renders (silver menu, orange, black, Now Playing) measured; other models pixel-identical to v0.15.0; README; final reviewer.
