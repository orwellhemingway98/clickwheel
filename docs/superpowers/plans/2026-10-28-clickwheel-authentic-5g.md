# ClickWheel Authentic 5G Design Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make ClickWheel's screen, physical rendering and wheel/button behaviour match the white iPod 5th generation.

**Architecture:** Behaviour is built from pure, clock-injected units (`WheelGestureTracker` sectors, `ScrollAccelerator`, `ButtonGestureRecognizer`, `ClickRateLimiter`, `Marquee`, Now Playing mode state in `Navigator`), driven by a 10 Hz `tick(now:)`. All screen styling lives in one `ScreenTheme` token set laid out in 240 × 180 design points. Views only render state.

**Tech Stack:** Swift 5 mode, SwiftUI/AppKit, AVFoundation, AppleScript, XCTest. Tests: `./scripts/test.sh`.

**Spec:** `docs/superpowers/specs/2026-10-28-clickwheel-authentic-5g-design.md` (values: `docs/reference/ipod-5g-screen-values.md`, `docs/reference/ipod-5g-dimensions.md`)

## Global Constraints

- Life-size `IPodGeometry` stays; the LCD content is designed at 240 × 180 pt (`IPodGeometry.lcdDesignSize`).
- Every LCD colour, size and duration comes from `ScreenTheme`. No literals in views except layout arithmetic.
- Clock injection: every time-dependent unit takes `now: TimeInterval` (seconds) as a parameter. No `Date()` inside logic.
- Timings (exact): hold 0.8 s; lift continuation 0.15 s; acceleration reset 0.25 s; volume overlay 2.0 s; scrubber idle 3.0 s; Quick Scroll fade 1.0 s; marquee pause 1.0 s, speed 30 pt/s; transition 0.25 s ease-out; click 1 kHz, 4 ms, minimum 0.025 s apart; FF/RW 5 s every 0.25 s; restart threshold 3 s; scrub 2 s per step.
- Copy (exact): `Music`, `Extras`, `Settings`, `Shuffle Songs`, `Now Playing`, `Clock`, `Stopwatch`.
- No Apple assets; Source Sans 3 stays. Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Overlapping gestures:** a held ⏭ while the wheel turns, or a tap during a hold-in-progress, must not fire both tap and hold, or leave fast-forward stuck on (tests in Tasks 3 and 9).
2. **The tick stops when the app loses focus:** the volume overlay or Quick Scroll letter must not stay on screen forever if `tick(now:)` pauses and resumes much later (test in Task 5).
3. **Acceleration overshoot at list ends:** ×8 jumps clamp at the first and last rows. The click doesn't fire when the selection can't move (test in Task 5).
4. **Track changes while scrubbing:** the track ends or changes during scrub mode; the scrubber must not seek the new track to a stale position (test in Task 5).
5. **Now Playing row appears or disappears while the root menu is open:** the selection must stay on the same item and never point past the end (test in Task 5).

---

### Task 1: 96-sector wheel and lift continuation

**Files:** Modify `ClickWheel/Core/WheelGestureTracker.swift`; Test `ClickWheelTests/WheelGestureTrackerTests.swift`

**Interfaces:**
- Produces: `WheelGestureTracker(sectors: Int = 96, sectorsPerStep: Int = 4, deadZoneRadius: Double = 12, liftTolerance: TimeInterval = 0.15)`; `begin(at:now:)`, `move(to:now:) -> Int`, `end(now:)`. `degreesPerStep` is removed (15° = 4 × 3.75°).

- [ ] **Step 1: Update and add tests.** The existing tests pass `now:` values. New tests:
  - `testQuantisedToSectors`: begin p(0); `move(p(3))` → 0; `move(p(15.1))` → 1 (four sectors crossed).
  - `testLiftWithin150msContinues`: begin p(0), move p(10), `end(now: 1.0)`, `begin(at: p(10), now: 1.1)`, `move(p(16))` → 1 (carry kept).
  - `testLiftAfter150msResets`: same with begin at `now: 1.3` → 0.
