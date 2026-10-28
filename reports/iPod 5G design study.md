# Rebuilding the iPod 5G, measure by measure

The white iPod 5th generation (iPod with video, October 2005) can be rebuilt with high geometric precision, but only partly with documented precision. **The physical front is fully fixed by Apple's own dimensional drawing.** It is a 61.80 × 103.50 mm face with a 52.42 × 39.94 mm display window, a 38.10 mm Click Wheel and a ≈13.7 mm center button, and the window sits behind an even 4.69 mm border on three sides ([Apple Accessory Design Guidelines R4, Fig. 16-72](https://images-eu.ssl-images-amazon.com/images/I/E1-CkFcRAZS.pdf)). **The interaction model is the next best documented layer.** Apple's Features Guides fix every button gesture and the menu tree, and Rockbox's driver for the same hardware supplies the numbers Apple never published: 96 wheel positions per turn, one list step per 15°, velocity-based acceleration above 270°/s, and a 1 kHz, 4 ms piezo click ([Rockbox button-clickwheel.c](https://raw.githubusercontent.com/Rockbox/rockbox/master/firmware/target/arm/ipod/button-clickwheel.c); [Rockbox piezo.c](https://raw.githubusercontent.com/Rockbox/rockbox/master/firmware/target/arm/ipod/piezo.c)). **The on-screen UI is the weakest layer.** The typeface (Podium Sans, a bitmap derivative of Myriad), its five firmware sizes and black menu text are documented. No public source gives row heights, header height, highlight gradients or transition timing ([The Apple Wiki: Podium Sans](https://theapplewiki.com/wiki/Podium_Sans); [TechCrunch/iPodWizard](https://techcrunch.com/2007/05/15/spice-up-that-ipod-with-new-font-colors/)). No sourced colour value exists for any part of the device either. In practice, ClickWheel can ship an exact body, an exact control model and a credible but provisional screen. Closing the screen gaps takes one specific step: reading the 5G firmware's layout and image resources with iPodWizard or sampling a real 320 × 240 framebuffer.

**How to read the evidence in this report.** Every spec is tagged with one of four tiers. **[Apple]** marks a value from Apple's drawing, press releases or Features Guides. **[Firmware]** marks a value read out of Apple's firmware resources by the community tool iPodWizard. **[Rockbox]** marks a value from the open-source Rockbox firmware, which runs on the same hardware. Its hardware constants come from the real wheel controller, but its timing and curves are Rockbox's own design choices, not Apple's. **[Estimate]** marks a value derived by arithmetic from the above, or a design recollection that no source confirms. Treat [Estimate] values as placeholders to verify.

## Apple's drawing fixes the front face to ±0.2 mm

The authoritative geometry comes from Apple's *Accessory Design Guidelines for Apple Devices*, Release R4 (2017-09-21), §16.67, **Figure 16-72, "iPod 5th gen. 30GB Dimensional Drawing"** (Apple drawing iPod10-12). Its stated tolerances are ±0.4 mm on one-decimal values and ±0.20 mm on two-decimal values ([Apple Accessory Design Guidelines](https://images-eu.ssl-images-amazon.com/images/I/E1-CkFcRAZS.pdf); summarised in the project file `docs/reference/ipod-5g-dimensions.md`). Values the drawing does not label were measured from the to-scale drawing at 12.13 px/mm. That scale was checked against the labelled body width, window and wheel, which agree within 0.5%.

