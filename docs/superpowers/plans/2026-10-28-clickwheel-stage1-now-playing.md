# ClickWheel Stage 1 (Now Playing) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A floating iPod-style Mac window that shows what Apple Music or Spotify is playing and controls it through a click wheel, with a two-item menu (Now Playing, Settings).

**Architecture:** Pure, unit-tested logic (wheel gesture math, menu navigation, source selection, parsing, formatting) sits under SwiftUI views and a borderless AppKit window. Music apps are reached through AppleScript behind a `MusicSource` protocol, so tests use a mock and stage 2/3 can extend the protocol without touching the UI.

**Tech Stack:** Swift (language mode 5), SwiftUI + AppKit, `NSAppleScript`, AVFoundation (click sound), XCTest, XcodeGen (generates the `.xcodeproj` from `project.yml`).

**Spec:** `docs/superpowers/specs/2026-10-28-clickwheel-design.md`

## Global Constraints

- macOS 14+ deployment target. Bundle ID `com.mfelouro.ClickWheel`. App name `ClickWheel`.
- App Sandbox **off**, Hardened Runtime **on**, entitlement `com.apple.security.automation.apple-events = true`.
- `NSAppleEventsUsageDescription`: "ClickWheel controls Apple Music and Spotify so it can show what's playing and play, pause or skip tracks."
- No Apple firmware, fonts, icons, sounds or logos. All artwork is drawn in SwiftUI; the click sound is synthesized; the only bundled font is Source Sans 3 (SIL OFL), shipped with its `OFL.txt`.
- Never send an Apple Event to an app that isn't running (`tell application` would launch it). Check `NSRunningApplication` first. Bundle IDs: `com.apple.Music`, `com.spotify.client`.
- Window about 280 × 460 pt, borderless, transparent, rounded body with a soft shadow.
- One wheel step per 15° of rotation; volume changes 3 points (0–100) per step.
- Polling interval 1.0 s, done off the main thread.
- `.xcodeproj` is generated and git-ignored; `project.yml` is the source of truth.
- Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Polling while an app is closed:** the user quits Spotify; ClickWheel must not relaunch it every second. Expect `snapshot()` never called on a non-running source (test in Task 3).
2. **App quits mid-song:** the screen falls back to "Nothing playing" with no crash and no stale track (test in Task 3).
3. **Odd track metadata:** titles with emoji, `|`, quotes, empty album, or a missing field (local files, podcasts, Spotify ads) must parse without dropping or shifting fields (test in Task 5).
4. **Wheel at the 0°/360° seam and near the center:** crossing the seam must not produce a ±24-step jump; jitter within the dead zone must produce no steps (test in Task 2).
5. **Streams and ads:** duration 0, or position greater than duration, must show a sane progress bar (0…1) and times, never NaN or a negative "remaining" (test in Task 6).

---

## File Structure

```
project.yml                         XcodeGen spec (app + test targets)
.gitignore
ClickWheel/
  App/ClickWheelApp.swift            @main, owns AppSettings/PlayerHub/Navigator, starts polling
  App/AppDelegate.swift              creates the FloatingWindow, installs key monitor
  App/Info.plist, ClickWheel.entitlements
  Core/WheelEvent.swift              enum WheelEvent
  Core/WheelGestureTracker.swift     angle → step math
  Core/KeyMap.swift                  key code → WheelEvent
  Core/AppSettings.swift             SourceMode, clicker, keepOnTop (UserDefaults)
  Core/Navigator.swift               menu stack + event handling
  Core/MenuModel.swift               MenuScreen, MenuItem, Screen
  Core/TimeFormat.swift              time strings + progress fraction
  Player/NowPlayingInfo.swift        NowPlayingInfo, PlayerState, PlayerSnapshot, ArtworkRef, SourceID
  Player/MusicSource.swift           protocol + MusicSourceError
  Player/PlayerHub.swift             polling, active source selection, command forwarding
  Player/AppleScriptRunner.swift     runs NSAppleScript, maps errors
  Player/ScriptOutputParser.swift    parses the delimited script output
  Player/AppleMusicSource.swift
  Player/SpotifySource.swift
  Player/ArtworkCache.swift
  UI/Theme.swift                     colors, fonts, sizes
  UI/IPodView.swift                  body: screen + wheel + drag area + context menu
  UI/ScreenView.swift                header + content switch + permission message
  UI/MenuListView.swift
  UI/NowPlayingView.swift
  UI/ClickWheelView.swift
  UI/ClickSound.swift
  Window/FloatingWindow.swift        borderless NSWindow + drag view
  Resources/Fonts/SourceSans3-*.otf, OFL.txt
ClickWheelTests/
  WheelGestureTrackerTests.swift, KeyMapTests.swift, NavigatorTests.swift,
  PlayerHubTests.swift, ScriptOutputParserTests.swift, TimeFormatTests.swift,
  ArtworkCacheTests.swift, Mocks/MockMusicSource.swift, Mocks/SpyPlayerControls.swift
README.md, LICENSE
```