- [ ] **Step 2: Run tests.** Expected: compile failure.
- [ ] **Step 3: Implement.** Sector index = `floor(angle / 3.75)`. Deltas are counted in sectors with ±48 wrap, then accumulated. Steps = `carry / 4`, truncating toward zero. `end` records the time; `begin` within `liftTolerance` keeps the carry.
- [ ] **Step 4: Run tests.** Expected: pass. **Step 5:** commit `feat: 96-sector wheel with lift continuation`.

### Task 2: ScrollAccelerator

**Files:** Create `ClickWheel/Core/ScrollAccelerator.swift`; Test `ClickWheelTests/ScrollAcceleratorTests.swift`

**Interfaces:**
- Produces: `struct ScrollAccelerator { init(degreesPerStep: Double = 15, startSpeed: Double = 300, cap: Int = 8, resetAfter: TimeInterval = 0.25); mutating func multiplier(forStep direction: Int, now: TimeInterval) -> Int; mutating func reset() }`
- Velocity: instantaneous speed = `degreesPerStep / dt`, smoothed `v = (3v + new) / 4`. Multiplier = `1` if `v < startSpeed`, else `min(cap, max(1, Int(((v / startSpeed)² · 2 − 1).rounded())))`. A gap over `resetAfter`, or a sign change, resets `v` to the new step's instantaneous speed.

- [ ] **Step 1: Tests** (feed steps at constant intervals for 8 steps, check the last multiplier): 200°/s → 1; 350°/s → 2; 450°/s → 4 (`(1.5²·2−1) = 3.5` → 4); 700°/s → 8 (cap). `testPauseResets`: fast steps, then one after a 0.3 s gap → 1. `testDirectionChangeResets`: fast +1 steps, then −1 → 1.
- [ ] **Steps 2–4:** red, implement, green. **Step 5:** commit `feat: gentle scroll acceleration`.

### Task 3: Button tap/hold recognizer

**Files:** Create `ClickWheel/Core/ButtonGestureRecognizer.swift`; Modify `ClickWheel/Core/WheelEvent.swift`; Test `ClickWheelTests/ButtonGestureRecognizerTests.swift`

**Interfaces:**
- `WheelEvent` gains `.menuHold`, `.seekForward(active: Bool)`, `.seekBackward(active: Bool)`, `.tick(now: TimeInterval)`; `.previous` keeps meaning a ⏮ tap.
- `enum WheelButton { case menu, previous, next, playPause, center }`
- `struct ButtonGestureRecognizer { init(holdThreshold: TimeInterval = 0.8); mutating func press(_:now:) -> [WheelEvent]; mutating func release(_:now:) -> [WheelEvent]; mutating func poll(now:) -> [WheelEvent] }`
- Mapping:
  - Tap on release: `.menu`, `.previous`, `.next`, `.playPause`, `.center`.
  - Hold (when `poll` passes the threshold while pressed): menu → `.menuHold`; next → `.seekForward(active: true)`; previous → `.seekBackward(active: true)`; playPause and center have no hold, so they still tap on release.
  - Release after a seek hold → `.seekForward/Backward(active: false)` and no tap. Release after `.menuHold` → nothing.
  - Pressing a second button releases the first as a cancel: it emits seek `active: false` if one was active, and no tap.

- [ ] **Step 1: Tests:** quick tap on each button → its tap event; menu held 0.9 s (polled) → `.menuHold`, then release → `[]`; next held → `seekForward(true)` then release → `seekForward(false)`; playPause held 2 s then released → `.playPause`; poll before the threshold → `[]`; second press cancels the first (no tap, seek stops).
- [ ] **Steps 2–4:** red, implement, green. **Step 5:** commit `feat: tap and hold recognition for wheel buttons`.

