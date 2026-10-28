# iPod 5G screen: working layout and colour values

All values are in **LCD pixels on the 320 × 240 panel**. ClickWheel lays its LCD
out at 240 × 180, so multiply by 0.75.

**Source.** These values were read from the Rockbox theme **iVideo** v1.2 (2011),
a fan recreation of the original 5G firmware look: the `.cfg`, `.sbs` and `.wps`
files plus samples from its bitmaps. Credit: *Modified/Derived from iVideo theme
for iPod Video (CC-BY-SA 3.0) by Humberto Santana*
(<http://themes.rockbox.org/index.php?themeid=1309&target=ipodvideo>). They are a
recreation, not values measured from Apple's firmware. Typography and behaviour
facts are in `reports/iPod 5G design study.md`.

## Global
| Item | Value |
|---|---|
| Background | `#FFFFFF` |
| Text | `#000000` |
| Secondary or upcoming text | `#888888` |
| Menu font | 24 px line height (ascent 17); the real font is Podium Sans (a Myriad derivative) |
| Title font | 18 px line height (ascent 14) |

## Title bar (y 0–23)
| Item | Value |
|---|---|
| Height | 24 px, with the UI viewport starting at y = 24 |
| Gradient | `#F8F8FF` (y0) → `#EBEEF1` (y7) → `#DDE1E4` (y13) → `#D0D4D6` (y21) |
| Bottom rule | 1 px `#6D747D` at y = 23 |
| Title | centred in x 60–260, y 4, 18 px font, black (the firmware adds a drop shadow) |
| Play/pause icon | x 11, y 4, 18 × 15 |
| Hold (lock) icon | x 36, y 5, 10 × 13 |
| Battery icon | x 286, y 6, 25 × 12 |

## Menus (y 24–239)
| Item | Value |
|---|---|
| Rows | 24 px each, so 9 visible rows in 216 px |
| Selection bar | full width, vertical gradient `#6BA6DE` → `#186DBD`, text `#FFFFFF` |
| Scrollbar | off in this theme |

## Now Playing
| Item | Value |
|---|---|
| "x of y" | x 15, y 32, 18 px font |
| Album art | 96 × 96 at x 15, y 61 |
| Art frame | a 4 px shade strip at each side, plus an 8 px soft shadow under it (`#C9C6C9` fading to `#FFFFFF`) |
| Title / artist / album | x 120, y 70 / 100 / 130, width 190, 18 px font |
| Progress bar | 280 × 15 at x 20, y 182 |
| Progress fill | glossy blue: `#62B6FF` `#7BC4FF` `#94CBFF` `#93D1FF` (top highlight) … `#45A9FF` (y7) … `#AAEBFF` `#B2EBFF` (bottom) |
| Progress track | glossy grey: `#DDDEDD` `#E4E4E4` `#F1F1F1` … `#D0D0D0` (y7) … `#F8F8F8` `#FFFFFF`, with a shadow line `#BABCBA` under it |
| Volume bar | replaces the progress bar while adjusting: 254 × 15 at x 29, y 182, speaker glyphs at x 12 and x 283 |
