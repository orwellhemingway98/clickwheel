import Foundation
import os

/// The iPod's menu stack. Scroll moves the selection (or volume on Now Playing),
/// center opens the selected item, menu goes back one level.
@MainActor
final class Navigator: ObservableObject {
    static let volumePerStep = 3

    @Published private(set) var stack: [Screen] = []

    /// The most recent load or play, so callers (and tests) can await it.
    private(set) var lastTask: Task<Void, Never>?

    private let player: PlayerControlling
    private let settings: AppSettings
    private let musicMenu: (() -> MenuScreen)?
    private let onPlayed: () -> Void
    private let onScrollStep: () -> Void
    private let log = Logger(subsystem: "com.mfelouro.ClickWheel", category: "Navigator")

    init(player: PlayerControlling, settings: AppSettings,
         musicMenu: (() -> MenuScreen)? = nil,
         onPlayed: @escaping () -> Void = {},
         onScrollStep: @escaping () -> Void = {}) {
        self.player = player
        self.settings = settings
        self.musicMenu = musicMenu
        self.onPlayed = onPlayed
        self.onScrollStep = onScrollStep
        stack = [.menu(rootMenu())]
    }

    var current: Screen { stack[stack.count - 1] }

    func handle(_ event: WheelEvent) {
        switch event {
        case .scroll(let steps): scroll(steps)
        case .center: select()
        case .menu: if stack.count > 1 { stack.removeLast() }
        case .playPause: player.playPause()
        case .next: player.next()
        case .previous: player.previous()
        case .menuHold, .seekForward, .seekBackward, .tick: break
        }
    }

    // MARK: - Private

    private func scroll(_ steps: Int) {
        guard steps != 0 else { return }
        switch current {
        case .nowPlaying:
            player.adjustVolume(by: steps * Self.volumePerStep)
            onScrollStep()
        case .menu(var screen):
            let selectable = screen.items.indices.filter { screen.items[$0].isSelectable }
            guard let position = selectable.firstIndex(of: screen.selectedIndex) else { return }
            let target = selectable[min(max(position + steps, 0), selectable.count - 1)]
            guard target != screen.selectedIndex else { return }
            screen.selectedIndex = target
            screen.windowStart = MenuWindow.start(previous: screen.windowStart, selected: target,
                                                  visible: MenuWindow.visibleRows, count: screen.items.count)
            stack[stack.count - 1] = .menu(screen)
            onScrollStep()
        }
    }

    private func select() {
        guard case .menu(let screen) = current, screen.items.indices.contains(screen.selectedIndex) else { return }
        let item = screen.items[screen.selectedIndex]
        guard item.isSelectable else { return }
        switch item.action {
        case .push(let build): stack.append(.menu(build()))
        case .load(let title, let empty, let loader): load(title: title, empty: empty, loader: loader)
        case .showNowPlaying: stack.append(.nowPlaying)
        case .run(let action):
            action()
            // Re-publish so rows showing a detail value refresh.
            stack[stack.count - 1] = .menu(screen)
        case .play(let start): play(start)
        }
    }

    private func load(title: String, empty: String, loader: @escaping () async throws -> [MenuItem]) {
        let screen = MenuScreen(title: title, items: [.placeholder("Loading…")])
        stack.append(.menu(screen))
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
                if stack.count == origin { stack.append(.nowPlaying) }
                onPlayed()
            } catch {
                log.error("Play failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func rootMenu() -> MenuScreen {
        var items: [MenuItem] = []
        if let musicMenu {
            items.append(MenuItem("Music", action: .push(musicMenu)))
        }
        items.append(MenuItem("Now Playing", action: .showNowPlaying))
        items.append(MenuItem("Settings", action: .push { [unowned self] in self.settingsMenu() }))
        return MenuScreen(title: "ClickWheel", items: items)
    }

    private func settingsMenu() -> MenuScreen {
        let settings = self.settings
        return MenuScreen(title: "Settings", items: [
            MenuItem("Source", detail: { Self.label(for: settings.sourceMode) }, action: .run {
                let all = SourceMode.allCases
                let index = all.firstIndex(of: settings.sourceMode) ?? 0
                settings.sourceMode = all[(index + 1) % all.count]
            }),
            MenuItem("Clicker", detail: { settings.clickerEnabled ? "On" : "Off" }, action: .run {
                settings.clickerEnabled.toggle()
            }),
        ])
    }

    private static func label(for mode: SourceMode) -> String {
        switch mode {
        case .auto: return "Auto"
        case .appleMusic: return SourceID.appleMusic.displayName
        case .spotify: return SourceID.spotify.displayName
        }
    }
}