### Task 4: Seeking commands

**Files:** Modify `ClickWheel/Player/MusicSource.swift`, `PlayerHub.swift`, `AppleMusicSource.swift`, `SpotifySource.swift`; Test `ClickWheelTests/PlayerHubTests.swift`, `Mocks/MockMusicSource.swift`, `Mocks/SpyPlayerControls.swift`

**Interfaces:**
- `MusicSource` adds `func setPosition(_ seconds: Double) throws`. AppleScript: `set player position to <n>` (both apps).
- `PlayerControlling` adds `func seek(by seconds: Double)`, `func setPosition(_ seconds: Double)`, `func restartOrPrevious()`. In `PlayerHub`: seek clamps to `0…duration`; `restartOrPrevious` → `setPosition(0)` if `snapshot.track.position > 3`, else `previous()`.

- [ ] **Step 1: Tests:** `testSeekClampsToTrack` (position 10, duration 200: seek −30 → `setPosition(0.0)`, seek +500 → `setPosition(200.0)`); `testRestartOrPreviousAt5sRestarts` → `setPosition(0.0)`; `testRestartOrPreviousAt2sGoesBack` → `previous`; seeking with no track does nothing.
- [ ] **Steps 2–4:** red, implement (osacompile the two new script lines), green. **Step 5:** commit `feat: seek and smart previous`.

### Task 5: Navigator behaviour (modes, menus, acceleration, overlays)

**Files:** Modify `ClickWheel/Core/Navigator.swift`, `MenuModel.swift`, `ClickWheel/Library/LibraryMenus.swift`, `ClickWheel/Library/AppleMusicLibrary.swift`; Create `ClickWheel/Core/Stopwatch.swift`; Test `ClickWheelTests/NavigatorTests.swift`, `NavigatorLoadingTests.swift`, `NavigatorModesTests.swift`

**Interfaces:**
- `Screen` adds `.clock` and `.stopwatch`. `MenuScreen` adds `quickScroll: Bool = false`. `MenuWindow.visibleRows` becomes **9**.
- `Navigator.init(..., shuffle: (() async throws -> Void)? = nil, ...)`; `onScrollStep` becomes `onRowsMoved: (Int) -> Void`.
- Published state: `nowPlayingMode: NowPlayingMode` (`.normal`, `.volume(until: TimeInterval)`, `.scrubbing(position: Double, until: TimeInterval)`); `quickScrollLetter: String?`; `lastNavigation: NavigationDirection` (`.forward` / `.back`, for transitions); `stopwatch: Stopwatch`.
- `func setTrack(_ track: NowPlayingInfo?)`: the root gains or loses its last `Now Playing` row (the selection stays on the same item, clamped). Scrub mode exits if the track ID changes.
- `handle(.tick(now:))`: expires the volume overlay, scrubbing, and Quick Scroll (`now − lastQuickScroll ≥ 1.0`); repeats seeks every 0.25 s while a seek hold is active (`seek(by: ±5)`).
- Root: `Music` (if a music menu exists), `Extras`, `Settings`, `Shuffle Songs` (if `shuffle` exists; plays then pushes Now Playing), plus `Now Playing` when a track is set.
- Extras: `Clock` → `.clock`; `Stopwatch` → `.stopwatch`. On `.stopwatch`: center starts or stops; playPause resets.
- Scroll in menus: `steps × accelerator.multiplier`; `onRowsMoved(moved)` only when the selection moved. When the multiplier is ≥ 2 and the screen has `quickScroll`, set `quickScrollLetter` = `Navigator.indexLetter(for: label)` (first character uppercased if A–Z after removing diacritics, else `#`).
- Now Playing: scroll in `.normal` or `.volume` → volume (no acceleration), mode `.volume(until: now + 2)`. Center toggles `.scrubbing(position: current, until: now + 3)`. Scroll while scrubbing moves the position by `2 s × steps × multiplier`, calls `setPosition`, and extends `until`. MENU while scrubbing returns to `.normal` and doesn't pop.
- `.menuHold` pops to root. `.previous` calls `restartOrPrevious()`. `.seekForward/Backward(active:)` start and stop the repeating seek.
- `LibraryMenus.shuffleAction(library:runner:) -> () async throws -> Void`: shuffled `allTracks`, first 100 IDs → `.queue(trackIDs:, startIndex: 0)`. Songs, Artists and Albums screens set `quickScroll: true`.
- `struct Stopwatch { mutating func toggle(now:); mutating func reset(); func elapsed(now:) -> TimeInterval; var isRunning: Bool }` and `TimeFormat.stopwatch(_:) -> String` (`"mm:ss.t"`).

