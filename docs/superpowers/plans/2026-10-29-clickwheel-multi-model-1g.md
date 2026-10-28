# ClickWheel Multi-Model System + iPod 1st Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a model system (Settings › Model) and the original 2001 iPod as its first new model, while the 5G stays pixel-identical.

**Architecture:** Each model is pure data (`ModelSpec`: body, display, controls and firmware, in millimetres). `IPodGeometry` computes points for the selected model; gray-LCD models use a pixel-crisp scale. The navigator reads a `FirmwareProfile` for menus, the MENU-hold action and the backlight. Rendering dispatches on display kind (color or gray) and control kind (click wheel or scroll wheel).

**Tech Stack:** Swift 5 mode, SwiftUI/AppKit, XCTest. Tests: `./scripts/test.sh`.

**Spec:** `docs/superpowers/specs/2026-10-29-clickwheel-multi-model-1g-design.md` (values: `docs/reference/ipod-1g-front-values.md`, `reports/iPod 1G design study.md`)

## Global Constraints

- The 5G must stay **pixel-identical**: every existing `IPodGeometryTests` assertion keeps passing unchanged, and a 5G snapshot matches v0.3.0.
- 1G millimetre values exactly as spec §3.1. LCD pitch 0.248 mm, 160 × 128 px.
- Pixel-crisp: `pixelPoints = max(0.75, round(0.248 · d · 4) / 4)`, `pointsPerMM = pixelPoints / 0.248` (gray models only).
- 1G wheel: 6 of 96 sectors per step (16 per turn); no Quick Scroll; hold MENU toggles the backlight; Backlight Timer default 10 s with options Off/2/5/10/20/Always.
- ChicagoFLF ships with its public-domain note in `Resources/Fonts/` (`ChicagoFLF.ttf` plus `ChicagoFLF-README.txt` stating the author's public-domain declaration).
- Copy (exact): `Playlists`, `Browse`, `Extras`, `Settings`, `Backlight`, `Model`, `Backlight Timer`, `1st gen`, `5th gen`.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Switching models mid-use:** while a song plays, on Now Playing or deep in a menu, switching must land on the new model's root without a stale screen, stuck overlay or wrong window size (test in Task 2; manual in Task 6).
2. **Ring button vs wheel:** pressing exactly on the boundary between the wheel and the ring, or starting on the ring then spinning, must not fire a button tap (test in Task 3).
3. **Backlight with the timer Off or Always:** "Off" never auto-lights but the toggles work; "Always" never times out; changing the setting while lit applies immediately (test in Task 2).
4. **Odd displays for pixel-crisp:** a low-density external display (≈ 3.6 pt/mm) must give a valid 0.75 pt pixel and a window that fits, never zero or NaN (test in Task 1).
5. **5G regression:** hold MENU on the 5G still goes home; Quick Scroll and colour screens are unchanged (tests in Task 2; snapshot in Task 6).

---

### Task 1: Model specs and generalized geometry

**Files:** Create `ClickWheel/Models/IPodModel.swift` (`IPodModel`, `ModelSpec`, `BodySpec`, `DisplaySpec`, `ControlSpec`, `FirmwareProfile`, `LCDPalette`); Modify `ClickWheel/UI/IPodGeometry.swift`; Test `ClickWheelTests/IPodModelTests.swift`, `ClickWheelTests/IPodGeometryTests.swift` (additions only)

**Interfaces:**
- `enum IPodModel: String, CaseIterable { case firstGen, fifthGen }` with `var spec: ModelSpec`, `var shortName: String` ("1st gen" / "5th gen").
- `DisplaySpec.kind: DisplayKind`, either `.color` or `.gray(LCDPalette)`. Also `pixels: CGSize` (320 × 240 or 160 × 128), `pixelPitch: CGFloat` (0.156 / 0.248), `designSize: CGSize` (5G 240 × 180; 1G 160 × 128).
- `ControlSpec`: `kind` (`.clickWheel` / `.scrollWheel`), `outerDiameter` (5G wheel 38.10; 1G ring 52.1), `wheelDiameter` (5G 38.10; 1G 41.1), `buttonDiameter` (13.7 / 20.7), `centerFromBottom` (30.44 / 32.3), `sectorsPerStep` (4 / 6).
- `FirmwareProfile`: `menuStyle` (`.fifthGen` / `.firstGenLate`), `holdMenu` (`.home` / `.toggleBacklight`), `quickScroll: Bool`, `backlight: Bool`.
- `IPodGeometry.init(model: IPodModel = .fifthGen, pointsPerMM:)`; `static func lifeSize(model: IPodModel = .fifthGen, screenWidthPoints:physicalWidthMM:)` (applies pixel-crisp for gray models). New: `model`, `ringDiameter`, `lcdPixel` (points per LCD pixel), `controlCenterY`. Existing names (`wheelCenterY`, `wheelDiameter`, `lcdDesignSize` as an instance `designSize`, `lcdScale`) keep their 5G results. The static `IPodGeometry.lcdDesignSize` stays for the 5G views.

- [ ] **Step 1: Tests**
  - `testFifthGenSpecMatchesCurrentConstants`: body 61.80 × 103.50, corner 6.8, window 52.42 × 39.94, wheel 38.10, button 13.7, centre 30.44, 4 sectors per step.
  - `testFirstGenSpec`: the spec §3.1 values; `pixels == 160×128`; `sectorsPerStep == 6`; profile `.toggleBacklight`, `quickScroll == false`.
  - `testFirstGenGeometryAtTen`: `IPodGeometry(model: .firstGen, pointsPerMM: 10)`: body 618 × 1020, ring 521, wheel 411, button 207, `controlCenterY` 1020 − 323 = 697, window 430 × 356 at top 46, LCD 396.8 × 317.4.
  - `testPixelCrispOnUsersDisplay`: `lifeSize(model: .firstGen, screenWidthPoints: 1512, physicalWidthMM: 301)` → `lcdPixel == 1.25`, `pointsPerMM ≈ 5.0403`.
  - `testPixelCrispRounding`: density 3.6 pt/mm → `lcdPixel == 1.0`; 3.2 → 0.75; 2.0 → 0.75 (the minimum; the raw value would be 0.5); 7.0 → 1.75.
  - `testFifthGenLifeSizeUnchanged`: the existing life-size expectations, through the new API with `model: .fifthGen`.
- [ ] **Steps 2–4:** red, implement, green. **Step 5:** commit `feat: iPod model specs and per-model geometry`.

### Task 2: Settings, firmware profiles, backlight and 1G menus

**Files:** Modify `ClickWheel/Core/AppSettings.swift`, `ClickWheel/Core/Navigator.swift`, `ClickWheel/Library/LibraryMenus.swift`; Create `ClickWheel/Core/Backlight.swift`; Test `ClickWheelTests/NavigatorFirstGenTests.swift`, `ClickWheelTests/BacklightTests.swift`, `ClickWheelTests/PlayerHubTests.swift` (settings persistence)

**Interfaces:**
- `AppSettings`: `@Published var model: IPodModel` (default `.fifthGen`); `@Published var backlightTimer: BacklightTimer` (`.off, .two, .five, .ten, .twenty, .always`, default `.ten`; `var seconds: TimeInterval?` is nil for off and always; `label` is "Off" / "2 s" / … / "Always").
- `struct Backlight { mutating func wake(now:timer:)`, `mutating func toggle(now:timer:)`, `mutating func tick(now:)`, `var isOn: Bool }`:
  - wake: off → no change; always → on; n → on until now + n.
  - toggle: if on → off (until cleared); if off → on (for n, or always).
  - tick turns it off once the deadline passes.
- `Navigator.init(..., profile: FirmwareProfile = IPodModel.fifthGen.spec.firmware, browse: (() -> MenuScreen)? = nil, playlists: (() -> MenuItem)? = nil, ...)`.
  - `@Published private(set) var backlight: Backlight`.
  - `func setProfile(_:)`: resets the stack to the new root, clears modes and overlays, and wakes the backlight.
  - Every non-tick event first calls `backlight.wake`. `.tick` calls `backlight.tick`.
  - `.menuHold`: `.home` → pop to root; `.toggleBacklight` → `backlight.toggle`.
  - Quick Scroll only if `profile.quickScroll`.
- Root menus:
  - `.fifthGen`: unchanged.
  - `.firstGenLate`: `Playlists` (from `playlists`), `Browse` (push `browse`), `Extras` → `Clock`, `Settings`, `Backlight` (run: toggle), plus `Now Playing` when a track is loaded.
- Settings (both): `Model` (detail `shortName`; cycles `settings.model` in `IPodModel.allCases` order), `Source`, `Clicker`. On gray-backlight profiles, add `Backlight Timer` (cycles through the options) after Source.
- `LibraryMenus.browseMenu(library:runner:) -> MenuScreen` (Artists, Albums, Songs; the same loaders as today) and `LibraryMenus.playlistsItem(library:runner:) -> MenuItem`.

- [ ] **Step 1: Tests**
  - 1G root labels, with and without a track.
  - Browse labels `["Artists", "Albums", "Songs"]`.
  - 1G Settings `["Model", "Source", "Backlight Timer", "Clicker"]`; 5G Settings `["Model", "Source", "Clicker"]`.
  - Model row cycles `.firstGen` → `.fifthGen` → `.firstGen` and persists.
  - Hold MENU on 1G toggles the backlight and stays on the screen; on 5G it goes to root.
  - The Backlight row toggles.
  - No Quick Scroll letter on 1G after a fast spin in a long `quickScroll` list.
  - `setProfile` from a deep 5G Now Playing in scrub mode → stack count 1, mode `.normal`, no letter.
  - Backlight: wake with 10 s → on, then off at a tick at +10.1 and not at +9.9; off-timer wake → stays off, but toggle turns it on; always → on after a tick at +1000; toggle while on → off.
  - Navigator: a scroll event wakes the backlight.
- [ ] **Steps 2–4:** red, implement, green. **Step 5:** commit `feat: model setting, firmware profiles, backlight and 1G menus`.

### Task 3: Scroll wheel input model

**Files:** Create `ClickWheel/Core/ScrollWheelLayout.swift`; Modify `ClickWheel/App/WheelInput.swift` (tracker built from the model's `sectorsPerStep`), `ClickWheel/UI/ClickWheelView.swift` (tracker per model); Test `ClickWheelTests/ScrollWheelLayoutTests.swift`, `ClickWheelTests/WheelGestureTrackerTests.swift` (one addition)

**Interfaces:** `enum ScrollWheelRegion: Equatable { case select, wheel, ring(WheelButton), outside }`; `ScrollWheelLayout(button: CGFloat, wheel: CGFloat, ring: CGFloat).region(at point: CGPoint) -> ScrollWheelRegion` (point relative to the centre; diameters in points; ring quadrants as in `ClickWheelView`). Boundaries: `r <= button/2` → select; `r <= wheel/2` → wheel; `r <= ring/2` → ring; else outside.

- [ ] Tests:
  - centre → select; r = 15 with button 20.7 / wheel 41.1 / ring 52.1 at 1 mm per pt → wheel
  - r = 23 at −90° → `.ring(.menu)`; at 0° → next; at 90° → playPause; at 180° → previous; r = 27 → outside
  - exact boundary r = 20.55 → wheel; r = 10.35 → select
  - tracker with `sectorsPerStep: 6`: begin p(0) → `move(p(90))` = 4
- [ ] Red, implement, green. Commit `feat: scroll wheel hit areas and 16-step wheel`.

### Task 4: Gray LCD screen

**Files:** Create `ClickWheel/UI/Gray/GrayScreenTheme.swift`, `GrayScreenView.swift`, `GrayMenuList.swift`, `GrayNowPlaying.swift`, `GrayClock.swift`, `GrayGlyphs.swift` (battery, play/pause, speaker, diamond as `Shape`s); add the `ChicagoFLF` font and its README; Modify `ClickWheel/UI/ScreenView.swift` (dispatch on `display.kind`), `project.yml` if needed.

**Interfaces:**
- `GrayScreenTheme`: every px value and palette in spec §3.2. Palette selection uses `navigator.backlight.isOn`; the colour change animates over 0.15 s.
- Views lay out in LCD pixels inside a 160 × 128 frame, scaled by `g.lcdPixel` (`scaleEffect`), with ChicagoFLF 12.
- Scroll bar shows when `items.count > 6`; the thumb height is `max(6, 108 · 6 / count)`, positioned by `windowStart`.
- `MenuWindow.visibleRows` becomes per screen kind (9 color, 6 gray). Navigator gets `visibleRows` from the profile (`FirmwareProfile.visibleRows`: 9 / 6), so `windowStart` math stays in the navigator.

- [ ] Tests: `testFirstGenNavigatorUsesSixRows` (scroll to row 7 → `windowStart == 2`); `testFifthGenStillNineRows`.
- [ ] Download ChicagoFLF from its author's distribution (ask the user first: state the file, source and size). Bundle it with the README stating the public-domain declaration.
- [ ] Snapshots, with `--model firstGen` added to the dev flag: unlit menu, lit menu (any key), Now Playing, scrubber, volume, Clock. Check against spec §3.2. Commit `feat: 1G gray LCD screen`.

### Task 5: 1G body, scroll wheel view and model switching

**Files:** Create `ClickWheel/UI/ScrollWheelView.swift`; Modify `ClickWheel/UI/IPodView.swift` (body materials per model; window per geometry; control dispatch), `ClickWheel/UI/Theme.swift` (1G face, ring, label and wheel colours), `ClickWheel/Window/DisplayGeometry.swift` (`update(for:model:)`), `ClickWheel/App/AppModel.swift` (observe `settings.model` → `display.update`, `navigator.setProfile`, rebuild input tracker), `ClickWheel/App/AppDelegate.swift` (window resizes from `display.$geometry`, as today)

**Interfaces:**
- `ScrollWheelView` uses `ScrollWheelLayout`:
  - ring presses go through `WheelInput.press/release`, and start/stop flash the segment
  - wheel drags go through `WheelInput.scroll` and rotate the texture by the accumulated angle
  - Select presses
  - a press that starts on the ring and then moves ≥ 6 pt or rotates is cancelled
- Ring segments: four 90° arcs with 0.6 mm gaps at the diagonals, labels "menu", ⏮, ⏭, ▶❚❚ at the ring's mid-radius.
- Wheel texture: fine radial lines (72 lines, 0.3 pt, `#000` at 0.06) over `#E6E6E4`, with an edge of 0.3 mm `#7E7E7E`.

- [ ] Build. Snapshots: 1G full body (unlit and lit), plus the 5G at the same settings as v0.3.0 (should match). Measure the 1G render in mm as in the life-size pass: body 61.8 × 102 (±0.1 at 5.04 pt/mm), window top 4.6, ring Ø 52.1. Commit `feat: 1G body, scroll wheel and model switching`.

### Task 6: Verification, README, review

- [ ] Full suite. The snapshot set: 1G (unlit, lit, Now Playing, scrubber, volume, Clock, Settings) and 5G (unchanged).
- [ ] Manual checklist for the user:
  - switch models while playing
  - 16-step wheel feel and the rotating texture
  - ring presses vs spins
  - hold MENU → backlight (1G), home (5G)
  - Backlight Timer options and the Backlight row
  - window resize on switch
- [ ] README: a "Models" section (1st gen, 5th gen; how to switch) and credits for ChicagoFLF and Apple's recreation as the measurement reference. Commit `docs: models README`.
