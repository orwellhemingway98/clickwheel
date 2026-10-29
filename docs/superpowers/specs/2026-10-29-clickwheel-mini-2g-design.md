# ClickWheel: iPod mini (2nd generation) (Spec and Plan)

**Date:** 2026-10-29. **Status:** approved ("write the spec and plan, then build it").
**Sources:** Apple, "Identify your iPod model" (A1051, February 2005: "The Click
Wheel text color matches the color of the device"); Wikipedia, *iPod Mini*
(brighter pink, blue and green; silver unchanged; gold dropped). Dimensions as the
mini (`docs/reference/ipod-mini-dimensions.md`; Apple has one mini drawing).

## Spec

**Model.** `IPodModel.miniSecondGen`: "mini 2G", "iPod mini (2nd gen)", 2005, between the iPod photo and the 5th gen. Body, display, controls and firmware as the mini; only the colours differ.

**Colours.** `ColourChoice.miniSecondGen` (key `miniSecondGen`), remembered separately from the mini (estimates):

| Colour | Body | Wheel | Button | Labels |
|---|---|---|---|---|
| Silver | `#C8CACD` | `#E4E5E7` | `#E4E5E7` | `#A6A9AE` |
| Pink | `#EFA6C2` | `#F8DDE8` | `#F8DDE8` | `#E48AAE` |
| Blue | `#86B6E6` | `#D6E6F6` | `#D6E6F6` | `#6A9FD6` |
| Green | `#A2D27E` | `#DDEFCF` | `#DDEFCF` | `#86BF5E` |

## Plan (native, TDD)
1. **Model and colours.** Tests: the spec equals the mini's apart from name, year and colours; the colour table; Model list order and names; Settings › Colour offers the four; the choice is separate from the mini's. Then the model and colour list.
2. **Verify.** Suite; mini 2G renders (silver, pink, blue, green); the other models pixel-identical to v0.10.0; README; final reviewer.
