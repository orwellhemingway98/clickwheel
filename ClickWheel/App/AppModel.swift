import Combine
import AppKit
import SwiftUI

/// Owns the long-lived objects the views share.
@MainActor
final class AppModel {
    /// The unit tests are hosted in the app; don't talk to real music apps then.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    let settings = AppSettings()
    let hub: PlayerHub
    let navigator: Navigator
    let artwork = ArtworkCache()
    let clickSound = ClickSound()
    /// One click per row moved, rate-limited during fast scrolls.
    private let clicks = ClickThrottle()
    let library = AppleMusicLibrary()
    let libraryRunner = BackgroundRunner(label: "ClickWheel.Library")
    let display = DisplayGeometry()
    private var trackObserver: AnyCancellable?

    init() {
        hub = PlayerHub(sources: [AppleMusicSource(), SpotifySource()], settings: settings)
        let settings = settings
        let clickSound = clickSound
        let hub = hub
        let library = library
        let libraryRunner = libraryRunner
        navigator = Navigator(
            player: hub, settings: settings,
            musicMenu: { LibraryMenus.musicMenu(library: library, runner: libraryRunner) },
            shuffle: LibraryMenus.shuffleAction(library: library, runner: libraryRunner),
            onPlayed: { Task { await hub.refresh() } },
            onRowsMoved: { [clicks] _ in
                if settings.clickerEnabled, clicks.shouldClick(now: ProcessInfo.processInfo.systemUptime) {
                    clickSound.play()
                }
            })
        let navigator = navigator
        trackObserver = hub.$snapshot
            .map { $0?.track }
            .sink { track in navigator.setTrack(track) }
        hub.startPolling()
    }

    /// The iPod with every shared object injected.
    func rootView(includesWindowControls: Bool = true) -> some View {
        LifeSizeRoot(display: display) {
            IPodView(includesWindowControls: includesWindowControls)
        }
        .environmentObject(settings)
        .environmentObject(hub)
        .environmentObject(navigator)
        .environmentObject(artwork)
    }

    /// Development aid: `ClickWheel --snapshot out.png [--now-playing] [--keys c,d,m]`
    /// renders the iPod to a PNG after the first poll, then quits. `--keys` presses
    /// c(enter) d(own) u(p) m(enu) with a pause after each, so loads can finish.
    func renderSnapshotIfRequested() {
        let args = CommandLine.arguments
        guard let flag = args.firstIndex(of: "--snapshot"), args.indices.contains(flag + 1) else { return }
        let path = args[flag + 1]
        let keys = args.firstIndex(of: "--keys").flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil }
        Task {
            if args.contains("--now-playing") {
                // Wait for the first poll so the Now Playing row exists (it's last).
                try? await Task.sleep(for: .seconds(2))
                navigator.handle(.scroll(steps: 20))
                navigator.handle(.center)
            }
            for key in (keys ?? "").split(separator: ",") {
                switch key {
                case "c": navigator.handle(.center)
                case "d": navigator.handle(.scroll(steps: 1))
                case "u": navigator.handle(.scroll(steps: -1))
                case "m": navigator.handle(.menu)
                case "w": break
                default: break
                }
                try? await Task.sleep(for: .seconds(1.5))
            }
            // Short final wait after keys, so timed overlays (volume, scrubber) are still up.
            try? await Task.sleep(for: .seconds(keys == nil ? 2.5 : 0.3))
            let renderer = ImageRenderer(content: rootView(includesWindowControls: false).padding(20))
            renderer.scale = 2
            if let image = renderer.nsImage, let tiff = image.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: path))
            }
            NSApp.terminate(nil)
        }
    }
}

/// A reference wrapper so the navigator's callback can mutate the limiter.
private final class ClickThrottle {
    private var limiter = ClickRateLimiter()
    func shouldClick(now: TimeInterval) -> Bool { limiter.shouldClick(now: now) }
}