Test command used throughout (referred to as **TEST**):

```bash
xcodegen generate && xcodebuild test -project ClickWheel.xcodeproj -scheme ClickWheel -destination 'platform=macOS' -quiet
```

---

### Task 1: Project scaffold

**Files:**
- Create: `project.yml`, `.gitignore`, `ClickWheel/App/ClickWheelApp.swift`, `ClickWheel/App/Info.plist`, `ClickWheel/App/ClickWheel.entitlements`, `ClickWheelTests/SmokeTests.swift`

**Interfaces:**
- Produces: buildable `ClickWheel` app scheme with a `ClickWheelTests` unit-test target (`@testable import ClickWheel`).

- [ ] **Step 1: Install XcodeGen:** `brew install xcodegen`. Expected: `xcodegen --version` prints a version.
- [ ] **Step 2: Write `project.yml`:** one macOS application target `ClickWheel` (sources `ClickWheel/`, Info.plist and entitlements from Global Constraints, `SWIFT_VERSION: 5.0`, `MACOSX_DEPLOYMENT_TARGET: 14.0`, `ENABLE_HARDENED_RUNTIME: YES`, `CODE_SIGN_IDENTITY: "-"` for ad-hoc local signing), and a unit-test bundle `ClickWheelTests` hosted by the app. Scheme `ClickWheel` runs the tests.
- [ ] **Step 3: Write `.gitignore`:** `*.xcodeproj/`, `build/`, `DerivedData/`, `.DS_Store`, `xcuserdata/`.
- [ ] **Step 4: Minimal app:** `ClickWheelApp` with a placeholder `Text("ClickWheel")` window. `SmokeTests.testTruth()` asserts `XCTAssertTrue(true)`.
- [ ] **Step 5: Run TEST.** Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 6: Commit:** `chore: scaffold ClickWheel Xcode project`.

### Task 2: Wheel gesture math and key map

**Files:**
- Create: `ClickWheel/Core/WheelEvent.swift`, `ClickWheel/Core/WheelGestureTracker.swift`, `ClickWheel/Core/KeyMap.swift`
- Test: `ClickWheelTests/WheelGestureTrackerTests.swift`, `ClickWheelTests/KeyMapTests.swift`

**Interfaces:**
- Produces:
  - `enum WheelEvent: Equatable { case scroll(steps: Int), center, menu, previous, next, playPause }` (positive steps = clockwise = down the list / volume up)
  - `struct WheelGestureTracker { init(degreesPerStep: Double = 15, deadZoneRadius: Double = 12); mutating func begin(at point: CGPoint); mutating func move(to point: CGPoint) -> Int; mutating func end() }`, where points are relative to the wheel center in SwiftUI coordinates (y down)
  - `enum KeyMap { static func event(forKeyCode code: UInt16) -> WheelEvent? }`

