import Foundation
import os

/// The iPod's menu stack and screen modes. Scroll moves the selection (or
/// volume / scrub position on Now Playing), center opens the selected item,
/// menu goes back one level. Timeouts and repeats run off `.tick(now:)`.
@MainActor
final class Navigator: ObservableObject {
    static let volumePerStep = 3
    static let volumeOverlayDuration: TimeInterval = 2
    static let scrubIdleTimeout: TimeInterval = 3
    static let scrubSecondsPerStep: Double = 2
    static let quickScrollFade: TimeInterval = 1
    static let seekRepeatInterval: TimeInterval = 0.25
    static let seekSeconds: Double = 5

    @Published private(set) var stack: [Screen] = []
    @Published private(set) var nowPlayingMode: NowPlayingMode = .normal
    @Published private(set) var quickScrollLetter: String?
    @Published private(set) var lastNavigation: NavigationDirection = .forward
    @Published private(set) var stopwatch = Stopwatch()
    @Published private(set) var backlight = Backlight()
    /// Whether the light was on before the current input woke it (for toggles).
    private var backlightBeforeInput = false
    private(set) var profile: FirmwareProfile

    /// Shared with the slide transition, which reads it at animation time.
    let slideDirection = SlideDirection()

    /// The most recent load or play, so callers (and tests) can await it.
    private(set) var lastTask: Task<Void, Never>?

    private let player: PlayerControlling
    private let settings: AppSettings
    private let musicMenu: (() -> MenuScreen)?
    private let shuffle: (() async throws -> Void)?
    private let browse: (() -> MenuScreen)?
    private let playlists: (() -> MenuItem)?
    private let now: () -> TimeInterval
    private let onPlayed: () -> Void
    private let onRowsMoved: (Int) -> Void
    private let log = Logger(subsystem: "com.mfelouro.ClickWheel", category: "Navigator")

    private var accelerator = ScrollAccelerator()
    private var track: NowPlayingInfo?
    private var lastQuickScroll: TimeInterval?
    private var seeking: (direction: Double, nextAt: TimeInterval)?

    init(player: PlayerControlling, settings: AppSettings,
         musicMenu: (() -> MenuScreen)? = nil,
         shuffle: (() async throws -> Void)? = nil,
         profile: FirmwareProfile = IPodModel.fifthGen.spec.firmware,
         browse: (() -> MenuScreen)? = nil,
         playlists: (() -> MenuItem)? = nil,
         now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
         onPlayed: @escaping () -> Void = {},
         onRowsMoved: @escaping (Int) -> Void = { _ in }) {
        self.player = player
        self.settings = settings
        self.musicMenu = musicMenu
        self.shuffle = shuffle
        self.profile = profile
        self.browse = browse
        self.playlists = playlists
        self.now = now
        self.onPlayed = onPlayed
        self.onRowsMoved = onRowsMoved
        stack = [.menu(rootMenu())]
    }

    var current: Screen { stack[stack.count - 1] }

    func handle(_ event: WheelEvent) {
        // Any input lights the backlight, except the tick and the hold that toggles it.
        backlightBeforeInput = backlight.isOn
        switch event {
        case .tick: break
        case .menuHold where profile.holdMenu == .toggleBacklight: break
        default: wakeBacklight()
        }
        switch event {
        case .scroll(let steps): scroll(steps)
        case .center: center()
        case .menu: back()
        case .menuHold:
            switch profile.holdMenu {
            case .home: popToRoot()
            case .toggleBacklight: toggleBacklight()
            }
        case .playPause:
            if case .stopwatch = current { stopwatch.reset() } else { player.playPause() }
        case .next: player.next()
        case .previous: player.restartOrPrevious()
        case .seekForward(let active): setSeeking(active ? 1 : nil)
        case .seekBackward(let active): setSeeking(active ? -1 : nil)
        case .tick(let time): tick(time)
        }
    }

    /// A click on a row: highlight it and open it, as if scrolled to and selected.
    func choose(row: Int) {
        guard case .menu(var screen) = current, screen.items.indices.contains(row),
              screen.items[row].isSelectable else { return }
        backlightBeforeInput = backlight.isOn
        wakeBacklight()
        screen.selectedIndex = row
        stack[stack.count - 1] = .menu(screen)
        select(in: screen)
    }