- [ ] **Step 1: Tests** (update the existing root-menu expectations to the new root; navigator clock values passed through `.tick`):
  - root labels with and without a track; `setTrack(nil)` while "Now Playing" is selected → the selection clamps onto "Shuffle Songs"
  - `.menuHold` from three levels deep → root
  - fast scroll in a 50-row `quickScroll` list moves more than 1 per step and sets the letter; the letter clears after a tick 1.0 s later; a tick 10 s later also clears it (focus-loss case)
  - fast scroll at the end of a list clamps, and `onRowsMoved` gets the actual moved count, 0 at the end with no call
  - Now Playing: scroll → spy `adjustVolume(3)`, mode `.volume`, which expires after a tick 2.1 s later; center → scrubbing; scroll +1 → spy `setPosition(current + 2)`; a tick after 3.1 s → `.normal`; `setTrack` with a new ID exits scrubbing
  - `.seekForward(active: true)` then ticks at +0.25 and +0.5 → two `seek(by: 5)` calls; `active: false` stops them
  - `.previous` → spy `restartOrPrevious`
  - Stopwatch: toggle at 0, `elapsed(now: 1.25)` → 1.25, `stopwatch(61.25)` → `"01:01.2"`
  - `indexLetter`: "Ólafur" → "O", "50 Cent" → "#", "the Beatles" → "T"
  - `shuffleAction` with a fake library of 150 tracks → one `.queue` request with 100 IDs, all from the library
- [ ] **Steps 2–4:** red, implement, green. **Step 5:** commit `feat: authentic 5G navigation, modes and menus`.

### Task 6: Clicker

**Files:** Modify `ClickWheel/UI/ClickSound.swift`; Create `ClickWheel/Core/ClickRateLimiter.swift`; Test `ClickWheelTests/ClickRateLimiterTests.swift`

**Interfaces:** `struct ClickRateLimiter { init(minimumInterval: TimeInterval = 0.025); mutating func shouldClick(now:) -> Bool }`. `ClickSound` generates a 1 kHz, 4 ms burst (square wave softened by a 0.5 ms attack and release). `AppModel` wires `onRowsMoved` → limiter → play.

- [ ] Tests: clicks at 0, 0.01, 0.03 → true, false, true. Red, implement, green. Commit `feat: 1 kHz clicker with rate limit`.

### Task 7: Screen theme, header and menus

**Files:** Create `ClickWheel/UI/ScreenTheme.swift`, `ClickWheel/UI/Marquee.swift`; Modify `ScreenView.swift`, `MenuListView.swift`, `Theme.swift` (remove the LCD tokens it no longer owns); Test `ClickWheelTests/MarqueeTests.swift`