- [ ] **Step 1: Write failing tests** (helper `p(deg, r = 50)` builds a point at that angle with `x = r·cos`, `y = r·sin`):
  - `testClockwiseTwentyDegreesIsOneStepWithCarry`: begin at p(0); `move(p(20)) == 1`; `move(p(30)) == 1` (5° carried + 10°).
  - `testCounterClockwiseThirtyDegreesIsMinusTwo`: begin p(0); `move(p(-30)) == -2`.
  - `testCrossingSeamClockwise`: begin p(350); `move(p(10)) == 1`.
  - `testCrossingSeamCounterClockwise`: begin p(10); `move(p(350)) == -1`.
  - `testDirectionChangeCancelsCarry`: begin p(0); `move(p(10)) == 0`; `move(p(-10)) == 0`; `move(p(-25)) == -1`.
  - `testDeadZoneIgnored`: begin p(0); `move(p(90, r: 5)) == 0`; then `move(p(20)) == 1` (angle reference unchanged by the ignored point).
  - `testEndResetsCarry`: begin p(0); move(p(10)); end(); begin p(0); `move(p(10)) == 0`.
  - KeyMap: 126 (↑) → `.scroll(steps: -1)`, 125 (↓) → `.scroll(steps: 1)`, 36 (Return) → `.center`, 53 (Esc) → `.menu`, 49 (Space) → `.playPause`, 0 (A) → `nil`.
- [ ] **Step 2: Run TEST.** Expected: compile failure (types undefined).
- [ ] **Step 3: Implement.** Angle = `atan2(y, x)` in degrees; delta normalized to (-180, 180]; accumulate; `steps = Int(accum / degreesPerStep)` (truncating toward zero); `accum -= steps · degreesPerStep`. Points within `deadZoneRadius` don't update the angle.
- [ ] **Step 4: Run TEST.** Expected: all pass.
- [ ] **Step 5: Commit:** `feat: wheel gesture tracker and key map`.

### Task 3: Player model, MusicSource protocol and PlayerHub

**Files:**
- Create: `ClickWheel/Player/NowPlayingInfo.swift`, `ClickWheel/Player/MusicSource.swift`, `ClickWheel/Player/PlayerHub.swift`, `ClickWheel/Core/AppSettings.swift`
- Test: `ClickWheelTests/PlayerHubTests.swift`, `ClickWheelTests/Mocks/MockMusicSource.swift`

**Interfaces:**
- Produces:
  - `enum SourceID: String, CaseIterable { case appleMusic, spotify }`
  - `enum PlayerState: Equatable { case playing, paused, stopped }`
  - `struct NowPlayingInfo: Equatable { trackID: String; title: String; artist: String; album: String; duration: Double; position: Double; index: Int?; count: Int?; source: SourceID }` (seconds)
  - `struct PlayerSnapshot: Equatable { state: PlayerState; track: NowPlayingInfo?; volume: Int }`
  - `enum ArtworkRef: Equatable { case data(Data), url(URL), none }`
  - `enum MusicSourceError: Error, Equatable { case permissionDenied, notRunning, scriptFailed(String) }`
  - `protocol MusicSource: AnyObject { var id: SourceID { get }; var displayName: String { get }; func isRunning() -> Bool; func snapshot() throws -> PlayerSnapshot; func artwork() throws -> ArtworkRef; func playPause() throws; func next() throws; func previous() throws; func setVolume(_ value: Int) throws }`
  - `enum SourceMode: String, CaseIterable { case auto, appleMusic, spotify }`
  - `final class AppSettings: ObservableObject { init(defaults: UserDefaults = .standard); @Published var sourceMode: SourceMode; @Published var clickerEnabled: Bool /* default true */; @Published var keepOnTop: Bool /* default true */ }`, each persisted on set.
  - `enum HubStatus: Equatable { case ok, permissionDenied(SourceID), error(String) }`
  - `protocol PlayerControlling: AnyObject { func playPause(); func next(); func previous(); func adjustVolume(by delta: Int) }`
  - `@MainActor final class PlayerHub: ObservableObject, PlayerControlling { init(sources: [MusicSource], settings: AppSettings); @Published private(set) var activeSource: SourceID?; @Published private(set) var snapshot: PlayerSnapshot?; @Published private(set) var status: HubStatus; func refresh() async; func startPolling(interval: TimeInterval = 1.0); func stopPolling() }`. Commands run on a background queue against the active source, then trigger `refresh()`.