    /// Switches to another model's firmware: back to its main menu, with every
    /// mode and overlay cleared.
    func setProfile(_ newProfile: FirmwareProfile) {
        profile = newProfile
        nowPlayingMode = .normal
        quickScrollLetter = nil
        lastQuickScroll = nil
        seeking = nil
        accelerator.reset()
        lastNavigation = .back
        slideDirection.forward = false
        stack = [.menu(rootMenu())]
        wakeBacklight()
    }

    private func wakeBacklight() {
        guard profile.backlight else { return }
        backlight.wake(now: now(), timer: settings.backlightTimer)
    }

    private func toggleBacklight() {
        guard profile.backlight else { return }
        backlight.toggle(now: now(), timer: settings.backlightTimer, wasOn: backlightBeforeInput)
    }

    /// The track now loaded (or nil). Adds or removes the root's Now Playing row
    /// and ends scrubbing when the track changes.
    func setTrack(_ newTrack: NowPlayingInfo?) {
        if newTrack?.trackID != track?.trackID, case .scrubbing = nowPlayingMode {
            nowPlayingMode = .normal
        }
        let hadTrack = track != nil
        track = newTrack
        guard hadTrack != (newTrack != nil), case .menu(var root) = stack[0] else { return }
        let selectedLabel = root.items.indices.contains(root.selectedIndex) ? root.items[root.selectedIndex].label : nil
        let fresh = rootMenu()
        root.items = fresh.items
        if let label = selectedLabel, let index = root.items.firstIndex(where: { $0.label == label }) {
            root.selectedIndex = index
        } else {
            root.selectedIndex = max(0, root.items.count - 1)
        }
        root.windowStart = MenuWindow.start(previous: 0, selected: root.selectedIndex,
                                            visible: profile.visibleRows, count: root.items.count)
        stack[0] = .menu(root)
    }

