# ClickWheel: iPod (3rd generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved by the user ("write the spec and plan, then build it").
**Sources:** `docs/reference/ipod-3g-dimensions.md` (Apple's drawing),
`research_notes/iPod 3G design study/notes.md`.

## Decisions
- Firmware **2.3**: the main menu is Music, Extras, Settings, Shuffle Songs, Backlight, plus Now Playing while playing.
- Button labels glow **red with the backlight** and fade with it.

## Spec

**Model.** `IPodModel.thirdGen` ("3rd gen", "3rd generation", 2003), between the 2nd and 5th gen in the Model list.

**Body** (mm). 61.80 × 103.49, corner 6.0, rim 0.4. A rounded-edge band 5.9 mm wide on each side is drawn as soft side shading, with a faint outline of the flat face (inset 5.9 at the sides, 5.2 at the top, 7.2 at the bottom, corner 3.4). Face material is the 1G's "iBook white".

**Display.** Window 40.29 × 32.61, centred, top 7.24, corner 1.0. LCD 160 × 128 at 0.248 mm (the gray screen, as on the 1G).
- Palette: unlit `#5A915A` → `#66A066`, ink `#0E1A0E`; lit `#ADD8E6` → `#C4E4EE`, ink `#102028` (Rockbox colours, as gradients).
- Pixel-crisp scale, as on the 1G.

**Controls** (`ControlKind.buttonRow`)
- Touch wheel Ø 38.70, centre 26.41 above the bottom. It's smooth and still, with no ring or labels; 6 sectors per step (16 per turn).
- Select Ø 14.50.
- Four round touch buttons Ø 10.90, row centre 49.91 below the top, centres at x = 30.90 ± 6.65 and ± 19.95 (13.3 apart). Left to right: ⏮, MENU, ▶❚❚, ⏭.
- Button labels are red `#FF3B2F` with a soft glow while the backlight is on, grey `#9A9A9E` while it's off, cross-fading over 0.6 s.
- A button press goes through `WheelInput.press/release`, so taps and holds work: hold MENU toggles the backlight, hold ⏮/⏭ rewinds or fast-forwards. A press that moves 6 pt or more, or leaves the button, is cancelled.

**Firmware profile.** `menuStyle: .thirdGenLate`, `holdMenu: .toggleBacklight`, `quickScroll: false`, `backlight: true`, `visibleRows: 6`.
- Root: Music (the Music menu), Extras (Clock), Settings, Shuffle Songs (the Shuffle action), Backlight (toggle), plus Now Playing.
- Settings: Model, Source, Backlight Timer, Clicker.

**Non-goals.** Contacts, Calendar, Notes, Games, ratings, On-The-Go, Contrast, Hold switch.

## Plan (native, TDD)

1. **Model data and geometry.**
   - Add `BodySpec.edgeBand` and `faceInset`; add `ControlKind.buttonRow`, `ControlSpec.rowButtonDiameter`, `rowCenterFromTop` and `rowSpacing`; add `MenuStyle.thirdGenLate`, and `ModelSpec.thirdGen` with the values above.
   - `IPodGeometry` gains `rowButtonDiameter`, `rowCenterY` and `rowSpacing`.
   - Tests: the spec values; the geometry at 10 pt/mm (window 402.9 × 326.1, top 72.35; row centre y 499.1, spacing 133, button 109; wheel 387 at y 770.8); model order and names.
2. **Button row hit areas.** `ButtonRowLayout(diameter:spacing:).button(at:) -> WheelButton?` (point relative to the row centre). Tests: each centre maps to its button; a point between buttons, or outside a circle, maps to nil.
3. **3G menus.** The `.thirdGenLate` root and Settings. Tests: the root with and without a track; Shuffle Songs present; Settings rows. Update the Model-list tests for the extra row.
4. **Views.**
   - `ScrollWheelView` skips the ring when the ring diameter equals the wheel's.
   - New `ButtonRowView`.
   - `IPodView` draws the edge band and face outline when `edgeBand > 0`, uses the white face for all scroll and touch-wheel models, and places the button row.
   - `GrayScreenView` reads the palette from the model (already does).
5. **Verify.** Full suite; 3G renders (unlit, lit, Now Playing) measured against the drawing (body, window top, row and wheel); pixel-identical 1G, 2G and 5G renders against v0.6.1; README model table; final reviewer.