- `MockMusicSource`: settable `running`, `nextSnapshot`, `snapshotError`, `nextArtwork: ArtworkRef`, and recorded `calls: [String]` plus `snapshotCallCount`.

- [ ] **Step 1: Write failing tests** (sources `music` = mock `.appleMusic`, `spotify` = mock `.spotify`, settings on a throwaway `UserDefaults(suiteName:)`):
  - `testNotRunningSourceIsNeverQueried`: spotify not running → after `refresh()`, `spotify.snapshotCallCount == 0`.
  - `testAutoPicksPlayingSource`: music paused, spotify playing → `activeSource == .spotify`.
  - `testAutoKeepsLastActiveWhenBothPaused`: refresh with spotify playing, then both paused → still `.spotify`.
  - `testAutoBothPlayingKeepsLastActive`: active `.spotify`, then both playing → `.spotify`; from fresh hub both playing → `.appleMusic`.
  - `testAutoNothingActiveYetPicksFirstRunning`: only spotify running, paused → `.spotify`.
  - `testFixedModeIgnoresOtherSource`: mode `.spotify`, music playing, spotify paused → `.spotify`.
  - `testAppQuitClearsSnapshot`: spotify playing, refresh; then `spotify.running = false`; refresh → `snapshot == nil`, `activeSource == nil` (no other running), no throw.
  - `testPermissionDeniedSetsStatus`: spotify running, `snapshotError = .permissionDenied` → `status == .permissionDenied(.spotify)`, `snapshot == nil`.
  - `testCommandsGoToActiveSource`: active `.spotify`; `playPause()` → after awaiting refresh, `spotify.calls == ["playPause"]`, `music.calls == []`.
  - `testVolumeClampedAndAdjusted`: spotify volume 98, `adjustVolume(by: 6)` → `setVolume(100)`; volume 2, `adjustVolume(by: -6)` → `setVolume(0)`.
  - `testCommandsWithNoActiveSourceAreNoOps`: no sources running → `playPause()` records nothing.
  - `testSettingsPersist`: set `sourceMode = .spotify`, `clickerEnabled = false`; new `AppSettings` on same defaults reads them back.
- [ ] **Step 2: Run TEST.** Expected: compile failure.
- [ ] **Step 3: Implement** the types above. Selection rule (auto): candidates = running sources whose snapshot succeeded; if last active is playing → keep it; else first playing in `[.appleMusic, .spotify]` order; else last active if still running; else first running; else `nil`. Make test-only awaiting of commands possible by having each command method be fire-and-forget publicly but backed by an `internal func perform(_:) async`, which tests call.
- [ ] **Step 4: Run TEST.** Expected: all pass.
- [ ] **Step 5: Commit:** `feat: player model, music source protocol and hub`.

### Task 4: Navigator and stage-1 menus

**Files:**
- Create: `ClickWheel/Core/MenuModel.swift`, `ClickWheel/Core/Navigator.swift`
- Test: `ClickWheelTests/NavigatorTests.swift`, `ClickWheelTests/Mocks/SpyPlayerControls.swift`

**Interfaces:**
- Consumes: `WheelEvent` (Task 2), `PlayerControlling`, `AppSettings`, `SourceMode` (Task 3).
- Produces:
  - `struct MenuItem: Identifiable { id: String; label: String; detail: () -> String?; action: MenuAction }`
  - `enum MenuAction { case push(() -> MenuScreen), showNowPlaying, run(() -> Void) }`
  - `struct MenuScreen { title: String; items: [MenuItem]; selectedIndex: Int }`
  - `enum Screen { case menu(MenuScreen), nowPlaying }`
  - `@MainActor final class Navigator: ObservableObject { init(player: PlayerControlling, settings: AppSettings, onScrollStep: @escaping () -> Void = {}); @Published private(set) var stack: [Screen]; var current: Screen; func handle(_ event: WheelEvent) }`