| Feature | Value (mm) | Tier | Notes |
|---|---|---|---|
| Body width × height | **61.80 × 103.50** | [Apple] labelled | Aspect ratio 1 : 1.675 |
| Body depth | **11.00** (30 GB); 14.0 (60/80 GB) | [Apple] labelled | Spec sheet says 10.92 / 13.97 ([The Apple Wiki](https://theapplewiki.com/wiki/IPod_with_video)) |
| Body corner radius | **≈ 6.8** | [Apple] measured from drawing | Circle fit to the outline |
| Top edge step | **0.39** | [Apple] labelled | Front face sits just below the back shell |
| Display window | **52.42 × 39.94**, corner radius ≈ 1.0 | [Apple] labelled; radius measured | Centred horizontally |
| Window centre | **78.84 above bottom edge** | [Apple] labelled | Window top is 4.69 below the top edge |
| Window border | **4.69 top, left and right** | [Estimate] derived | One even border around the screen |
| LCD active area | **49.92 × 37.44** | [Apple] | 320 × 240 px at 0.156 mm dot pitch |
| Black mask around the LCD | **1.25 on every side** | [Estimate] derived | (52.42 − 49.92) / 2 = (39.94 − 37.44) / 2 |
| Click Wheel diameter | **38.10** | [Apple] labelled | 0.617 × body width |
| Click Wheel centre | **30.44 above bottom edge** | [Apple] labelled | Centred horizontally |
| Window-to-wheel gap | **9.38** | [Estimate] derived | |
| Wheel to bottom edge | **11.39** | [Estimate] derived | |
| Center button diameter | **≈ 13.7** | [Apple] measured from drawing | 0.36 × wheel diameter |
| Touch ring width | **≈ 12.2** (radius 6.85 → 19.05) | [Estimate] derived | Ring midline at r ≈ 12.95 |

Two derived facts matter for the app. First, the active LCD is centred in its window with an identical **1.25 mm black margin on all four sides**. The earlier research estimate of 0.8–1 mm, based on a nominal 2.5-inch panel, is superseded by Apple's 0.156 mm dot pitch. Second, the project's dimensions file gives two ready-made point scales. At **4.531 pt/mm** (the current v0.2 width), the body is 280 × 469 pt, the corner radius 30.6 pt, the window 237.5 × 181.0 pt at 21.2 pt from the top, and the wheel and button 172.6 pt and 62.0 pt with the wheel centre 331 pt from the top. At **life size on a 127.5 pt/in display (5.020 pt/mm)**, these become 310 × 520 pt, 33.9 pt, 263.1 × 200.5 pt at 23.5 pt, and 191.2 / 68.7 pt with the centre at 367 pt.

A third scale deserves consideration [Estimate]. If the 320 × 240 framebuffer is drawn at exactly one point per LCD pixel, the scale becomes **6.41 pt/mm** (320 / 49.92). The body is then about 396 × 663 pt, the window 336 × 256 pt and the wheel 244 pt. At that scale the screen renders with no resampling, at 2× on Retina. At the two smaller scales the bitmap UI has to be scaled down (to 0.71× or 0.78×), which blurs a pixel font. That trade-off between size on the desk and screen crispness is the main geometric decision left for ClickWheel.

## Clear-over-white polycarbonate makes the face, and nobody published its colours

**The front is one glossy plastic part over a mirror-polished back.** The Apple Wiki describes a glossy plastic front plate with a chrome back, the same language as the iPod nano ([The Apple Wiki](https://theapplewiki.com/wiki/IPod_with_video)). Reviewers called the back "mirror-shiny" and noted it shows fingerprints and fine scratches ([MobileTechReview](https://mobiletechreview.com/iPod/iPod-video.htm)). The white look comes from **doubleshot molding: a transparent layer molded over an opaque white one**. Engadget ties Apple's "clear-over-white and clear-over-black molding" to patent application US 2007/0048470 ([Engadget](https://www.engadget.com/2007-03-05-apples-doubleshot-casting-and-the-zune.html)). That application names Jonathan Ive among its inventors, was filed in August 2005, two months before launch, lists PC, ABS and PC-ABS, and says polycarbonate works particularly well. Its example walls are about 1.5 mm at the front, but the example device is a small keylike player, not the 5G ([Google Patents US20070048470A1](https://patents.google.com/patent/US20070048470A1/en)). The family precedent is explicit: the 2001 iPod had a white polycarbonate front set into a mirror-finish stainless steel case ([Computerwoche](https://www.computerwoche.de/a/the-birth-of-the-ipod,2498421,11)). For the 5G, sources say "chrome" without confirming stainless steel.

The construction explains how the face should read. **The screen sits under the same continuous clear layer as the white**, with no separate lens. One owner describes a whole clear shell over the white and the screen, and owners report the screen area scratches easily ([MacRumors](https://forums.macrumors.com/threads/ipod-video-scratches.157162/page-6)). iFixit's teardown shows the faceplate clipping onto an internal metal frame, with the Click Wheel beneath it and the center button as a separate part snapping in through the wheel ([iFixit](https://www.ifixit.com/Guide/iPod+5th+Generation+(Video)+Front+Faceplate+Replacement/159192)). For rendering, this suggests [Estimate] one specular highlight that passes unbroken across white and screen alike, a faint second edge just inside the outline where the white layer begins under the clear, and at most a 1–2 px chrome sliver outside the face from the 0.39 mm step. The window needs no bezel line. When the display is off, it reads as deep glossy near-black.

**The Click Wheel is a capacitive ring with four mechanical press points**, labelled MENU (12 o'clock), previous (9), next (3) and play/pause (6), plus a separate mechanical center button and a piezo clicker ([The Apple Wiki](https://theapplewiki.com/wiki/IPod_with_video)). Apple marketed it as "precise, one-handed navigation" ([Apple Newsroom](https://www.apple.com/newsroom/2005/10/12Apple-Unveils-the-New-iPod/)). Under the ring, a membrane senses capacitance changes, and four switches sit beneath it ([Wikipedia: iPod click wheel](https://en.wikipedia.org/wiki/IPod_click_wheel)). Reviewers noted the wheel shrank from the 4G's ([InsanelyMac](https://www.insanelymac.com/forum/topic/5500-review-5g-ipod-with-video/)). Label typeface, glyph size and print method are unsourced. Myriad-like small caps for MENU and grey double-triangle glyphs are the working assumption [Estimate]. Earlier notes placed the labels 14–15 mm from centre. Apple's geometry puts the ring midline at about 12.95 mm, so **centre the labels near r ≈ 13 mm** and verify against a photo.

No published hex, RGB or Pantone value exists for any surface. The table below gives starting values to sample against high-quality photos, and all of them are [Estimate].

| Part (white model) | Finish | Starting value |
|---|---|---|
| Front face | Glossy, faintly cool white, never pure white | #F4F4F2 – #FAFAF8, highlight to #FFFFFF |
| Click Wheel | Matte or satin, slightly greyer than the face | #ECECEA – #F0F0EE |
| Wheel labels | Mid grey | #A8A8AC – #B4B4B8 |
| Center button | Glossy, matches face, slightly domed | ≈ #F6F6F4 |
| Window mask (off) | Near-black, faint blue-grey cast | #101214 – #1A1C1F |

The 5.5G ("Late 2006", released 12 September 2006) is externally identical, so one render serves both ([Macworld](https://www.macworld.com/article/181678/5gipodlate2006.html)). Its screen is 60 percent brighter with richer colours, which affects only the displayed UI.

## Podium Sans on 320 × 240 is documented; the screen's pixel geometry is not

**The 5G UI font is Podium Sans, a bitmap modification of Myriad.** It was used on the iPod photo, iPod with video and the first two iPod nanos. It is a bitmap face because iPod Software does not support TrueType ([The Apple Wiki: Podium Sans](https://theapplewiki.com/wiki/Podium_Sans)). It drops Myriad's distinctive 'k', 'y' and splayed 'M', and the iPod classic replaced it with Helvetica Bold in September 2007 ([Wikipedia: Podium Sans](https://en.wikipedia.org/wiki/Podium_Sans)). A firmware dump made with iPodWizard [Firmware] shows **Podium Sans embedded at sizes 14, 16, 18, 22 and 28** ([TechCrunch](https://techcrunch.com/2007/05/15/spice-up-that-ipod-with-new-font-colors/)). The same dump shows four separately styled text roles:

| Resource | Role | Documented detail [Firmware] |
|---|---|---|
| 24222 | Menu text | Default **#000000** (ARGB 0xFF000000), left-justified, a 1-bit (non-anti-aliased) font |
| 24223 | Title bar | Also renders "Song # of #" on Now Playing and the "Do not disconnect" text |
| 24224 | Title bar text **shadow** | Confirms title text has a drop shadow |
| 24225 | Secondary text | Right-justified values such as On/Off |
| −344 | Alphabetical index | The fast-scroll letter overlay |

Justification codes are 0x1 left, 0x101 centre and 0x201 right ([TechCrunch](https://techcrunch.com/2007/05/15/spice-up-that-ipod-with-new-font-colors/)). Whether 14–28 are pixel heights or point sizes is unknown. A practical stand-in is Myriad Semibold or Bold, pixel-snapped with smoothing off and scaled nearest-neighbour. Real fidelity needs the actual glyph strikes, which iPodWizard can export. An unofficial "Podium Sans" TTF circulates online with unknown provenance and licence, and ClickWheel should not ship it.

**The title bar** documentedly carries a centred screen title, a play or pause glyph, and a battery icon that animates while charging ([Apple Features Guide via notice-facile](https://www.notice-facile.com/en/manual/1885013/apple+ipod-features)). Rockbox's "iVideo" theme, the best-known recreation of the original firmware, keeps shuffle and repeat icons right-justified "like in the OF" and ships battery, hold, disk-access, shuffle and repeat bitmaps ([themes.rockbox.org iVideo](http://themes.rockbox.org/index.php?themeid=1309&target=ipodvideo)). The rest is recollection [Estimate]: a light grey vertical gradient about 20–22 px tall with a 1 px darker bottom rule, black bold-looking title, a blue play glyph at left, a green-filled battery outline at right, and a padlock at left when Hold is on.

**Menus** are full-width lists. Split-screen menus with artwork belong to the 2007 iPod classic, and appear on a 5G only through modified firmware ([The Apple Wiki: iPod classic](https://theapplewiki.com/wiki/IPod_classic); [iPod Classic Users group](https://www.facebook.com/groups/ipodclassicusers/posts/4626839054252916/)). The documented facts are black left-justified text, right-justified secondary values and a letter overlay on fast scroll. Everything else is [Estimate]: a white background, a full-width blue vertical-gradient selection bar with white text, a right chevron on submenu rows, a thin scrollbar only on overflow, ellipsis truncation with a marquee on the selected row, and 8 or 9 visible rows. With a ~20 px title bar, 8 rows give about 27 px each and 9 rows about 24 px. One look at a real screen decides between them.

**Now Playing** documentedly shows the song number ("x of y"), shuffle and repeat icons, album art, title, artist and album, and a progress bar with elapsed and remaining time ([iPod Features Guide, March 2006](https://archive.org/download/manualsonline-id-3b62a5c2-05f8-400e-aa0a-205d4a887438/3b62a5c2-05f8-400e-aa0a-205d4a887438.pdf)). Pressing Center switches to a scrubber that **"displays a diamond"** for the playhead. Further presses cycle through album art, a rating screen of bullets or stars, lyrics and podcast information. The volume bar marks a set limit with a triangle and shows a lock icon at the limit ([Apple Features Guide via notice-facile](https://www.notice-facile.com/en/manual/1885013/apple+ipod-features)). iVideo ships album-art frame pieces (left, right, bottom) and shaded progress and volume bars, which suggests enthusiasts saw a shadow or reflection under the art and a bevelled bar ([iVideo](http://themes.rockbox.org/index.php?themeid=1309&target=ipodvideo)). Layout positions are [Estimate]: art about 100–120 px square at left, three stacked text lines to its right, a thin glossy blue progress bar near the bottom with elapsed time at left and "−" remaining at right.

**Colour and motion** are the largest gaps. Only menu text black is sourced. The 5G panel is 16-bit RGB565, so any sampled value should be snapped to that grid: red and blue in steps of about 8.2, green in steps of about 4.0 ([Rockpod](https://github.com/nuxcodes/rockpod)). No source gives the menu transition. The common memory is a horizontal push, new list in from the right on enter and reversed on Menu, at about 200–300 ms [Estimate]. That needs frame-by-frame measurement from 60 fps video.

## A 96-position wheel, a quartic accelerator and a 1 kHz tick

**The wheel reports absolute position: 96 positions per revolution, 3.75° each, increasing clockwise.** Rockbox reads a 32-bit register (0x7000c140). A valid packet satisfies `(status & 0x800000ff) == 0x8000001a`. Position is `(status >> 16) & 0x7f`, bit 0x40000000 means touched, and button bits are 0x100 Center, 0x200 next, 0x400 previous, 0x800 play/pause and 0x1000 MENU ([Rockbox button-clickwheel.c](https://raw.githubusercontent.com/Rockbox/rockbox/master/firmware/target/arm/ipod/button-clickwheel.c)). Deltas wrap by the shortest path: a delta below −48 has 96 added, and one above +48 has 96 subtracted. **Rockbox emits one step per 4 positions (15°), or 24 items per slow revolution.** Smaller movements are ignored as jitter. A lift shorter than **150 ms** counts as the same gesture. The constants WHEELCLICKS_PER_ROTATION 96, WHEEL_SENSITIVITY 4 and WHEEL_UNTOUCH_TIMEOUT 150000 µs are all in the same file. The nano's smaller wheel uses 6 positions per step. Apple's own threshold is undocumented. Owners' sense of 20–30 items per turn fits 15° but is unmeasured.

**Acceleration in Rockbox is velocity-driven and steep** [Rockbox]. The iPod Video config sets WHEEL_ACCEL_START to **270°/s** and WHEEL_ACCELERATION to 3, a fourth-power curve ([Rockbox ipodvideo.h](https://raw.githubusercontent.com/Rockbox/rockbox/master/firmware/export/config/ipodvideo.h)). The driver converts each step to degrees per second and smooths it as `v = (15·v + v_new) / 16`. **A direction reversal, or a 250 ms pause, resets** both velocity and the step accumulator ([button-clickwheel.c](https://raw.githubusercontent.com/Rockbox/rockbox/master/firmware/target/arm/ipod/button-clickwheel.c)). Working through the fixed-point code in `button_apply_acceleration()` gives the multiplier **round((ω / 270)⁴)**, applied when it is at least 2 ([Rockbox button.c](https://raw.githubusercontent.com/Rockbox/rockbox/master/firmware/drivers/button.c)).

| Wheel speed ω | Revolutions/s | Items per 15° step [Estimate, from Rockbox math] |
|---|---|---|
| < ~299°/s | < 0.83 | 1 |
| 300°/s | 0.83 | 2 |
| 405°/s | 1.13 | 5 |
| 540°/s | 1.5 | 16 |
| 810°/s | 2.25 | 81 |

Apple's firmware feels gentler than this. Firmware 1.2 (September 2006) also changed scrolling on original 5Gs: one owner found long-list scrolling "slowed down considerably", with the click falling out of step with the list ([penmachine](https://www.penmachine.com/2006/10/ipod-5g-interface-slows-down-after.html)). A sensible design choice for ClickWheel [Estimate] is to keep Rockbox's structure (EMA velocity, 250 ms and reversal resets) with a softer curve, such as squared from 270–360°/s. Rockbox itself used a squared curve from 360°/s on the iPod 3G ([Rockbox commit](https://git.lenord.me/len0rd/rockbox/commit/d10bf7ab46e5b6e043507f7eee01b7dd42b87c7a)). Also keep the sub-step remainder rather than discarding it, quantise finger angle to 96 sectors, and ignore touches inside the center-button radius.

**Buttons separate tap from hold everywhere**, per Apple's Late 2006 Features Guide [Apple] ([Features Guide](https://gerritspeek.nl/apparaten/misc/manual-ipod-classic-5g.pdf)):

| Input | Tap | Hold |
|---|---|---|
| MENU | Back one level | Jump to main menu |
| Play/Pause | Play or pause; on a list title, play the whole list | Turn off |
| Next | Next song, video or chapter | Fast-forward |
| Previous | Restart track; twice for previous track | Rewind |
| Center | Choose item; on Now Playing, cycle scrubber → art → rating → … | Add song to On-The-Go (until the title flashes) |
| Wheel | Scroll; on Now Playing, volume; in scrubber, seek | — |
| MENU + Center | — | ≈ 6 s resets (after toggling Hold) |
| Any button / wheel | Wakes the device and backlight | — |
| Hold switch | Disables controls; an orange bar shows | — |

Hold thresholds are undocumented. Fire tap actions on release only when no hold fired, as Rockbox's release-versus-repeat model does ([keymap-ipod.c](https://raw.githubusercontent.com/Rockbox/rockbox/master/apps/keymaps/keymap-ipod.c)). Working values are about 1 s for MENU-hold and 2–3 s for power-off [Estimate]. Unpublished timings also include the scrubber's return to normal view, seek resolution per wheel step, scan ramp, the volume step count and the volume overlay timeout. Placeholders are 2–3 s overlays and 32–40 volume steps with no acceleration [Estimate].

**The click is a piezo inside the iPod, not the headphones**, and fires once per list step ([Wikipedia: iPodLinux](https://en.wikipedia.org/wiki/IPodLinux)). On the 5G the setting is simply Clicker On/Off ([Features Guide](https://gerritspeek.nl/apparaten/misc/manual-ipod-classic-5g.pdf)). Rockbox drives the piezo with PWM: the click is period 91 for 4000 µs, and its measured table gives Hz ≈ 91225 / period. That makes **≈1002 Hz for 4 ms, about four square-wave cycles**, a tick rather than a tone. The beep is period 40 (≈2.3 kHz) for 200 ms. Older Rockbox values were period 50 for 0.4 ms, about 1.85 kHz ([Rockbox piezo.c](https://raw.githubusercontent.com/Rockbox/rockbox/master/firmware/target/arm/ipod/piezo.c)). These were tuned by ear to resemble Apple's, not measured from it. ClickWheel should rate-limit the click during accelerated scrolling and stay silent when the highlight cannot move [Estimate].

**The menu tree** for the main menu is Music, Photos, Videos, Extras, Settings and Shuffle Songs, editable through Settings › Main Menu ([Features Guide](https://gerritspeek.nl/apparaten/misc/manual-ipod-classic-5g.pdf)). Music holds Playlists, Artists, Albums, Songs, Podcasts, Genres, Composers and Audiobooks. Extras holds Clock, Stopwatch, Games, Screen Lock, Contacts, Calendar, Notes and Voice Memos ([March 2006 guide](https://archive.org/download/manualsonline-id-3b62a5c2-05f8-400e-aa0a-205d4a887438/3b62a5c2-05f8-400e-aa0a-205d4a887438.pdf)). Settings covers About, Main Menu, Backlight Timer (default 10 s), Brightness, Clicker, Volume Limit, Sound Check, EQ, Shuffle, Repeat and others. A "Now Playing" row appended to the main menu while audio plays is commonly remembered but unsourced. **The firmware version defines the feature set.** Firmware 1.2 brought Quick Scroll, the large letter overlay on fast spins in sorted lists, to all 5Gs, along with gapless playback and games. It exits after about one second without movement and does not run in Podcasts ([Daring Fireball](https://daringfireball.net/2006/09/fifth_generation_ipod_features); [penmachine](https://www.penmachine.com/2006/10/ipod-5g-interface-slows-down-after.html)). Search in the Music menu and the Brightness setting are 5.5G-only. A ClickWheel aiming at "the 2005 original" should therefore omit Quick Scroll and Search. One aiming at "late 5G" includes Quick Scroll, and a 5.5G mode adds both.

## Conclusion

The research inverts a natural assumption. The part of the iPod people remember most vividly, the screen, is the least documented, while the hardware and the wheel are almost fully specified. That ordering should shape how ClickWheel is built. The body and wheel geometry can be frozen now, as can the input pipeline: 96 sectors, 4-sector steps, 150 ms lift tolerance, 250 ms and reversal resets, and a 1 kHz, 4 ms tick. Each comes straight from Apple's drawing or from hardware constants. The screen should be built as a parameterised theme, with every row height, gradient stop and duration held as a token, so that measured values can replace estimates without restructuring.

Two choices are product decisions rather than research gaps. One is the render scale: life size or the v0.2 scale both resample a 320 × 240 bitmap UI, while about 6.41 pt/mm renders it pixel-exact at the cost of a larger window. The other is the firmware era to emulate (1.1, 1.2 or 5.5G), since it decides whether Quick Scroll, Search and Brightness exist. Acceleration is a third choice in disguise. Rockbox's quartic curve is documented, but Apple's feel is gentler and unpublished, so ClickWheel will be tuned by hand against a real device whatever happens.

## Remaining unknowns and how to measure them

| Unknown | Best measurement route |
|---|---|
| Menu row height, visible rows, title bar height, insets, chevron and scrollbar art | Open 5G firmware 1.2.x in iPodWizard (Layout and Images tabs); otherwise measure a lossless 320 × 240 framebuffer capture |
| All UI colours: header gradient, selection blue, battery green, progress fill | Same capture, snapped to RGB565; or iPodWizard image export |
| Podium Sans glyph strikes, pixel heights, title weight and shadow offset | iPodWizard font export from the firmware file |
| Menu slide duration and easing; whether the title animates | Frame-by-frame analysis of 60 fps video of a real 5G |
| Apple's wheel threshold and acceleration curve | Film the screen and the wheel together at known rotation speeds and count items per turn |
| Hold durations (MENU, power, On-The-Go), scrubber and volume timeouts, volume step count | Stopwatch timing on hardware; count volume steps from silence to maximum |
| Click frequency, duration and throttling | Contact-mic recording of the piezo, analysed with a spectrogram |
| Surface colours, label typeface, label radius, button dome and wheel recess | Colour-calibrated macro photos of a white 5G beside a reference card; calipers and a depth gauge for recess |
| Interim concrete values for screen layout | Download Rockbox's iVideo theme (needs user approval) and read the pixel viewports and colours in its .sbs, .wps and .cfg files. These are a recreation, not Apple's values |
