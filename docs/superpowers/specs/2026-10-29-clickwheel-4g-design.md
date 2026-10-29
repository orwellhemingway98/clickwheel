# ClickWheel: iPod (4th generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-4g-dimensions.md` (Apple's drawing); Apple's
"Identify your iPod model" (U2 edition: black front, red click wheel); the 4G is
the last full-size iPod with Chicago on screen.

## Decisions (user)
- The **U2 Special Edition** is offered as a colour of the 4G (Settings › Colour: White, U2 Special Edition).
- Colours are per model; each model remembers its own choice.

## Spec

**Model.** `IPodModel.fourthGen`: "4th gen", "4th generation", 2004, between the mini and the 5th gen.

**Body** (mm). 61.80 × 103.50, corner 6.0, rim 0.4, edge band 5.7, flat-face inset 5.6 top / 6.0 bottom, face corner 3.4. Glossy plastic front (`.whitePlastic`) tinted by the chosen colour, with the clear-front gloss.

**Colours** (per model, `BodyColour`: id, label, body, wheel, button, labels):

| Model | Colour | Body | Wheel | Button | Labels |
|---|---|---|---|---|---|
| 4G | White | `#F4F4F2` | `#EEEEEC` | `#F6F6F4` | `#8E9399` |
| 4G | U2 Special Edition | `#1B1B1D` | `#C41E2A` | `#C41E2A` | `#1A1A1A` |
| mini | Silver, Gold, Pink, Blue, Green | as v0.8.0 | as v0.8.0 | = wheel | `#8E9399` |

U2 values are estimates (Apple only names black and red).

**Display.** Window 41.5 × 34.0, top 6.59, corner 1.0. LCD 160 × 128 at 0.24 mm, Chicago, 6 rows, 3 Now Playing lines, pixel-crisp. Palette (estimated): unlit `#A9AFA6` → `#B7BCB3`, ink `#1E211D`; lit `#DCE4EE` → `#EEF2F7`, ink `#1C2026`.

**Controls.** Click wheel Ø 42.06, centre 32.46 above the bottom, Select Ø 13.9, 6 sectors per step.

**Firmware.** `.thirdGenLate`, hold MENU toggles the backlight, backlight on, 6 rows, no Quick Scroll, colours White / U2.

**Colour plumbing.**
- `FirmwareProfile.colours: ColourChoice?` (`key` + `options: [BodyColour]`) replaces the `colours: Bool` flag; `ModelSpec.hasColours` = it's non-nil.
- `AppSettings.colour(in:) -> BodyColour` / `setColour(_:in:)`: persisted per key (`colour.<key>`); default the first option. The mini (key `mini`) falls back to the v0.8.0 `miniColor` value. `MiniColor` is replaced by `BodyColour.mini`.
- The Colour list behaves as before (opens at the top, ✓ on the current colour, choosing sets it and goes back).
- `MiniFinish` becomes `BodyFinish(colour:)`, used by any model with colours: face, wheel, button and label colours. The 5G keeps its theme.

## Plan (native, TDD)
1. **Per-model colours.** `BodyColour`, `ColourChoice`, the lists, settings per key with the mini fallback, the Navigator Colour row and list from the profile. Tests: lists and values; per-model persistence; legacy `miniColor` read; 4G Settings rows; choosing U2 persists and goes back; the 3G and 5G have no Colour row. Update the mini tests to the new API.
2. **4G model and geometry.** Spec values; geometry at 10 pt/mm (body 618 × 1035, window top 65.9, wheel centre y 710.4, LCD 384 × 307.2); Model list order.
3. **Views.** `BodyFinish`; the plastic face tinted by the colour when the model has colours; `ClickWheelView` takes wheel, button and label colours from it.
4. **Verify.** Suite; 4G renders (white dark, white lit, U2, Now Playing) measured against the drawing; mini, 1G–3G and 5G pixel-identical to v0.8.0; README; final reviewer.