- Menus: root `MenuScreen(title: "ClickWheel")` with items `Now Playing` (`.showNowPlaying`) and `Settings` (`.push`). Settings items: `Source` (detail "Auto" / "Apple Music" / "Spotify"; run cycles auto → appleMusic → spotify → auto) and `Clicker` (detail "On"/"Off"; run toggles).

- [ ] **Step 1: Write failing tests:**
  - `testStartsAtRootWithFirstItemSelected`: title "ClickWheel", labels `["Now Playing", "Settings"]`, index 0.
  - `testScrollMovesSelectionClamped`: scroll(+5) → index 1; scroll(-9) → index 0.
  - `testCenterOnSettingsPushes`: scroll(1), center → current title "Settings".
  - `testMenuPopsAndRestoresSelection`: into Settings, menu → root with index 1.
  - `testMenuAtRootIsNoOp`: menu → stack count 1.
  - `testCenterOnNowPlayingShowsNowPlaying`: center → `.nowPlaying`.
  - `testScrollOnNowPlayingAdjustsVolume`: on now playing, scroll(2) → spy recorded `adjustVolume(6)`.
  - `testTransportEventsForwardedEverywhere`: at root, `.playPause`, `.next`, `.previous` → spy `["playPause", "next", "previous"]`.
  - `testSourceCycles`: in Settings, center on Source three times → `settings.sourceMode` goes `.appleMusic`, `.spotify`, `.auto`; detail reflects the current value.
  - `testClickerToggles`: center on Clicker → `clickerEnabled == false`, detail "Off".
  - `testScrollStepCallbackFiresOnlyWhenSelectionMoves`: at index 0, scroll(-1) → callback count 0; scroll(1) → 1.
- [ ] **Step 2: Run TEST.** Expected: compile failure.
- [ ] **Step 3: Implement** `Navigator`. On now playing, scroll calls the callback once per event with non-zero steps (so the clicker ticks for volume too).
- [ ] **Step 4: Run TEST.** Expected: all pass.
- [ ] **Step 5: Commit:** `feat: navigator with stage 1 menus`.

### Task 5: AppleScript sources

**Files:**
- Create: `ClickWheel/Player/AppleScriptRunner.swift`, `ClickWheel/Player/ScriptOutputParser.swift`, `ClickWheel/Player/AppleMusicSource.swift`, `ClickWheel/Player/SpotifySource.swift`
- Test: `ClickWheelTests/ScriptOutputParserTests.swift`

**Interfaces:**
- Consumes: `MusicSource`, `PlayerSnapshot`, `NowPlayingInfo`, `ArtworkRef`, `MusicSourceError` (Task 3).
- Produces:
  - `enum AppleScriptRunner { static func run(_ source: String) throws -> NSAppleEventDescriptor }`, mapping error number -1743 → `.permissionDenied`, -600 → `.notRunning`, anything else → `.scriptFailed(message)`.
  - `enum ScriptOutputParser { static let separator: Character = "\u{1F}"; static func parse(_ output: String, source: SourceID, durationIsMilliseconds: Bool) -> PlayerSnapshot? }`
  - `final class AppleMusicSource: MusicSource` and `final class SpotifySource: MusicSource`; `isRunning()` uses `NSRunningApplication.runningApplications(withBundleIdentifier:)`.
- Script output contract (fields joined by ASCII 31): `state, volume, trackID, title, artist, album, duration, position, index, count`. State is `playing`/`paused`/`stopped`; when stopped, only `state` and `volume` are present. `index`/`count` may be empty. Music reports duration in seconds and Spotify in milliseconds; position is seconds for both. Numbers may use a comma decimal separator (locale), so the parser accepts both `.` and `,`.
- Apple Music track ID = `persistent ID of current track`; index/count from `index of current track` / `count of tracks of current playlist`, each wrapped in `try` (empty on error). Artwork = `data of artwork 1 of current track` → `.data`. Spotify track ID = `id of current track`, artwork = `artwork url of current track` → `.url`, index/count empty.
- Each source checks `isRunning()` before every script and throws `.notRunning` otherwise.