**Interfaces:**
- `ScreenTheme`: every value in spec §2, by name (`headerHeight 18`, `headerStops`, `ruleColor`, `rowHeight 18`, `selectionStops`, `textSize 13.5`, `detailColor`, `inset 6`, progress and volume frames and stops, durations).
- `enum Marquee { static func offset(elapsed: TimeInterval, overflow: CGFloat, pause: TimeInterval = 1, speed: CGFloat = 30) -> CGFloat }`: 0 during the pause, then grows at `speed` up to `overflow`, holds for `pause`, then the cycle restarts. 0 when `overflow ≤ 0`.
- `ScreenView`: header per spec (title shadow, blue play/pause glyph, battery); content switch adds `.clock`, `.stopwatch` and a Quick Scroll overlay; push transitions keyed by screen depth, using `lastNavigation`.
- `MenuListView`: 9 rows, selection gradient, detail text, `›`, tail truncation, marquee on the selected row (driven by `TimelineView(.animation)`).

- [ ] Marquee tests: `offset(0.5, 40)` = 0; `offset(1.5, 40)` = 15; `offset(2.5, 40)` = 40 (clamped); `offset(3.4, 40)` = 40 (end hold); `offset(3.6, 40)` = 0 (restart); overflow 0 → 0. Red, implement, green.
- [ ] Snapshot the root menu and Settings (`--snapshot`); check: 9 rows, gradients, title shadow. Commit `feat: 5G colour menus and header`.

### Task 8: Now Playing, scrubber, volume, Clock, Stopwatch, Quick Scroll views

**Files:** Modify `NowPlayingView.swift`; Create `ClickWheel/UI/GlossBar.swift`, `ClockView.swift`, `StopwatchView.swift`, `QuickScrollOverlay.swift`

**Interfaces:** `GlossBar(fraction:style:)`, where style is `.progress`, `.volume` or `.scrub(diamondAt:)`. It draws the spec's glossy stops, track and shadow line. `NowPlayingView` switches the bar on `navigator.nowPlayingMode`.

- [ ] Build. Snapshot with `--now-playing` and with `--keys` for scrub (center) and volume (d). Check the layout against spec §2's table: positions within 1 pt. Commit `feat: 5G Now Playing, scrubber, volume and extras screens`.

### Task 9: Physical rendering and input wiring

**Files:** Modify `ClickWheel/UI/IPodGeometry.swift` (rim 0.4 mm), `IPodView.swift`, `ClickWheelView.swift`, `Theme.swift`, `ClickWheel/App/AppDelegate.swift`, `AppModel.swift`; Test `ClickWheelTests/KeyMapTests.swift`

**Interfaces:**
- Window: near-black gradient, no stroke. One gloss sweep over the face *and* window, drawn above both. The separate glare is removed. A 0.5 pt inner edge inset 0.6 mm. Colours per spec §3.
- `ClickWheelView` sends `press` and `release` of the quadrant or center to a `ButtonGestureRecognizer` held by `AppModel`. Ring drags use the tracker with `now`. A 10 Hz timer in `AppModel` calls `recognizer.poll(now:)` and `navigator.handle(.tick(now:))`.
- `KeyMap`: `keyDown(code:isRepeat:)` and `keyUp(code:)` map to recognizer presses and releases (← previous, → next, Return center, Esc menu, Space playPause); ↑ and ↓ stay scroll ±1 per key repeat.

- [ ] KeyMap tests: ← down → `press(.previous)`; ← up → `release(.previous)`; a repeat keyDown for a button → no new press; ↑ → `.scroll(-1)`. Red, implement, green.
- [ ] Snapshot: no border around the window; one gloss across the window; rim visibly thinner. Commit `feat: 5G physical finish and tap/hold input`.

### Task 10: Verification and README

- [ ] Full test suite, then snapshot set: root, Settings, Songs (with Quick Scroll forced), Now Playing, scrubber, volume, Clock, Stopwatch. Put them side by side.
- [ ] Manual checklist for the user: the acceleration feel, holds (MENU, ⏭, ⏮), smart ⏮, scrubber, volume overlay, click sound, slide transitions, Shuffle Songs, Clock and Stopwatch.
- [ ] README: features list update; credit for the iVideo values (CC-BY-SA). Commit `docs: authentic 5G README`.