    /// The Quick Scroll index letter for a row label: A–Z ignoring accents, else "#".
    nonisolated static func indexLetter(for label: String) -> String {
        guard let first = label.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).first,
              first.isASCII, first.isLetter else { return "#" }
        return String(first).uppercased()
    }

    // MARK: - Input

    private func scroll(_ steps: Int) {
        guard steps != 0 else { return }
        let time = now()
        switch current {
        case .nowPlaying:
            if case .scrubbing(let position, _) = nowPlayingMode {
                let multiplier = accelerator.multiplier(forStep: steps, now: time)
                let duration = track?.duration ?? 0
                let target = min(max(0, position + Double(steps * multiplier) * Self.scrubSecondsPerStep), duration)
                nowPlayingMode = .scrubbing(position: target, until: time + Self.scrubIdleTimeout)
                player.setPosition(target)
            } else {
                // Volume is never accelerated.
                player.adjustVolume(by: steps * Self.volumePerStep)
                nowPlayingMode = .volume(until: time + Self.volumeOverlayDuration)
                onRowsMoved(abs(steps))
            }
        case .menu(var screen):
            let multiplier = accelerator.multiplier(forStep: steps, now: time)
            let selectable = screen.items.indices.filter { screen.items[$0].isSelectable }
            guard let position = selectable.firstIndex(of: screen.selectedIndex) else { return }
            let targetPosition = min(max(position + steps * multiplier, 0), selectable.count - 1)
            let target = selectable[targetPosition]
            guard target != screen.selectedIndex else { return }
            screen.selectedIndex = target
            screen.windowStart = MenuWindow.start(previous: screen.windowStart, selected: target,
                                                  visible: profile.visibleRows, count: screen.items.count)
            stack[stack.count - 1] = .menu(screen)
            if profile.quickScroll && screen.quickScroll && multiplier >= 2 {
                quickScrollLetter = Self.indexLetter(for: screen.items[target].label)
                lastQuickScroll = time
            }
            onRowsMoved(abs(targetPosition - position))
        case .clock, .stopwatch:
            break
        }
    }

    private func center() {
        switch current {
        case .nowPlaying:
            if case .scrubbing = nowPlayingMode {
                nowPlayingMode = .normal
            } else if let track {
                nowPlayingMode = .scrubbing(position: track.position, until: now() + Self.scrubIdleTimeout)
            }
        case .stopwatch:
            stopwatch.toggle(now: now())
        case .clock:
            break
        case .menu(let screen):
            select(in: screen)
        }
    }

    private func back() {
        // MENU leaves the scrubber first; the volume bar doesn't hold MENU back.
        if case .nowPlaying = current, case .scrubbing = nowPlayingMode {
            nowPlayingMode = .normal
            return
        }
        guard stack.count > 1 else { return }
        stack.removeLast()
        leftScreen()
    }

    private func popToRoot() {
        guard stack.count > 1 else { return }
        stack.removeSubrange(1...)
        leftScreen()
    }

    private func leftScreen() {
        lastNavigation = .back
        slideDirection.forward = false
        nowPlayingMode = .normal
        quickScrollLetter = nil
        accelerator.reset()
    }

    private func push(_ screen: Screen) {
        lastNavigation = .forward
        slideDirection.forward = true
        quickScrollLetter = nil
        accelerator.reset()
        stack.append(screen)
    }

    private func setSeeking(_ direction: Double?) {
        seeking = direction.map { ($0, now() + Self.seekRepeatInterval) }
    }

    private func tick(_ time: TimeInterval) {
        // Only publish when something changes, so idle ticks don't redraw the screen.
        if profile.backlight {
            var next = backlight
            next.tick(now: time)
            if next != backlight { backlight = next }
        }
        switch nowPlayingMode {
        case .volume(let until) where time >= until: nowPlayingMode = .normal
        case .scrubbing(_, let until) where time >= until: nowPlayingMode = .normal
        default: break
        }
        if let last = lastQuickScroll, time - last >= Self.quickScrollFade {
            quickScrollLetter = nil
            lastQuickScroll = nil
        }
        // Fire every repeat that's due, but only once per tick if ticks were missed.
        if var seek = seeking, time >= seek.nextAt {
            player.seek(by: seek.direction * Self.seekSeconds)
            seek.nextAt = max(seek.nextAt + Self.seekRepeatInterval, time + Self.seekRepeatInterval / 2)
            seeking = seek
        }
    }

    // MARK: - Menus

    private func select(in screen: MenuScreen) {
        guard screen.items.indices.contains(screen.selectedIndex) else { return }
        let item = screen.items[screen.selectedIndex]
        guard item.isSelectable else { return }
        switch item.action {
        case .push(let build): push(.menu(build()))
        case .load(let title, let empty, let loader):
            load(title: title, empty: empty, quickScroll: item.quickScrollList, loader: loader)
        case .showNowPlaying: push(.nowPlaying)
        case .open(let screen): push(screen)
        case .run(let action):
            action()
            // Re-publish so rows showing a detail value refresh — but only if the
            // action didn't navigate (switching Model resets to the new main menu).
            if case .menu(let top) = current, top.id == screen.id {
                stack[stack.count - 1] = .menu(screen)
            }
        case .play(let start): play(start)
        }
    }

    private func load(title: String, empty: String, quickScroll: Bool, loader: @escaping () async throws -> [MenuItem]) {
        var screen = MenuScreen(title: title, items: [.placeholder("Loading…")])
        screen.quickScroll = quickScroll
        push(.menu(screen))
        lastTask = Task {
            let items: [MenuItem]
            do {
                let loaded = try await loader()
                items = loaded.isEmpty ? [.placeholder(empty)] : loaded
            } catch {
                log.error("Load failed: \(error.localizedDescription, privacy: .public)")
                items = [.placeholder("Couldn't load library")]
            }
            replaceItems(ofScreen: screen.id, with: items)
        }
    }

    /// Applies a finished load only if its screen is still on the stack.
    private func replaceItems(ofScreen id: UUID, with items: [MenuItem]) {
        for index in stack.indices {
            if case .menu(var screen) = stack[index], screen.id == id {
                screen.items = items
                stack[index] = .menu(screen)
                return
            }
        }
    }

    private func play(_ start: @escaping () async throws -> Void) {
        let origin = stack.count
        lastTask = Task {
            do {
                try await start()
                // Only jump to Now Playing if the user is still where they picked the song.
                if stack.count == origin { push(.nowPlaying) }
                onPlayed()
            } catch {
                log.error("Play failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func rootMenu() -> MenuScreen {
        var items: [MenuItem] = []
        let title: String
        switch profile.menuStyle {
        case .fifthGen, .classic:
            title = profile.menuStyle == .classic ? "iPod" : "ClickWheel"
            if let musicMenu {
                items.append(MenuItem("Music", action: .push(musicMenu)))
            }
            items.append(MenuItem("Extras", action: .push { MenuScreen(title: "Extras", items: [
                MenuItem("Clock", action: .open(.clock)),
                MenuItem("Stopwatch", action: .open(.stopwatch)),
            ]) }))
            items.append(MenuItem("Settings", action: .push { [unowned self] in self.settingsMenu() }))
            if let shuffle {
                items.append(MenuItem("Shuffle Songs", action: .play(shuffle)))
            }
        case .firstGenLate:
            title = "iPod"
            if let playlists { items.append(playlists()) }
            if let browse { items.append(MenuItem("Browse", action: .push(browse))) }
            items.append(MenuItem("Extras", action: .push { MenuScreen(title: "Extras", items: [
                MenuItem("Clock", action: .open(.clock)),
            ]) }))
            items.append(MenuItem("Settings", action: .push { [unowned self] in self.settingsMenu() }))
            items.append(MenuItem("Backlight", action: .run { [unowned self] in self.toggleBacklight() }))
        case .thirdGenLate:
            title = "iPod"
            if let musicMenu { items.append(MenuItem("Music", action: .push(musicMenu))) }
            items.append(MenuItem("Extras", action: .push { MenuScreen(title: "Extras", items: [
                MenuItem("Clock", action: .open(.clock)),
            ]) }))
            items.append(MenuItem("Settings", action: .push { [unowned self] in self.settingsMenu() }))
            if let shuffle { items.append(MenuItem("Shuffle Songs", action: .play(shuffle))) }
            items.append(MenuItem("Backlight", action: .run { [unowned self] in self.toggleBacklight() }))
        }
        if track != nil {
            items.append(MenuItem("Now Playing", action: .showNowPlaying))
        }
        return MenuScreen(title: title, items: items)
    }

    private func settingsMenu() -> MenuScreen {
        let settings = self.settings
        var items = [
            MenuItem("Model", detail: { settings.model.shortName },
                     action: .push { [unowned self] in self.modelMenu() }),
        ]
        if let choice = profile.colours {
            items.append(MenuItem("Colour", detail: { settings.colour(in: choice).label },
                                  action: .push { [unowned self] in self.colourMenu(choice) }))
        }
        items += [
            MenuItem("Source", detail: { Self.label(for: settings.sourceMode) }, action: .run {
                let all = SourceMode.allCases
                let index = all.firstIndex(of: settings.sourceMode) ?? 0
                settings.sourceMode = all[(index + 1) % all.count]
            }),
        ]
        if profile.backlight {
            items.append(MenuItem("Backlight Timer", detail: { settings.backlightTimer.label }, action: .run { [unowned self] in
                let all = BacklightTimer.allCases
                let index = all.firstIndex(of: settings.backlightTimer) ?? 0
                settings.backlightTimer = all[(index + 1) % all.count]
                self.backlight.apply(timer: settings.backlightTimer, now: self.now())
            }))
        }
        items.append(MenuItem("Clicker", detail: { settings.clickerEnabled ? "On" : "Off" }, action: .run {
            settings.clickerEnabled.toggle()
        }))
        return MenuScreen(title: "Settings", items: items)
    }

    /// Settings › Model: every iPod in release order, the current one ticked.
    /// Like every iPod list it opens at the top. Choosing another switches to it
    /// (the app then resets to its main menu); choosing the current one goes back.
    private func modelMenu() -> MenuScreen {
        let settings = self.settings
        return MenuScreen(title: "Model", items: IPodModel.allCases.map { model in
            MenuItem(model.generationName,
                     detail: { (settings.model == model ? "✓ " : "") + String(model.spec.year) },
                     action: .run { [unowned self] in
                         if settings.model == model { self.back() } else { settings.model = model }
                     })
        })
    }

    /// Settings › Colour (models that come in colours): opens at the top, the
    /// current colour ticked; choosing one sets it and goes back.
    private func colourMenu(_ choice: ColourChoice) -> MenuScreen {
        let settings = self.settings
        return MenuScreen(title: "Colour", items: choice.options.map { colour in
            MenuItem(colour.label, detail: { settings.colour(in: choice) == colour ? "✓" : nil },
                     action: .run { [unowned self] in
                         settings.setColour(colour, in: choice)
                         self.back()
                     })
        })
    }

    private static func label(for mode: SourceMode) -> String {
        switch mode {
        case .auto: return "Auto"
        case .appleMusic: return SourceID.appleMusic.displayName
        case .spotify: return SourceID.spotify.displayName
        }
    }
}