- [ ] **Step 1: Write failing parser tests** (`j(...)` joins with the separator):
  - `testParsesPlayingMusicTrack`: `j("playing","55","ABC","Song","Artist","Album","245.5","12.25","3","14")`, ms=false → state `.playing`, volume 55, duration 245.5, position 12.25, index 3, count 14.
  - `testSpotifyMillisecondsConverted`: duration "245000", ms=true → 245.0.
  - `testStoppedHasNoTrack`: `j("stopped","40")` → track nil, volume 40.
  - `testOddMetadataSurvives`: title `"Hey | \"Jude\" 🎸"`, album "" → title and empty album preserved exactly, artist not shifted.
  - `testMissingIndexAndCount`: empty index/count → both nil.
  - `testCommaDecimals`: duration "245,5" → 245.5.
  - `testGarbageReturnsNil`: "" and `"weird"` → nil.
- [ ] **Step 2: Run TEST.** Expected: compile failure.
- [ ] **Step 3: Implement** parser, runner and both sources (scripts as multi-line string literals inside each source).
- [ ] **Step 4: Run TEST.** Expected: all pass.
- [ ] **Step 5: Manual check:** temporarily call `AppleMusicSource().snapshot()` and `SpotifySource().snapshot()` from the app at launch, with each app playing, and print. Expected: the Automation prompt appears once per app; after Allow, real track info prints. Remove the temporary call.
- [ ] **Step 6: Commit:** `feat: Apple Music and Spotify AppleScript sources`.

### Task 6: Time formatting and artwork cache

**Files:**
- Create: `ClickWheel/Core/TimeFormat.swift`, `ClickWheel/Player/ArtworkCache.swift`
- Test: `ClickWheelTests/TimeFormatTests.swift`, `ClickWheelTests/ArtworkCacheTests.swift`

**Interfaces:**
- Consumes: `ArtworkRef`, `MusicSource` (Task 3).
- Produces:
  - `enum TimeFormat { static func elapsed(_ s: Double) -> String; static func remaining(position: Double, duration: Double) -> String; static func progress(position: Double, duration: Double) -> Double }`
  - `@MainActor final class ArtworkCache: ObservableObject { init(capacity: Int = 20, fetchURL: @escaping (URL) async throws -> Data = { try await URLSession.shared.data(from: $0).0 }); func image(trackID: String, source: MusicSource) async -> NSImage? }`. On a miss it calls `source.artwork()` off the main thread, then (for `.url`) `fetchURL`. Failures return nil and aren't cached. Least-recently-used items are evicted past capacity.

- [ ] **Step 1: Write failing tests:**
  - `elapsed(83) == "1:23"`, `elapsed(5) == "0:05"`, `elapsed(3725) == "1:02:05"`, `elapsed(-4) == "0:00"`, `elapsed(.nan) == "0:00"`.
  - `remaining(position: 83, duration: 200) == "-1:57"`; `remaining(position: 250, duration: 200) == "-0:00"`; `remaining(position: 10, duration: 0) == "-0:00"`.
  - `progress(50, 200) == 0.25`, `progress(250, 200) == 1`, `progress(10, 0) == 0`, `progress(-5, 200) == 0`.
  - `testCacheHitDoesNotRefetch`: mock source returns `.url(x)`; fetch closure counts calls and returns PNG data of a 1×1 image; two calls with the same trackID → fetch count 1, `source.calls` contains "artwork" once.
  - `testFailureNotCached`: first fetch throws → nil; second succeeds → image, fetch count 2.
  - `testEvictsBeyondCapacity`: capacity 2; tracks a, b, c, then a → 4 fetches.
- [ ] **Step 2: Run TEST.** Expected: compile failure.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run TEST.** Expected: all pass.
- [ ] **Step 5: Commit:** `feat: time formatting and artwork cache`.

