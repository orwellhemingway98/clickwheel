# iPod (1st generation): front layout values

**Source.** Apple's own interactive recreation of the 1G iPod on the Apple Music
"Page Not Found" page (<https://music.apple.com/404>, "Give this a spin instead"),
inspected in a browser on 2026-10-28. Its component is `web-music-ipod`
(`/includes/ipod/web-music-ipod.esm.js`). Only element boxes and computed styles
were read; no Apple artwork or code was copied.

**Scale.** The recreation's body is 415 px wide, set equal to the documented
61.8 mm width, so 1 mm = 6.715 px. Its body is 692 px tall (103.1 mm at that
scale), against Apple's documented 102 mm. Vertical positions below are therefore
measured from the **bottom** edge (wheel) or the **top** edge (screen), and the
documented height is kept. The documented body is **102 × 61.8 × 19.9 mm**
(Apple spec via EveryMac, Low End Mac and apple-history.com).

| Feature | px (recreation) | mm | Notes |
|---|---|---|---|
| Body | 415 × 692 | 61.8 × 103.1 | use the documented 61.8 × 102.0 |
| Body corner radius | 38 | **5.7** | |
| Display window (outer) | 289 × 239, centred | **43.0 × 35.6** | dark border 8 px = 1.2 mm; window corner radius 10 px = 1.5 mm |
| Window top from body top | 31 | **4.6** | |
| LCD area inside the border | 273 × 223 | **40.7 × 33.2** | close to 160 × 128 at 4:3.2 |
| Button ring (outer) | 350 Ø, centred | **52.1 Ø** | four separate segments: menu (top), ⏮, ⏭, ▶❚❚ |
| Ring centre from bottom edge | 217 | **32.3** | 692 − (300 + 175) |
| Rotating scroll wheel | 276 Ø | **41.1 Ø** | concentric with the ring |
| Select (center) button | 139 Ø | **20.7 Ø** | |
| MENU label | lowercase "menu", about 55 × 24 px at the ring's top | | the glyphs ⏮ ⏭ ▶❚❚ are about 23 × 11 px |

## Look (from computed styles; colours are that recreation's choices)
- Body face: a diagonal light-grey to white gradient (`#D4D4D4` → `#FEFEFE`), with
  inset shadows that read as a chrome edge.
- Display window: 8 px near-black border (`rgba(24,24,24,0.7)`) with an inner dark
  ring. The LCD gradient runs `#A5A59B` → `#D6D5D0` (grey-green), with text `#484647`.
- Button ring: `#EDEDED` with soft inset shading. The scroll wheel has a fine
  texture (a PNG pattern) and a `#7E7E7E` 2 px edge. The select button has a
  `#9F9F9F` 2 px edge and a soft radial highlight.
- Font: "ChicagoKare", a Chicago recreation.

These are Apple's 2026 recreation, not measurements of a 2001 unit. They are the
best front-layout source found. Every other source gives only overall dimensions
(see `reports/iPod 1G design study.md`).
