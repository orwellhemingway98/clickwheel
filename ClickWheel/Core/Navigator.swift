import Foundation

/// The iPod's menu stack. Scroll moves the selection (or volume on Now Playing),
/// center opens the selected item, menu goes back one level.
@MainActor
final class Navigator: ObservableObject {
    static let volumePerStep = 3

    @Published private(set) var stack: [Screen] = []

    private let player: PlayerControlling
    private let settings: AppSettings
    private let onScrollStep: () -> Void

    init(player: PlayerControlling, settings: AppSettings, onScrollStep: @escaping () -> Void = {}) {
        self.player = player
        self.settings = settings
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
            let target = min(max(screen.selectedIndex + steps, 0), max(screen.items.count - 1, 0))
            guard target != screen.selectedIndex else { return }
            screen.selectedIndex = target
            stack[stack.count - 1] = .menu(screen)
            onScrollStep()
        }
    }

    private func select() {
        guard case .menu(let screen) = current, screen.items.indices.contains(screen.selectedIndex) else { return }
        switch screen.items[screen.selectedIndex].action {
        case .push(let build): stack.append(.menu(build()))
        case .showNowPlaying: stack.append(.nowPlaying)
        case .run(let action):
            action()
            // Re-publish so rows showing a detail value refresh.
            stack[stack.count - 1] = .menu(screen)
        }
    }

    private func rootMenu() -> MenuScreen {
        MenuScreen(title: "ClickWheel", items: [
            MenuItem("Now Playing", action: .showNowPlaying),
            MenuItem("Settings", action: .push { [unowned self] in self.settingsMenu() }),
        ])
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