### Task 7: iPod UI (screen, wheel, sound, font)

**Files:**
- Create: `ClickWheel/UI/Theme.swift`, `ClickWheel/UI/IPodView.swift`, `ClickWheel/UI/ScreenView.swift`, `ClickWheel/UI/MenuListView.swift`, `ClickWheel/UI/NowPlayingView.swift`, `ClickWheel/UI/ClickWheelView.swift`, `ClickWheel/UI/ClickSound.swift`, `ClickWheel/Resources/Fonts/SourceSans3-Regular.otf`, `SourceSans3-Semibold.otf`, `OFL.txt`
- Modify: `project.yml` (resources, `ATSApplicationFontsPath: Fonts` in Info.plist), `ClickWheel/App/ClickWheelApp.swift`

**Interfaces:**
- Consumes: `Navigator`, `PlayerHub`, `AppSettings`, `ArtworkCache`, `TimeFormat`, `WheelGestureTracker`, `WheelEvent`.
- Produces: `struct IPodView: View` (environment objects: `Navigator`, `PlayerHub`, `AppSettings`, `ArtworkCache`); `final class ClickSound { func play() }`.

Visual values (Theme): body 280 × 460, corner radius 36, white-to-light-grey vertical gradient, shadow radius 12 at 25% black. Screen inset 20 pt from top/sides, 240 × 180, corner radius 8, LCD gradient `#C9D3DC → #E8EDF1`, 1 pt dark border. Header 20 pt tall with the title centered (Semibold 13), a play/pause glyph on the left and a drawn battery on the right. List rows 22 pt, Regular 14; selected row uses a blue gradient `#5EA0E6 → #2D6FC4` with white text. Wheel diameter 180, centered 60 pt below the screen, light grey with a subtle inner shadow; center button 64 pt. Labels "MENU", "⏮", "⏭", "▶❚❚" in grey Semibold 12.

- [ ] **Step 1: Download Source Sans 3** Regular and Semibold OTF plus `OFL.txt` from the `adobe-fonts/source-sans` GitHub releases into `ClickWheel/Resources/Fonts/`, and register via `ATSApplicationFontsPath`.
- [ ] **Step 2: Build views.** `ScreenView` switches on `navigator.current`: `.menu` → `MenuListView` (rows with label, optional detail right-aligned, `›` for `.push` items; keeps the selected row visible via `ScrollViewReader`); `.nowPlaying` → `NowPlayingView` (artwork 80 × 80 from `ArtworkCache`, placeholder music-note square when nil; title/artist/album truncated with tail; "n of m" when both known; progress bar using `TimeFormat.progress`; elapsed and remaining labels; "Nothing playing" when `hub.snapshot?.track == nil`). If `hub.status == .permissionDenied(id)`, the screen shows "Allow ClickWheel to control <name> in System Settings" and an "Open Settings" button that opens `x-apple.systempreferences:com.apple.preference.security?Privacy_Automation`.
- [ ] **Step 3: `ClickWheelView`.** `DragGesture(minimumDistance: 0)` on the ring feeds `WheelGestureTracker` (points relative to the wheel center); non-zero steps → `navigator.handle(.scroll(steps:))`. A tap with no rotation in the top / left / right / bottom quadrant of the ring → `.menu` / `.previous` / `.next` / `.playPause`. Center button tap → `.center`.
- [ ] **Step 4: `ClickSound`.** At init, synthesize a 4 ms, 2 kHz sine burst with exponential decay into an `AVAudioPCMBuffer` (44.1 kHz mono) and play it through an `AVAudioEngine` player node. Wire `Navigator(onScrollStep:)` to `if settings.clickerEnabled { clickSound.play() }`.
- [ ] **Step 5: Wire the app.** `ClickWheelApp` creates `AppSettings`, `PlayerHub(sources: [AppleMusicSource(), SpotifySource()], settings:)`, `Navigator`, `ArtworkCache`, `ClickSound`, starts polling, and shows `IPodView` (temporarily in a normal window).
- [ ] **Step 6: Run TEST** (no regressions), then run the app. Expected: the iPod renders; scrolling moves the highlight with ticks; Settings toggles work; Now Playing shows the live track from whichever app is playing.
- [ ] **Step 7: Commit:** `feat: iPod screen, click wheel and click sound`.

### Task 8: Floating window and keyboard

**Files:**
- Create: `ClickWheel/Window/FloatingWindow.swift`, `ClickWheel/App/AppDelegate.swift`
- Modify: `ClickWheel/App/ClickWheelApp.swift`, `ClickWheel/UI/IPodView.swift`

**Interfaces:**
- Consumes: `IPodView`, `KeyMap`, `Navigator`, `AppSettings`.
- Produces: `final class FloatingWindow: NSWindow` (borderless, `backgroundColor = .clear`, `isOpaque = false`, `hasShadow = false` since SwiftUI draws the shadow, `canBecomeKey == true`, `setFrameAutosaveName("ClickWheelWindow")`); `struct WindowDragArea: NSViewRepresentable` whose `mouseDown` calls `window?.performDrag(with:)`.

- [ ] **Step 1:** `ClickWheelApp` uses `@NSApplicationDelegateAdaptor(AppDelegate.self)` and a `Settings { EmptyView() }` scene, so SwiftUI opens no default window. `AppDelegate.applicationDidFinishLaunching` builds the objects from Task 7, hosts `IPodView` in a `FloatingWindow` (about 300 × 480 content including shadow margin), centers it the first time, and shows it.
- [ ] **Step 2:** `IPodView` puts `WindowDragArea` behind the body shape (screen and wheel sit above it and keep their own gestures). Context menu on the body: "Keep on Top" (checkmark from `settings.keepOnTop`) and "Quit ClickWheel". `keepOnTop` sets `window.level` to `.floating` or `.normal`, applied at launch and on change.
- [ ] **Step 3:** Install `NSEvent.addLocalMonitorForEvents(matching: .keyDown)`; `KeyMap.event(forKeyCode:)` non-nil → `navigator.handle(...)` and swallow the event; otherwise pass it through (so ⌘Q still works).
- [ ] **Step 4: Run TEST**, then run the app. Expected: a borderless iPod with no title bar; drag by the body moves it; position is restored on relaunch; Keep on Top works; arrows/Return/Esc/Space work; ⌘Q quits.
- [ ] **Step 5: Commit:** `feat: floating borderless window and keyboard control`.

### Task 9: Manual verification, README and GitHub

**Files:**
- Create: `README.md`, `LICENSE` (MIT, `Copyright (c) 2026 mfelouro`), `docs/screenshot.png`

- [ ] **Step 1: Manual checklist** (record pass/fail in the commit message body):
  1. Apple Music playing → track, artwork, progress update every second.
  2. Spotify playing → same.
  3. Pause Music, play Spotify → switches to Spotify within ~1 s (Auto).
  4. Source set to Apple Music while Spotify plays → stays on Music.
  5. ⏮ / ⏭ / ▶❚❚ and wheel volume work in both apps.
  6. Quit Spotify while playing → "Nothing playing"; Spotify does **not** relaunch within 10 s.
  7. Reset permission (`tccutil reset AppleEvents com.mfelouro.ClickWheel`), relaunch, click Don't Allow → permission message and working "Open Settings" button.
  8. Keyboard shortcuts; Keep on Top; window position restored after relaunch.
  9. A radio station or podcast in Music → no NaN or negative times.
- [ ] **Step 2: README:** what it is (fan homage, not affiliated with Apple), screenshot, requirements (macOS 14+, Xcode, XcodeGen), build steps (`brew install xcodegen`, `xcodegen generate`, open and run), the Automation permission note, the roadmap (stages 2–4), and font credit (Source Sans 3, SIL OFL).
- [ ] **Step 3: Commit:** `docs: README, license and screenshot`.
- [ ] **Step 4: Publish (ask the user first):** with their OK, `gh repo create clickwheel --public --source . --push` and share the URL.
